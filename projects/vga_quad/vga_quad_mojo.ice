
$$div_width=32
$include('../common/divint_any.ice')

$include('../common/vga_sdram_main_mojo.ice')

// ------------------------- 

algorithm frame_drawer(
  output uint23 saddr,
  output uint2  swbyte_addr,
  output uint1  srw,
  output uint32 sdata_in,
  output uint1  sin_valid,
  input  uint32 sdata_out,
  input  uint1  sbusy,
  input  uint1  sout_valid,
  input  uint1  vsync
) {

  uint1  vsync_filtered = 0;
  div32  divA;
  div32  divB;

  int32 qp0x = -400;
  int32 qp0y =   40;
  int32 qp1x =  400;
  int32 qp1y =   40;
  uint1 dir0 =   0;
  uint1 dir1 =   0;

  subroutine clear_screen(
  	// sdram
    reads   sbusy,
    writes  sdata_in,
    writes  saddr,
    writes  swbyte_addr,
    writes  sin_valid
  )
  {
    uint9  pix_x      = 0;
    uint8  pix_y      = 0;
	  
    pix_x  = 0;
    while (pix_x < 320) {	
	    // clear column
	    pix_y = 0;
      while (pix_y < 200) {
        // write to sdram
        while (1) {
          if (sbusy == 0) {        // not busy?
            sdata_in    = 0;
            saddr       = (pix_x + (pix_y << 8) + (pix_y << 6)) >> 2; // * 320 / 4
            swbyte_addr = pix_x & 3;
            sin_valid   = 1; // go ahead!
            break;
          }
        }          
        pix_y = pix_y + 1;
      }	  
	    pix_x = pix_x + 1;
	  }	
	  return;
  }

  subroutine draw_quad(
    // quad
    input  int32 p0x,
	  input  int32 p0y,
    input  int32 p1x,
	  input  int32 p1y,
	  // sdram
    reads   sbusy,
    writes  sdata_in,
    writes  saddr,
    writes  swbyte_addr,
    writes  sin_valid
  )
  {
    uint9  pix_x      = 0;
    uint8  pix_y      = 0;

    int32 h     = 100;
    int32 ynear = 4;
    
	  int32 scr0x = 0;
	  int32 scr0y = 0;
	  int32 scr1x = 0;
	  int32 scr1y = 0;
	  int32 scrix = 0;
	  int32 d10x  = 0;
	  int32 d10y  = 0;
   
    int32 hscr    = 0;
    int32 hscr_fp = 0;
    int32 dscr    = 0;
    int32 hscr0   = 0;
    int32 hscr1   = 0;
    int32 hscr_delta = 0;
	  int32 scr_deltax = 0;
       
    int32 hscr_tmp0 = 0;
    int32 hscr_tmp1 = 0;
    int32 hscr_tmp2 = 0;
    int32 dscr_tmp  = 0;
  
    int32 alpha = 0;

    scr0x = ynear * p0x;
    scr1x = ynear * p1x;

	  divA <- (scr0x,p0y);
	  divB <- (scr1x,p1y);
    // join
    (scr0x) <- divA;
    (scr1x) <- divB;

	  d10x  = p1x - p0x;
	  d10y  = p1y - p0y;
 	
    // dscr = p0x * d10y - p0y * d10x;
    // hscr = h * (scrix * d10y - ynear * d10x) / dscr;

    // compute divisor (dscr) as well as left/right heights
    dscr      =   p0x * d10y;   
    hscr_tmp0 = ynear * d10x;
++:
    dscr      = dscr - p0y * d10x;
    hscr_tmp1 = scr0x * d10y;
    hscr_tmp2 = scr1x * d10y;
++:
    hscr0 = h * (hscr_tmp1 - hscr_tmp0);
    hscr1 = h * (hscr_tmp2 - hscr_tmp0);
++:
    divA <- (hscr0,dscr);	
    divB <- (hscr1,dscr);	
    // join
    (hscr0) <- divA;
    (hscr1) <- divB;
++:    

    // prepare interpolation of height
    hscr_fp    = hscr0 << 16;   
    hscr_delta = (hscr1 - hscr0) << 16;
    scr_deltax = scr1x - scr0x;
    (hscr_delta) <- divA <- (hscr_delta,scr_deltax);

    // for each column
    scrix   = scr0x;
    while (scrix < scr1x) {
	
      // interpolator
      // interp = (scrix * d10y - ynear * d10x) / (p0x * d10y - p0y * d10x)      
      //interp = (scrix * d10y - hscr_tmp0) << 12;
		  //(interp) <- div <- (interp,dscr);	
      
      // current height to integer
      hscr = hscr_fp >> 16;
      // clamp      
      if (hscr < 0) {
		    hscr = 0;  // should not happen: overflow...
		  }
		  if (hscr > 99) {
		    hscr = 99; // max height
		  }
      // draw column in framebuffer
		  pix_y = 100 - hscr;
      while (pix_y < 100 + hscr) {
        // write to sdram
        pix_x = scrix + 160;
        while (1) {
          if (sbusy == 0) {        // not busy?
            sdata_in    = 5; // palette id
            saddr       = (pix_x + (pix_y << 8) + (pix_y << 6)) >> 2; // * 320 / 4
            swbyte_addr = pix_x & 3;
            sin_valid   = 1; // go ahead!
            break;
          }
        }          
        pix_y = pix_y + 1;
      }		
      
      hscr_fp = hscr_fp + hscr_delta;
      scrix = scrix + 1;	  
	  }	
	  return;
  }  
  
  vsync_filtered ::= vsync;

  sin_valid := 0; // maintain low (pulses high when needed)

  srw = 1;  // write

  while (1) {

    // clear
	  () <- clear_screen <- ();
    // draw
    () <- draw_quad <- (qp0x,qp0y, qp1x,qp1y);
	
    // wait for vsync
    while (vsync_filtered == 1) {}
    while (vsync_filtered == 0) {}

    if (dir0 == 0) {
      qp0y = qp0y + 1;
      if (qp0y > 80) {
        dir0 = 1;
      }
    } else {
      qp0y = qp0y - 1;
      if (qp0y < 20) {
        dir0 = 0;
      }
    }
    
    if (dir1 == 0) {
      qp1y = qp1y + 2;
      if (qp1y > 80) {
        dir1 = 1;
      }
    } else {
      qp1y = qp1y - 2;
      if (qp1y < 20) {
        dir1 = 0;
      }
    }

  }
}

// ------------------------- 