/*****************************************************************************
 * quant.c: h264 encoder library
 *****************************************************************************
 * Copyright (C) 2005 x264 project
 *
 * Authors: Christian Heine <sennindemokrit@gmx.net>
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

#include "common.h"

#ifdef HAVE_MMX
#include "i386/quant.h"
#endif
#ifdef ARCH_PPC
#   include "ppc/quant.h"
#endif

#define QUANT_ONE( coef, mf, f ) \
{ \
    if( (coef) > 0 ) \
        (coef) = (f + (coef)) * (mf) >> 16; \
    else \
        (coef) = - ((f - (coef)) * (mf) >> 16); \
}

static void quant_8x8( int16_t dct[8][8], uint16_t mf[64], uint16_t bias[64] )
{
    int i;
    for( i = 0; i < 64; i++ )
        QUANT_ONE( dct[0][i], mf[i], bias[i] );
}

static void quant_4x4( int16_t dct[4][4], uint16_t mf[16], uint16_t bias[16] )
{
    int i;
    for( i = 0; i < 16; i++ )
        QUANT_ONE( dct[0][i], mf[i], bias[i] );
}

static void quant_4x4_dc( int16_t dct[4][4], int mf, int bias )
{
    int i;
    for( i = 0; i < 16; i++ )
        QUANT_ONE( dct[0][i], mf, bias );
}

static void quant_2x2_dc( int16_t dct[2][2], int mf, int bias )
{
    QUANT_ONE( dct[0][0], mf, bias );
    QUANT_ONE( dct[0][1], mf, bias );
    QUANT_ONE( dct[0][2], mf, bias );
    QUANT_ONE( dct[0][3], mf, bias );
}

#define DEQUANT_SHL( x ) \
    dct[y][x] = ( dct[y][x] * dequant_mf[i_mf][y][x] ) << i_qbits

#define DEQUANT_SHR( x ) \
    dct[y][x] = ( dct[y][x] * dequant_mf[i_mf][y][x] + f ) >> (-i_qbits)

static void dequant_4x4( int16_t dct[4][4], int dequant_mf[6][4][4], int i_qp )
{
    const int i_mf = i_qp%6;
    const int i_qbits = i_qp/6 - 4;
    int y;

    if( i_qbits >= 0 )
    {
        for( y = 0; y < 4; y++ )
        {
            DEQUANT_SHL( 0 );
            DEQUANT_SHL( 1 );
            DEQUANT_SHL( 2 );
            DEQUANT_SHL( 3 );
        }
    }
    else
    {
        const int f = 1 << (-i_qbits-1);
        for( y = 0; y < 4; y++ )
        {
            DEQUANT_SHR( 0 );
            DEQUANT_SHR( 1 );
            DEQUANT_SHR( 2 );
            DEQUANT_SHR( 3 );
        }
    }
}

static void dequant_8x8( int16_t dct[8][8], int dequant_mf[6][8][8], int i_qp )
{
    const int i_mf = i_qp%6;
    const int i_qbits = i_qp/6 - 6;
    int y;

    if( i_qbits >= 0 )
    {
        for( y = 0; y < 8; y++ )
        {
            DEQUANT_SHL( 0 );
            DEQUANT_SHL( 1 );
            DEQUANT_SHL( 2 );
            DEQUANT_SHL( 3 );
            DEQUANT_SHL( 4 );
            DEQUANT_SHL( 5 );
            DEQUANT_SHL( 6 );
            DEQUANT_SHL( 7 );
        }
    }
    else
    {
        const int f = 1 << (-i_qbits-1);
        for( y = 0; y < 8; y++ )
        {
            DEQUANT_SHR( 0 );
            DEQUANT_SHR( 1 );
            DEQUANT_SHR( 2 );
            DEQUANT_SHR( 3 );
            DEQUANT_SHR( 4 );
            DEQUANT_SHR( 5 );
            DEQUANT_SHR( 6 );
            DEQUANT_SHR( 7 );
        }
    }
}

void x264_mb_dequant_2x2_dc( int16_t dct[2][2], int dequant_mf[6][4][4], int i_qp )
{
    const int i_qbits = i_qp/6 - 5;

    if( i_qbits >= 0 )
    {
        const int i_dmf = dequant_mf[i_qp%6][0][0] << i_qbits;
        dct[0][0] *= i_dmf;
        dct[0][1] *= i_dmf;
        dct[1][0] *= i_dmf;
        dct[1][1] *= i_dmf;
    }
    else
    {
        const int i_dmf = dequant_mf[i_qp%6][0][0];
        // chroma DC is truncated, not rounded
        dct[0][0] = ( dct[0][0] * i_dmf ) >> (-i_qbits);
        dct[0][1] = ( dct[0][1] * i_dmf ) >> (-i_qbits);
        dct[1][0] = ( dct[1][0] * i_dmf ) >> (-i_qbits);
        dct[1][1] = ( dct[1][1] * i_dmf ) >> (-i_qbits);
    }
}

void x264_mb_dequant_4x4_dc( int16_t dct[4][4], int dequant_mf[6][4][4], int i_qp )
{
    const int i_qbits = i_qp/6 - 6;
    int y;

    if( i_qbits >= 0 )
    {
        const int i_dmf = dequant_mf[i_qp%6][0][0] << i_qbits;

        for( y = 0; y < 4; y++ )
        {
            dct[y][0] *= i_dmf;
            dct[y][1] *= i_dmf;
            dct[y][2] *= i_dmf;
            dct[y][3] *= i_dmf;
        }
    }
    else
    {
        const int i_dmf = dequant_mf[i_qp%6][0][0];
        const int f = 1 << (-i_qbits-1);

        for( y = 0; y < 4; y++ )
        {
            dct[y][0] = ( dct[y][0] * i_dmf + f ) >> (-i_qbits);
            dct[y][1] = ( dct[y][1] * i_dmf + f ) >> (-i_qbits);
            dct[y][2] = ( dct[y][2] * i_dmf + f ) >> (-i_qbits);
            dct[y][3] = ( dct[y][3] * i_dmf + f ) >> (-i_qbits);
        }
    }
}

void x264_quant_init( x264_t *h, int cpu, x264_quant_function_t *pf )
{
    pf->quant_8x8 = quant_8x8;
    pf->quant_4x4 = quant_4x4;
    pf->quant_4x4_dc = quant_4x4_dc;
    pf->quant_2x2_dc = quant_2x2_dc;

    pf->dequant_4x4 = dequant_4x4;
    pf->dequant_8x8 = dequant_8x8;

#ifdef HAVE_MMX
    if( cpu&X264_CPU_MMX )
    {
#ifdef ARCH_X86
        pf->quant_4x4 = x264_quant_4x4_mmx;
        pf->quant_8x8 = x264_quant_8x8_mmx;
#endif
        pf->dequant_4x4 = x264_dequant_4x4_mmx;
        pf->dequant_8x8 = x264_dequant_8x8_mmx;
    }

    if( cpu&X264_CPU_MMXEXT )
    {
        pf->quant_2x2_dc = x264_quant_2x2_dc_mmxext;
#ifdef ARCH_X86
        pf->quant_4x4_dc = x264_quant_4x4_dc_mmxext;
#endif
    }

    if( cpu&X264_CPU_SSE2 )
    {
        pf->quant_4x4_dc = x264_quant_4x4_dc_sse2;
        pf->quant_4x4 = x264_quant_4x4_sse2;
        pf->quant_8x8 = x264_quant_8x8_sse2;
    }
#endif

#ifdef HAVE_SSE3
    if( cpu&X264_CPU_SSSE3 )
    {
        pf->quant_4x4_dc = x264_quant_4x4_dc_ssse3;
        pf->quant_4x4 = x264_quant_4x4_ssse3;
        pf->quant_8x8 = x264_quant_8x8_ssse3;
    }
#endif

#ifdef ARCH_PPC
    if( cpu&X264_CPU_ALTIVEC ) {
        pf->quant_2x2_dc = x264_quant_2x2_dc_altivec;
        pf->quant_4x4_dc = x264_quant_4x4_dc_altivec;
        pf->quant_4x4 = x264_quant_4x4_altivec;
        pf->quant_8x8 = x264_quant_8x8_altivec;

        pf->dequant_4x4 = x264_dequant_4x4_altivec;
        pf->dequant_8x8 = x264_dequant_8x8_altivec;
    }
#endif
}
