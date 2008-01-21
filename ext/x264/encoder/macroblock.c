/*****************************************************************************
 * macroblock.c: h264 encoder library
 *****************************************************************************
 * Copyright (C) 2003 Laurent Aimar
 * $Id: macroblock.c,v 1.1 2004/06/03 19:27:08 fenrir Exp $
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

#include "common/common.h"
#include "macroblock.h"


#define ZIG(i,y,x) level[i] = dct[x][y];
static inline void zigzag_scan_2x2_dc( int level[4], int16_t dct[2][2] )
{
    ZIG(0,0,0)
    ZIG(1,0,1)
    ZIG(2,1,0)
    ZIG(3,1,1)
}
#undef ZIG

/* (ref: JVT-B118)
 * x264_mb_decimate_score: given dct coeffs it returns a score to see if we could empty this dct coeffs
 * to 0 (low score means set it to null)
 * Used in inter macroblock (luma and chroma)
 *  luma: for a 8x8 block: if score < 4 -> null
 *        for the complete mb: if score < 6 -> null
 *  chroma: for the complete mb: if score < 7 -> null
 */
static int x264_mb_decimate_score( int *dct, int i_max )
{
    static const int i_ds_table4[16] = {
        3,2,2,1,1,1,0,0,0,0,0,0,0,0,0,0 };
    static const int i_ds_table8[64] = {
        3,3,3,3,2,2,2,2,2,2,2,2,1,1,1,1,
        1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 };

    const int *ds_table = (i_max == 64) ? i_ds_table8 : i_ds_table4;
    int i_score = 0;
    int idx = i_max - 1;

    while( idx >= 0 && dct[idx] == 0 )
        idx--;

    while( idx >= 0 )
    {
        int i_run;

        if( abs( dct[idx--] ) > 1 )
            return 9;

        i_run = 0;
        while( idx >= 0 && dct[idx] == 0 )
        {
            idx--;
            i_run++;
        }
        i_score += ds_table[i_run];
    }

    return i_score;
}

void x264_mb_encode_i4x4( x264_t *h, int idx, int i_qscale )
{
    int x = 4 * block_idx_x[idx];
    int y = 4 * block_idx_y[idx];
    uint8_t *p_src = &h->mb.pic.p_fenc[0][x+y*FENC_STRIDE];
    uint8_t *p_dst = &h->mb.pic.p_fdec[0][x+y*FDEC_STRIDE];
    DECLARE_ALIGNED( int16_t, dct4x4[4][4], 16 );

    if( h->mb.b_lossless )
    {
        h->zigzagf.sub_4x4( h->dct.block[idx].luma4x4, p_src, p_dst );
        return;
    }

    h->dctf.sub4x4_dct( dct4x4, p_src, p_dst );

    if( h->mb.b_trellis )
        x264_quant_4x4_trellis( h, dct4x4, CQM_4IY, i_qscale, DCT_LUMA_4x4, 1 );
    else
        h->quantf.quant_4x4( dct4x4, h->quant4_mf[CQM_4IY][i_qscale], h->quant4_bias[CQM_4IY][i_qscale] );

    h->zigzagf.scan_4x4( h->dct.block[idx].luma4x4, dct4x4 );
    h->quantf.dequant_4x4( dct4x4, h->dequant4_mf[CQM_4IY], i_qscale );

    /* output samples to fdec */
    h->dctf.add4x4_idct( p_dst, dct4x4 );
}

void x264_mb_encode_i8x8( x264_t *h, int idx, int i_qscale )
{
    int x = 8 * (idx&1);
    int y = 8 * (idx>>1);
    uint8_t *p_src = &h->mb.pic.p_fenc[0][x+y*FENC_STRIDE];
    uint8_t *p_dst = &h->mb.pic.p_fdec[0][x+y*FDEC_STRIDE];
    DECLARE_ALIGNED( int16_t, dct8x8[8][8], 16 );

    h->dctf.sub8x8_dct8( dct8x8, p_src, p_dst );

    if( h->mb.b_trellis )
        x264_quant_8x8_trellis( h, dct8x8, CQM_8IY, i_qscale, 1 );
    else 
        h->quantf.quant_8x8( dct8x8, h->quant8_mf[CQM_8IY][i_qscale], h->quant8_bias[CQM_8IY][i_qscale] );

    h->zigzagf.scan_8x8( h->dct.luma8x8[idx], dct8x8 );
    h->quantf.dequant_8x8( dct8x8, h->dequant8_mf[CQM_8IY], i_qscale );
    h->dctf.add8x8_idct8( p_dst, dct8x8 );
}

static void x264_mb_encode_i16x16( x264_t *h, int i_qscale )
{
    uint8_t  *p_src = h->mb.pic.p_fenc[0];
    uint8_t  *p_dst = h->mb.pic.p_fdec[0];

    DECLARE_ALIGNED( int16_t, dct4x4[16+1][4][4], 16 );

    int i;

    if( h->mb.b_lossless )
    {
        for( i = 0; i < 16; i++ )
        {
            int oe = block_idx_x[i]*4 + block_idx_y[i]*4*FENC_STRIDE;
            int od = block_idx_x[i]*4 + block_idx_y[i]*4*FDEC_STRIDE;
            h->zigzagf.sub_4x4ac( h->dct.block[i].residual_ac, p_src+oe, p_dst+od );
            dct4x4[0][block_idx_x[i]][block_idx_y[i]] = p_src[oe] - p_dst[od];
            p_dst[od] = p_src[oe];
        }
        h->zigzagf.scan_4x4( h->dct.luma16x16_dc, dct4x4[0] );
        return;
    }

    h->dctf.sub16x16_dct( &dct4x4[1], p_src, p_dst );
    for( i = 0; i < 16; i++ )
    {
        /* copy dc coeff */
        dct4x4[0][block_idx_y[i]][block_idx_x[i]] = dct4x4[1+i][0][0];

        /* quant/scan/dequant */
        if( h->mb.b_trellis )
            x264_quant_4x4_trellis( h, dct4x4[1+i], CQM_4IY, i_qscale, DCT_LUMA_AC, 1 );
        else
            h->quantf.quant_4x4( dct4x4[1+i], h->quant4_mf[CQM_4IY][i_qscale], h->quant4_bias[CQM_4IY][i_qscale] );

        h->zigzagf.scan_4x4ac( h->dct.block[i].residual_ac, dct4x4[1+i] );
        h->quantf.dequant_4x4( dct4x4[1+i], h->dequant4_mf[CQM_4IY], i_qscale );
    }

    h->dctf.dct4x4dc( dct4x4[0] );
    h->quantf.quant_4x4_dc( dct4x4[0], h->quant4_mf[CQM_4IY][i_qscale][0]>>1, h->quant4_bias[CQM_4IY][i_qscale][0]<<1 );
    h->zigzagf.scan_4x4( h->dct.luma16x16_dc, dct4x4[0] );

    /* output samples to fdec */
    h->dctf.idct4x4dc( dct4x4[0] );
    x264_mb_dequant_4x4_dc( dct4x4[0], h->dequant4_mf[CQM_4IY], i_qscale );  /* XXX not inversed */

    /* calculate dct coeffs */
    for( i = 0; i < 16; i++ )
    {
        /* copy dc coeff */
        dct4x4[1+i][0][0] = dct4x4[0][block_idx_y[i]][block_idx_x[i]];
    }
    /* put pixels to fdec */
    h->dctf.add16x16_idct( p_dst, &dct4x4[1] );
}

void x264_mb_encode_8x8_chroma( x264_t *h, int b_inter, int i_qscale )
{
    int i, ch;
    int b_decimate = b_inter && (h->sh.i_type == SLICE_TYPE_B || h->param.analyse.b_dct_decimate);

    for( ch = 0; ch < 2; ch++ )
    {
        uint8_t  *p_src = h->mb.pic.p_fenc[1+ch];
        uint8_t  *p_dst = h->mb.pic.p_fdec[1+ch];
        int i_decimate_score = 0;

        DECLARE_ALIGNED( int16_t, dct2x2[2][2] , 16 );
        DECLARE_ALIGNED( int16_t, dct4x4[4][4][4], 16 );

        if( h->mb.b_lossless )
        {
            for( i = 0; i < 4; i++ )
            {
                int oe = block_idx_x[i]*4 + block_idx_y[i]*4*FENC_STRIDE;
                int od = block_idx_x[i]*4 + block_idx_y[i]*4*FDEC_STRIDE;
                h->zigzagf.sub_4x4ac( h->dct.block[16+i+ch*4].residual_ac, p_src+oe, p_dst+od );
                h->dct.chroma_dc[ch][i] = p_src[oe] - p_dst[od];
                p_dst[od] = p_src[oe];
            }
            continue;
        }
            
        h->dctf.sub8x8_dct( dct4x4, p_src, p_dst );
        /* calculate dct coeffs */
        for( i = 0; i < 4; i++ )
        {
            /* copy dc coeff */
            dct2x2[block_idx_y[i]][block_idx_x[i]] = dct4x4[i][0][0];

            /* no trellis; it doesn't seem to help chroma noticeably */
            h->quantf.quant_4x4( dct4x4[i], h->quant4_mf[CQM_4IC+b_inter][i_qscale], h->quant4_bias[CQM_4IC+b_inter][i_qscale] );
            h->zigzagf.scan_4x4ac( h->dct.block[16+i+ch*4].residual_ac, dct4x4[i] );

            if( b_decimate )
            {
                i_decimate_score += x264_mb_decimate_score( h->dct.block[16+i+ch*4].residual_ac, 15 );
            }
        }

        h->dctf.dct2x2dc( dct2x2 );
        h->quantf.quant_2x2_dc( dct2x2, h->quant4_mf[CQM_4IC+b_inter][i_qscale][0]>>1, h->quant4_bias[CQM_4IC+b_inter][i_qscale][0]<<1 );
        zigzag_scan_2x2_dc( h->dct.chroma_dc[ch], dct2x2 );

        /* output samples to fdec */
        h->dctf.idct2x2dc( dct2x2 );
        x264_mb_dequant_2x2_dc( dct2x2, h->dequant4_mf[CQM_4IC + b_inter], i_qscale );  /* XXX not inversed */

        if( b_decimate && i_decimate_score < 7 )
        {
            /* Near null chroma 8x8 block so make it null (bits saving) */
            memset( &h->dct.block[16+ch*4], 0, 4 * sizeof( *h->dct.block ) );
            if( !array_non_zero( dct2x2 ) )
                continue;
            memset( dct4x4, 0, sizeof( dct4x4 ) );
        }
        else
        {
            for( i = 0; i < 4; i++ )
                h->quantf.dequant_4x4( dct4x4[i], h->dequant4_mf[CQM_4IC + b_inter], i_qscale );
        }

        for( i = 0; i < 4; i++ )
            dct4x4[i][0][0] = dct2x2[0][i];
        h->dctf.add8x8_idct( p_dst, dct4x4 );
    }

    /* coded block pattern */
    h->mb.i_cbp_chroma = 0;
    for( i = 0; i < 8; i++ )
    {
        int nz = array_non_zero_count( h->dct.block[16+i].residual_ac, 15 );
        h->mb.cache.non_zero_count[x264_scan8[16+i]] = nz;
        h->mb.i_cbp_chroma |= nz;
    }
    if( h->mb.i_cbp_chroma )
        h->mb.i_cbp_chroma = 2;    /* dc+ac (we can't do only ac) */
    else if( array_non_zero( h->dct.chroma_dc ) )
        h->mb.i_cbp_chroma = 1;    /* dc only */
}

static void x264_macroblock_encode_skip( x264_t *h )
{
    int i;
    h->mb.i_cbp_luma = 0x00;
    h->mb.i_cbp_chroma = 0x00;

    for( i = 0; i < 16+8; i++ )
    {
        h->mb.cache.non_zero_count[x264_scan8[i]] = 0;
    }

    /* store cbp */
    h->mb.cbp[h->mb.i_mb_xy] = 0;
}

/*****************************************************************************
 * x264_macroblock_encode_pskip:
 *  Encode an already marked skip block
 *****************************************************************************/
void x264_macroblock_encode_pskip( x264_t *h )
{
    const int mvx = x264_clip3( h->mb.cache.mv[0][x264_scan8[0]][0],
                                h->mb.mv_min[0], h->mb.mv_max[0] );
    const int mvy = x264_clip3( h->mb.cache.mv[0][x264_scan8[0]][1],
                                h->mb.mv_min[1], h->mb.mv_max[1] );

    /* Motion compensation XXX probably unneeded */
    h->mc.mc_luma( h->mb.pic.p_fdec[0],    FDEC_STRIDE,
                   h->mb.pic.p_fref[0][0], h->mb.pic.i_stride[0],
                   mvx, mvy, 16, 16 );

    /* Chroma MC */
    h->mc.mc_chroma( h->mb.pic.p_fdec[1],       FDEC_STRIDE,
                     h->mb.pic.p_fref[0][0][4], h->mb.pic.i_stride[1],
                     mvx, mvy, 8, 8 );

    h->mc.mc_chroma( h->mb.pic.p_fdec[2],       FDEC_STRIDE,
                     h->mb.pic.p_fref[0][0][5], h->mb.pic.i_stride[2],
                     mvx, mvy, 8, 8 );

    x264_macroblock_encode_skip( h );
}

/*****************************************************************************
 * x264_macroblock_encode:
 *****************************************************************************/
void x264_macroblock_encode( x264_t *h )
{
    int i_cbp_dc = 0;
    int i_qp = h->mb.i_qp;
    int b_decimate = h->sh.i_type == SLICE_TYPE_B || h->param.analyse.b_dct_decimate;
    int b_force_no_skip = 0;
    int i;

    if( h->sh.b_mbaff
        && h->mb.i_mb_xy == h->sh.i_first_mb + h->mb.i_mb_stride
        && IS_SKIP(h->mb.type[h->sh.i_first_mb]) )
    {
        /* The first skip is predicted to be a frame mb pair.
         * We don't yet support the aff part of mbaff, so force it to non-skip
         * so that we can pick the aff flag. */
        b_force_no_skip = 1;
        if( IS_SKIP(h->mb.i_type) )
        {
            if( h->mb.i_type == P_SKIP )
                h->mb.i_type = P_L0;
            else if( h->mb.i_type == B_SKIP )
                h->mb.i_type = B_DIRECT;
        }
    }

    if( h->mb.i_type == P_SKIP )
    {
        /* A bit special */
        x264_macroblock_encode_pskip( h );
        return;
    }
    if( h->mb.i_type == B_SKIP )
    {
        /* XXX motion compensation is probably unneeded */
        x264_mb_mc( h );
        x264_macroblock_encode_skip( h );
        return;
    }

    if( h->mb.i_type == I_16x16 )
    {
        const int i_mode = h->mb.i_intra16x16_pred_mode;
        h->mb.b_transform_8x8 = 0;
        /* do the right prediction */
        h->predict_16x16[i_mode]( h->mb.pic.p_fdec[0] );

        /* encode the 16x16 macroblock */
        x264_mb_encode_i16x16( h, i_qp );
    }
    else if( h->mb.i_type == I_8x8 )
    {
        DECLARE_ALIGNED( uint8_t, edge[33], 8 );
        h->mb.b_transform_8x8 = 1;
        for( i = 0; i < 4; i++ )
        {
            uint8_t  *p_dst = &h->mb.pic.p_fdec[0][8 * (i&1) + 8 * (i>>1) * FDEC_STRIDE];
            int      i_mode = h->mb.cache.intra4x4_pred_mode[x264_scan8[4*i]];

            x264_predict_8x8_filter( p_dst, edge, h->mb.i_neighbour8[i], x264_pred_i4x4_neighbors[i_mode] );
            h->predict_8x8[i_mode]( p_dst, edge );
            x264_mb_encode_i8x8( h, i, i_qp );
        }
    }
    else if( h->mb.i_type == I_4x4 )
    {
        h->mb.b_transform_8x8 = 0;
        for( i = 0; i < 16; i++ )
        {
            uint8_t  *p_dst = &h->mb.pic.p_fdec[0][4 * block_idx_x[i] + 4 * block_idx_y[i] * FDEC_STRIDE];
            int      i_mode = h->mb.cache.intra4x4_pred_mode[x264_scan8[i]];

            if( (h->mb.i_neighbour4[i] & (MB_TOPRIGHT|MB_TOP)) == MB_TOP )
                /* emulate missing topright samples */
                *(uint32_t*) &p_dst[4-FDEC_STRIDE] = p_dst[3-FDEC_STRIDE] * 0x01010101U;

            h->predict_4x4[i_mode]( p_dst );
            x264_mb_encode_i4x4( h, i, i_qp );
        }
    }
    else    /* Inter MB */
    {
        int i8x8, i4x4, idx;
        int i_decimate_mb = 0;

        /* Motion compensation */
        x264_mb_mc( h );

        if( h->mb.b_lossless )
        {
            for( i4x4 = 0; i4x4 < 16; i4x4++ )
            {
                int x = 4*block_idx_x[i4x4];
                int y = 4*block_idx_y[i4x4];
                h->zigzagf.sub_4x4( h->dct.block[i4x4].luma4x4,
                                    h->mb.pic.p_fenc[0]+x+y*FENC_STRIDE,
                                    h->mb.pic.p_fdec[0]+x+y*FDEC_STRIDE );
            }
        }
        else if( h->mb.b_transform_8x8 )
        {
            DECLARE_ALIGNED( int16_t, dct8x8[4][8][8], 16 );
            int nnz8x8[4] = {1,1,1,1};
            b_decimate &= !h->mb.b_trellis; // 8x8 trellis is inherently optimal decimation
            h->dctf.sub16x16_dct8( dct8x8, h->mb.pic.p_fenc[0], h->mb.pic.p_fdec[0] );

            for( idx = 0; idx < 4; idx++ )
            {
                if( h->mb.b_noise_reduction )
                    x264_denoise_dct( h, (int16_t*)dct8x8[idx] );
                if( h->mb.b_trellis )
                    x264_quant_8x8_trellis( h, dct8x8[idx], CQM_8PY, i_qp, 0 );
                else
                    h->quantf.quant_8x8( dct8x8[idx], h->quant8_mf[CQM_8PY][i_qp], h->quant8_bias[CQM_8PY][i_qp] );

                h->zigzagf.scan_8x8( h->dct.luma8x8[idx], dct8x8[idx] );

                if( b_decimate )
                {
                    int i_decimate_8x8 = x264_mb_decimate_score( h->dct.luma8x8[idx], 64 );
                    i_decimate_mb += i_decimate_8x8;
                    if( i_decimate_8x8 < 4 )
                    {
                        memset( h->dct.luma8x8[idx], 0, sizeof( h->dct.luma8x8[idx] ) );
                        memset( dct8x8[idx], 0, sizeof( dct8x8[idx] ) );
                        nnz8x8[idx] = 0;
                    }
                }
                else
                    nnz8x8[idx] = array_non_zero( dct8x8[idx] );
            }

            if( i_decimate_mb < 6 && b_decimate )
                memset( h->dct.luma8x8, 0, sizeof( h->dct.luma8x8 ) );
            else
            {
                for( idx = 0; idx < 4; idx++ )
                    if( nnz8x8[idx] )
                    {
                        h->quantf.dequant_8x8( dct8x8[idx], h->dequant8_mf[CQM_8PY], i_qp );
                        h->dctf.add8x8_idct8( &h->mb.pic.p_fdec[0][(idx&1)*8 + (idx>>1)*8*FDEC_STRIDE], dct8x8[idx] );
                    }
            }
        }
        else
        {
            DECLARE_ALIGNED( int16_t, dct4x4[16][4][4], 16 );
            int nnz8x8[4] = {1,1,1,1};
            h->dctf.sub16x16_dct( dct4x4, h->mb.pic.p_fenc[0], h->mb.pic.p_fdec[0] );

            for( i8x8 = 0; i8x8 < 4; i8x8++ )
            {
                int i_decimate_8x8;

                /* encode one 4x4 block */
                i_decimate_8x8 = 0;
                for( i4x4 = 0; i4x4 < 4; i4x4++ )
                {
                    idx = i8x8 * 4 + i4x4;

                    if( h->mb.b_noise_reduction )
                        x264_denoise_dct( h, (int16_t*)dct4x4[idx] );
                    if( h->mb.b_trellis )
                        x264_quant_4x4_trellis( h, dct4x4[idx], CQM_4PY, i_qp, DCT_LUMA_4x4, 0 );
                    else
                        h->quantf.quant_4x4( dct4x4[idx], h->quant4_mf[CQM_4PY][i_qp], h->quant4_bias[CQM_4PY][i_qp] );

                    h->zigzagf.scan_4x4( h->dct.block[idx].luma4x4, dct4x4[idx] );
                    
                    if( b_decimate )
                        i_decimate_8x8 += x264_mb_decimate_score( h->dct.block[idx].luma4x4, 16 );
                }

                /* decimate this 8x8 block */
                i_decimate_mb += i_decimate_8x8;
                if( i_decimate_8x8 < 4 && b_decimate )
                {
                    memset( &dct4x4[i8x8*4], 0, 4 * sizeof( *dct4x4 ) );
                    memset( &h->dct.block[i8x8*4], 0, 4 * sizeof( *h->dct.block ) );
                    nnz8x8[i8x8] = 0;
                }
            }

            if( i_decimate_mb < 6 && b_decimate )
                memset( h->dct.block, 0, 16 * sizeof( *h->dct.block ) );
            else
            {
                for( i8x8 = 0; i8x8 < 4; i8x8++ )
                    if( nnz8x8[i8x8] )
                    {
                        for( i = 0; i < 4; i++ )
                            h->quantf.dequant_4x4( dct4x4[i8x8*4+i], h->dequant4_mf[CQM_4PY], i_qp );
                        h->dctf.add8x8_idct( &h->mb.pic.p_fdec[0][(i8x8&1)*8 + (i8x8>>1)*8*FDEC_STRIDE], &dct4x4[i8x8*4] );
                    }
            }
        }
    }

    /* encode chroma */
    if( IS_INTRA( h->mb.i_type ) )
    {
        const int i_mode = h->mb.i_chroma_pred_mode;
        h->predict_8x8c[i_mode]( h->mb.pic.p_fdec[1] );
        h->predict_8x8c[i_mode]( h->mb.pic.p_fdec[2] );
    }

    /* encode the 8x8 blocks */
    x264_mb_encode_8x8_chroma( h, !IS_INTRA( h->mb.i_type ), h->mb.i_chroma_qp );

    /* coded block pattern and non_zero_count */
    h->mb.i_cbp_luma = 0x00;
    if( h->mb.i_type == I_16x16 )
    {
        for( i = 0; i < 16; i++ )
        {
            const int nz = array_non_zero_count( h->dct.block[i].residual_ac, 15 );
            h->mb.cache.non_zero_count[x264_scan8[i]] = nz;
            if( nz > 0 )
                h->mb.i_cbp_luma = 0x0f;
        }
    }
    else if( h->mb.b_transform_8x8 )
    {
        /* coded_block_flag is enough for CABAC.
         * the full non_zero_count is done only in CAVLC. */
        for( i = 0; i < 4; i++ )
        {
            const int nz = array_non_zero( h->dct.luma8x8[i] );
            int j;
            for( j = 0; j < 4; j++ )
                h->mb.cache.non_zero_count[x264_scan8[4*i+j]] = nz;
            if( nz > 0 )
                h->mb.i_cbp_luma |= 1 << i;
        }
    }
    else
    {
        for( i = 0; i < 16; i++ )
        {
            const int nz = array_non_zero_count( h->dct.block[i].luma4x4, 16 );
            h->mb.cache.non_zero_count[x264_scan8[i]] = nz;
            if( nz > 0 )
                h->mb.i_cbp_luma |= 1 << (i/4);
        }
    }

    if( h->param.b_cabac )
    {
        i_cbp_dc = ( h->mb.i_type == I_16x16 && array_non_zero( h->dct.luma16x16_dc ) )
                 | array_non_zero( h->dct.chroma_dc[0] ) << 1
                 | array_non_zero( h->dct.chroma_dc[1] ) << 2;
    }

    /* store cbp */
    h->mb.cbp[h->mb.i_mb_xy] = (i_cbp_dc << 8) | (h->mb.i_cbp_chroma << 4) | h->mb.i_cbp_luma;

    /* Check for P_SKIP
     * XXX: in the me perhaps we should take x264_mb_predict_mv_pskip into account
     *      (if multiple mv give same result)*/
    if( !b_force_no_skip )
    {
        if( h->mb.i_type == P_L0 && h->mb.i_partition == D_16x16 &&
            h->mb.i_cbp_luma == 0x00 && h->mb.i_cbp_chroma == 0x00 &&
            h->mb.cache.mv[0][x264_scan8[0]][0] == h->mb.cache.pskip_mv[0] &&
            h->mb.cache.mv[0][x264_scan8[0]][1] == h->mb.cache.pskip_mv[1] &&
            h->mb.cache.ref[0][x264_scan8[0]] == 0 )
        {
            h->mb.i_type = P_SKIP;
        }

        /* Check for B_SKIP */
        if( h->mb.i_type == B_DIRECT &&
            h->mb.i_cbp_luma == 0x00 && h->mb.i_cbp_chroma== 0x00 )
        {
            h->mb.i_type = B_SKIP;
        }
    }
}

/*****************************************************************************
 * x264_macroblock_probe_skip:
 *  Check if the current MB could be encoded as a [PB]_SKIP (it supposes you use
 *  the previous QP
 *****************************************************************************/
int x264_macroblock_probe_skip( x264_t *h, const int b_bidir )
{
    DECLARE_ALIGNED( int16_t, dct4x4[16][4][4], 16 );
    DECLARE_ALIGNED( int16_t, dct2x2[2][2], 16 );
    DECLARE_ALIGNED( int,     dctscan[16], 16 );

    int i_qp = h->mb.i_qp;
    int mvp[2];
    int ch;

    int i8x8, i4x4;
    int i_decimate_mb;

    if( !b_bidir )
    {
        /* Get the MV */
        mvp[0] = x264_clip3( h->mb.cache.pskip_mv[0], h->mb.mv_min[0], h->mb.mv_max[0] );
        mvp[1] = x264_clip3( h->mb.cache.pskip_mv[1], h->mb.mv_min[1], h->mb.mv_max[1] );

        /* Motion compensation */
        h->mc.mc_luma( h->mb.pic.p_fdec[0],    FDEC_STRIDE,
                       h->mb.pic.p_fref[0][0], h->mb.pic.i_stride[0],
                       mvp[0], mvp[1], 16, 16 );
    }

    /* get luma diff */
    h->dctf.sub16x16_dct( dct4x4, h->mb.pic.p_fenc[0],
                                  h->mb.pic.p_fdec[0] );

    for( i8x8 = 0, i_decimate_mb = 0; i8x8 < 4; i8x8++ )
    {
        /* encode one 4x4 block */
        for( i4x4 = 0; i4x4 < 4; i4x4++ )
        {
            const int idx = i8x8 * 4 + i4x4;

            h->quantf.quant_4x4( dct4x4[idx], h->quant4_mf[CQM_4PY][i_qp], h->quant4_bias[CQM_4PY][i_qp] );
            h->zigzagf.scan_4x4( dctscan, dct4x4[idx] );

            i_decimate_mb += x264_mb_decimate_score( dctscan, 16 );

            if( i_decimate_mb >= 6 )
            {
                /* not as P_SKIP */
                return 0;
            }
        }
    }

    /* encode chroma */
    i_qp = h->mb.i_chroma_qp;

    for( ch = 0; ch < 2; ch++ )
    {
        uint8_t  *p_src = h->mb.pic.p_fenc[1+ch];
        uint8_t  *p_dst = h->mb.pic.p_fdec[1+ch];

        if( !b_bidir )
        {
            h->mc.mc_chroma( h->mb.pic.p_fdec[1+ch],       FDEC_STRIDE,
                             h->mb.pic.p_fref[0][0][4+ch], h->mb.pic.i_stride[1+ch],
                             mvp[0], mvp[1], 8, 8 );
        }

        h->dctf.sub8x8_dct( dct4x4, p_src, p_dst );

        /* calculate dct DC */
        dct2x2[0][0] = dct4x4[0][0][0];
        dct2x2[0][1] = dct4x4[1][0][0];
        dct2x2[1][0] = dct4x4[2][0][0];
        dct2x2[1][1] = dct4x4[3][0][0];
        h->dctf.dct2x2dc( dct2x2 );
        h->quantf.quant_2x2_dc( dct2x2, h->quant4_mf[CQM_4PC][i_qp][0]>>1, h->quant4_bias[CQM_4PC][i_qp][0]<<1 );
        if( dct2x2[0][0] || dct2x2[0][1] || dct2x2[1][0] || dct2x2[1][1]  )
        {
            /* can't be */
            return 0;
        }

        /* calculate dct coeffs */
        for( i4x4 = 0, i_decimate_mb = 0; i4x4 < 4; i4x4++ )
        {
            h->quantf.quant_4x4( dct4x4[i4x4], h->quant4_mf[CQM_4PC][i_qp], h->quant4_bias[CQM_4PC][i_qp] );
            h->zigzagf.scan_4x4ac( dctscan, dct4x4[i4x4] );

            i_decimate_mb += x264_mb_decimate_score( dctscan, 15 );
            if( i_decimate_mb >= 7 )
            {
                return 0;
            }
        }
    }

    return 1;
}

/****************************************************************************
 * DCT-domain noise reduction / adaptive deadzone
 * from libavcodec
 ****************************************************************************/

void x264_noise_reduction_update( x264_t *h )
{
    int cat, i;
    for( cat = 0; cat < 2; cat++ )
    {
        int size = cat ? 64 : 16;
        const uint16_t *weight = cat ? x264_dct8_weight2_tab : x264_dct4_weight2_tab;

        if( h->nr_count[cat] > (cat ? (1<<16) : (1<<18)) )
        {
            for( i = 0; i < size; i++ )
                h->nr_residual_sum[cat][i] >>= 1;
            h->nr_count[cat] >>= 1;
        }

        for( i = 0; i < size; i++ )
            h->nr_offset[cat][i] =
                ((uint64_t)h->param.analyse.i_noise_reduction * h->nr_count[cat]
                 + h->nr_residual_sum[cat][i]/2)
              / ((uint64_t)h->nr_residual_sum[cat][i] * weight[i]/256 + 1);
    }
}

void x264_denoise_dct( x264_t *h, int16_t *dct )
{
    const int cat = h->mb.b_transform_8x8;
    int i;

    h->nr_count[cat]++;

    for( i = (cat ? 63 : 15); i >= 1; i-- )
    {
        int level = dct[i];
        if( level )
        {
            if( level > 0 )
            {
                h->nr_residual_sum[cat][i] += level;
                level -= h->nr_offset[cat][i];
                if( level < 0 )
                    level = 0;
            }
            else
            {
                h->nr_residual_sum[cat][i] -= level;
                level += h->nr_offset[cat][i];
                if( level > 0 )
                    level = 0;
            }
            dct[i] = level;
        }
    }
}

/*****************************************************************************
 * RD only; 4 calls to this do not make up for one macroblock_encode.
 * doesn't transform chroma dc.
 *****************************************************************************/
void x264_macroblock_encode_p8x8( x264_t *h, int i8 )
{
    int i_qp = h->mb.i_qp;
    uint8_t *p_fenc = h->mb.pic.p_fenc[0] + (i8&1)*8 + (i8>>1)*8*FENC_STRIDE;
    uint8_t *p_fdec = h->mb.pic.p_fdec[0] + (i8&1)*8 + (i8>>1)*8*FDEC_STRIDE;
    int b_decimate = h->sh.i_type == SLICE_TYPE_B || h->param.analyse.b_dct_decimate;
    int nnz8x8;
    int ch;

    x264_mb_mc_8x8( h, i8 );

    if( h->mb.b_transform_8x8 )
    {
        DECLARE_ALIGNED( int16_t, dct8x8[8][8], 16 );
        h->dctf.sub8x8_dct8( dct8x8, p_fenc, p_fdec );
        h->quantf.quant_8x8( dct8x8, h->quant8_mf[CQM_8PY][i_qp], h->quant8_bias[CQM_8PY][i_qp] );
        h->zigzagf.scan_8x8( h->dct.luma8x8[i8], dct8x8 );

        if( b_decimate )
            nnz8x8 = 4 <= x264_mb_decimate_score( h->dct.luma8x8[i8], 64 );
        else
            nnz8x8 = array_non_zero( dct8x8 );

        if( nnz8x8 )
        {
            h->quantf.dequant_8x8( dct8x8, h->dequant8_mf[CQM_8PY], i_qp );
            h->dctf.add8x8_idct8( p_fdec, dct8x8 );
        }
    }
    else
    {
        int i4;
        DECLARE_ALIGNED( int16_t, dct4x4[4][4][4], 16 );
        h->dctf.sub8x8_dct( dct4x4, p_fenc, p_fdec );
        h->quantf.quant_4x4( dct4x4[0], h->quant4_mf[CQM_4PY][i_qp], h->quant4_bias[CQM_4PY][i_qp] );
        h->quantf.quant_4x4( dct4x4[1], h->quant4_mf[CQM_4PY][i_qp], h->quant4_bias[CQM_4PY][i_qp] );
        h->quantf.quant_4x4( dct4x4[2], h->quant4_mf[CQM_4PY][i_qp], h->quant4_bias[CQM_4PY][i_qp] );
        h->quantf.quant_4x4( dct4x4[3], h->quant4_mf[CQM_4PY][i_qp], h->quant4_bias[CQM_4PY][i_qp] );
        for( i4 = 0; i4 < 4; i4++ )
            h->zigzagf.scan_4x4( h->dct.block[i8*4+i4].luma4x4, dct4x4[i4] );

        if( b_decimate )
        {
            int i_decimate_8x8 = 0;
            for( i4 = 0; i4 < 4 && i_decimate_8x8 < 4; i4++ )
                i_decimate_8x8 += x264_mb_decimate_score( h->dct.block[i8*4+i4].luma4x4, 16 );
            nnz8x8 = 4 <= i_decimate_8x8;
        }
        else
            nnz8x8 = array_non_zero( dct4x4 );

        if( nnz8x8 )
        {
            for( i4 = 0; i4 < 4; i4++ )
                h->quantf.dequant_4x4( dct4x4[i4], h->dequant4_mf[CQM_4PY], i_qp );
            h->dctf.add8x8_idct( p_fdec, dct4x4 );
        }
    }

    i_qp = h->mb.i_chroma_qp;

    for( ch = 0; ch < 2; ch++ )
    {
        DECLARE_ALIGNED( int16_t, dct4x4[4][4], 16 );
        p_fenc = h->mb.pic.p_fenc[1+ch] + (i8&1)*4 + (i8>>1)*4*FENC_STRIDE;
        p_fdec = h->mb.pic.p_fdec[1+ch] + (i8&1)*4 + (i8>>1)*4*FDEC_STRIDE;

        h->dctf.sub4x4_dct( dct4x4, p_fenc, p_fdec );
        h->quantf.quant_4x4( dct4x4, h->quant4_mf[CQM_4PC][i_qp], h->quant4_bias[CQM_4PC][i_qp] );
        h->zigzagf.scan_4x4ac( h->dct.block[16+i8+ch*4].residual_ac, dct4x4 );
        if( array_non_zero( dct4x4 ) )
        {
            h->quantf.dequant_4x4( dct4x4, h->dequant4_mf[CQM_4PC], i_qp );
            h->dctf.add4x4_idct( p_fdec, dct4x4 );
        }
    }

    if( nnz8x8 )
        h->mb.i_cbp_luma |= (1 << i8);
    else
        h->mb.i_cbp_luma &= ~(1 << i8);
    h->mb.i_cbp_chroma = 0x02;
}
