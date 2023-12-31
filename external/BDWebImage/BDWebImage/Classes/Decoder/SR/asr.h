#ifndef __ASR_H__
#define __ASR_H__

#include "NN265def.h"

#define CF_YUV_400     0  // ONLY Y
#define CF_YUV_410     1  // Y4X4 U1 V1
#define CF_YUV_420     2  // Y2X2 U1 V1
#define CF_YUV_422     3  // Y1X2 U1 V1
#define CF_YUV_444     4  // Y1 U1 V1
#define CF_YUV_420SP   5  // Y2X1 U1V1
#define CF_RGB8888     6

#define CF_RGB565      7  // yuv2rgb565 use

#define  ASR_DO_NOTHING		0
#define  ASR_DO_SCALE_1X1   1
#define  ASR_DO_SCALE_1o5X	2
#define  ASR_DO_SCALE_2X1	4
#define  ASR_DO_SCALE_2X2	8
#define  ASR_DO_SCALE_3X3	16
#define  ASR_DO_SCALE_4X4	32
#define  ASR_DO_SCALE_8X8	64
#define  ASR_DO_COMPARE		128


#define CHROMA_MSK_LUMA   1
#define CHROMA_MSK_UV     2
#define CHROMA_MSK_U      2
#define CHROMA_MSK_V      4




typedef struct  asr_frame {
	int             out_width;
	int             out_height;
	int             out_stride[3];
	uint8_t*        out_data[3];
}asr_frame;



typedef struct asr_param {
	unsigned char*      src[3];
	int					width;
	int					height;
	int					spit[3];
	unsigned char*      dst[3];
	int					dwidth;
	int					dheight;
	int					dpit[3];
	int					b_stretch;    //
	int					strength;     // 
	int					speed;        // 0-ultrafast,1-superfast, 2-veryfast;
	int					chroma_format_in;
	int					chroma_format_out;
	int                 chroma_mask;
	int                 border_flag;
	int					b_fxaa;       // true or false
	int					b_compare;    // true or false
	int					b_need_flip;  // output
	int					b_got_frame;  // output
}asr_param;


typedef struct asr_coeff {
	uint8_t     sobel_table[32];
	uint8_t     sqrt_table[32];
	uint8_t     sqrt_default[16];
	int32_t     hd;
	int32_t     sqrt_min;
	int32_t     sobel_mask;
	int32_t     sobel_shift;
	uint8_t     filter[1024];
}asr_coeff;

#define  ASR_TOP_BORDER  1
#define  ASR_BOT_BORDER  2



#if defined(__cplusplus)
extern "C" {
#endif//__cplusplus

	void stp_log(void* ptr, int level, const char* fmt, ...);

	void   asr2_context_initialize();

	int    alloc_asr_frame(asr_frame* the, int w, int h);
	void   free_asr_frame(asr_frame* the);
	void*  create_asr_handle(int i_thread, int b_async);
	void   release_asr_handle(void* pasr);

	int    do_frame_asr(void* pasr, asr_param* param); // seperate sr procedure;

	int    do_picture_asr(void* pasr, asr_param* param);


	//{{ combined with codec;
#define ASR_EXEC_WD        16 // avx2 code do 16 bytes each loop;
#define ASR_EXEC_WD_MSK    0x0f
	void*  asr2_frame_context_initialize(int width,int i_scale, int i_stength, int i_tap);
	void   asr2_frame_context_release(void* pasr);
	//}}

#define ut8 unsigned char
	void   asr2_block_w16(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);
	void   asr2_block_w8(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);
	void   asr2_block_w4(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);

	void   copy_block_w16(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);
	void   copy_block_w8(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);
	void   copy_block_w4(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);

	void   fx_block_w16(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);
	void   fx_block_w8(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);
	void   fx_block_w4(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);

	void   fy_block_w16(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);
	void   fy_block_w8(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);
	void   fy_block_w4(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);

	void   fill_x_block_w16(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);
	void   fill_x_block_w8(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);
	void   fill_x_block_w4(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);

	void   fill_y_block_w16(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);
	void   fill_y_block_w8(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);
	void   fill_y_block_w4(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);

	void   cubic_x_block_w16(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);
	void   cubic_x_block_w8(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);
	void   cubic_x_block_w4(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);
	void   cubic_x_block_w2(void* pasr, uint8_t* dst, uint8_t* src, int dpit, int spit, int height);

	void   cubic_y_block_w16(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);
	void   cubic_y_block_w8(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);
	void   cubic_y_block_w4(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);
	void   cubic_y_block_w2(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);

	void   fill_x_block_uv_w16(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);
	void   fill_x_block_uv_w8(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);
	void   fill_x_block_uv_w4(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);

	void   cubic_x_block_uv_w16(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);
	void   cubic_x_block_uv_w8(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);
	void   cubic_x_block_uv_w4(void* pasr, ut8* dst, ut8* src, int dpit, int spit, int height);

	void   sparse_plain_block_w32(ut8* pmap, ut8* src, int spit, int height);
	void   sparse_plain_block_w16(ut8* pmap, ut8* src, int spit, int height);
	void   sparse_plain_block_w8(ut8* pmap, ut8* src,  int spit, int height);
	void   sparse_plain_block_w4(ut8* pmap, ut8* src,  int spit, int height);

#if defined(__cplusplus)
}
#endif//__cplusplus



#endif //__ASR_H__