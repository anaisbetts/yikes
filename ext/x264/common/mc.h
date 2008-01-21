/*****************************************************************************
 * mc.h: h264 encoder library (Motion Compensation)
 *****************************************************************************
 * Copyright (C) 2003 Laurent Aimar
 * $Id: mc.h,v 1.1 2004/06/03 19:27:07 fenrir Exp $
 *
 * Authors: Laurent Aimar <fenrir@via.ecp.fr>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111, USA.
 *****************************************************************************/

#ifndef _MC_H
#define _MC_H 1

/* Do the MC
 * XXX: Only width = 4, 8 or 16 are valid
 * width == 4 -> height == 4 or 8
 * width == 8 -> height == 4 or 8 or 16
 * width == 16-> height == 8 or 16
 * */

typedef struct
{
    void (*mc_luma)(uint8_t *dst, int i_dst, uint8_t **src, int i_src,
                    int mvx, int mvy,
                    int i_width, int i_height );

    /* may round up the dimensions if they're not a power of 2 */
    uint8_t* (*get_ref)(uint8_t *dst, int *i_dst, uint8_t **src, int i_src,
                        int mvx, int mvy,
                        int i_width, int i_height );

    /* mc_chroma may write up to 2 bytes of garbage to the right of dst,
     * so it must be run from left to right. */
    void (*mc_chroma)(uint8_t *dst, int i_dst, uint8_t *src, int i_src,
                      int mvx, int mvy,
                      int i_width, int i_height );

    void (*avg[10])( uint8_t *dst, int, uint8_t *src, int );
    void (*avg_weight[10])( uint8_t *dst, int, uint8_t *src, int, int i_weight );

    /* only 16x16, 8x8, and 4x4 defined */
    void (*copy[7])( uint8_t *dst, int, uint8_t *src, int, int i_height );

    void (*plane_copy)( uint8_t *dst, int i_dst,
                        uint8_t *src, int i_src, int w, int h);

    void (*hpel_filter)( uint8_t *dsth, uint8_t *dstv, uint8_t *dstc, uint8_t *src,
                         int i_stride, int i_width, int i_height );

    /* prefetch the next few macroblocks of fenc or fdec */
    void (*prefetch_fenc)( uint8_t *pix_y, int stride_y,
                           uint8_t *pix_uv, int stride_uv, int mb_x );
    /* prefetch the next few macroblocks of a hpel reference frame */
    void (*prefetch_ref)( uint8_t *pix, int stride, int parity );

} x264_mc_functions_t;

void x264_mc_init( int cpu, x264_mc_functions_t *pf );

#endif
