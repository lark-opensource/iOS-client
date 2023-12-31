/*
 * Toutiao ByteVC1 Decoder API: definations and structures
 * 
 * Author Jiexi Wang (wangjiexi@bytedance.com)
 *
 * Copyright (c) 2017 bytedance
 * 
 * Date 2017-11-20
 *
 * This file is part of bytevc1
 */

#ifndef BYTEVC1_DEC_H
#define BYTEVC1_DEC_H

#include <stdint.h>
#include <stdbool.h>

typedef enum PixFmt {
    PixFmtUnknown = -1,
    PixFmtI400,
    PixFmtI420,
    PixFmtI422,
    PixFmtI444,
    PixFmtCount,
} PixFmt;

typedef enum DecStat {
    DecStatOK,
    DecStatErr,
    DecStatAgain,
    DecStatEnd,
} DecStat;

typedef struct ByteVC1DecContext ByteVC1DecContext;

typedef struct InnerFrame InnerFrame;

typedef struct TTFrame TTFrame;

typedef struct TTPacket TTPacket;

typedef struct ByteVC1DecParam ByteVC1DecParam;

#if defined(WIN32) || defined(_MSC_VER) 
//#define _h_dll_export   __declspec(dllexport)
#define _h_dll_export  
#elif defined(HIDE_API)
#define _h_dll_export __attribute__ ((visibility("hidden")))
#else
// for GCC
#define _h_dll_export __attribute__ ((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif
/*TTFrame*/
_h_dll_export TTFrame * ByteVC1_alloc_frame(void);

_h_dll_export void ByteVC1_frame_init(TTFrame * frame);

_h_dll_export void ByteVC1_frame_uninit(TTFrame * frame);

_h_dll_export void ByteVC1_release_frame(TTFrame * frame);

_h_dll_export uint32_t ByteVC1_get_frame_width(TTFrame* frame);

_h_dll_export uint32_t ByteVC1_get_frame_height(TTFrame* frame);

_h_dll_export long long ByteVC1_get_frame_pts(TTFrame* frame);

_h_dll_export long long ByteVC1_get_frame_opt(TTFrame* frame);

_h_dll_export uint32_t ByteVC1_get_frame_stride(TTFrame* frame, int channel/*y,u,v*/);

_h_dll_export uint32_t ByteVC1_get_frame_linesize(TTFrame* frame, int channel/*y,u,v*/);

_h_dll_export uint8_t* ByteVC1_get_frame_data(TTFrame* frame, int channel/*y,u,v*/);

_h_dll_export uint8_t ByteVC1_get_frame_bit_depth(TTFrame* frame);

_h_dll_export int ByteVC1_get_frame_video_signal_type_present_flag(TTFrame* frame);

_h_dll_export int ByteVC1_get_frame_video_full_range_flag(TTFrame* frame);

_h_dll_export uint8_t ByteVC1_get_frame_color_primaries(TTFrame* frame);

_h_dll_export uint8_t ByteVC1_get_frame_color_trc(TTFrame* frame);

_h_dll_export uint8_t ByteVC1_get_frame_colorspace(TTFrame* frame);

_h_dll_export PixFmt ByteVC1_get_frame_pix_fmt(TTFrame* frame);

_h_dll_export int32_t ByteVC1_get_frame_got_frame(TTFrame* frame);

_h_dll_export uint8_t ByteVC1_get_frame_slice_type(TTFrame* frame);/*0: B slice, 1: P slice 2: I slice*/

/*TTPacket*/
_h_dll_export TTPacket* ByteVC1_alloc_packet(void);

_h_dll_export void ByteVC1_free_packet(TTPacket* packet);

_h_dll_export void ByteVC1_set_packet_flag(TTPacket* packet, uint32_t flag);

_h_dll_export uint32_t ByteVC1_get_packet_flag(TTPacket* packet);

_h_dll_export void ByteVC1_set_packet_bs_len(TTPacket* packet, uint32_t bs_len);

_h_dll_export uint32_t ByteVC1_get_packet_bs_len(TTPacket* packet);

_h_dll_export void ByteVC1_set_packet_bs(TTPacket* packet, uint8_t* bs);

_h_dll_export uint8_t* ByteVC1_get_packet_bs(TTPacket* packet);

_h_dll_export void ByteVC1_set_packet_drop_frame(TTPacket* packet, int32_t drop_frame);

_h_dll_export int32_t ByteVC1_get_packet_drop_frame(TTPacket* packet);

_h_dll_export void ByteVC1_set_packet_drop_rate(TTPacket* packet, int32_t drop_rate);

_h_dll_export int32_t ByteVC1_get_packet_drop_rate(TTPacket* packet);

_h_dll_export void ByteVC1_set_packet_pts(TTPacket* packet, long long pts);

_h_dll_export long long ByteVC1_get_packet_pts(TTPacket* packet);

_h_dll_export void ByteVC1_set_packet_opt(TTPacket* packet, long long opt);

_h_dll_export long long ByteVC1_get_packet_opt(TTPacket* packet);

/*ByteVC1DecParam*/
_h_dll_export ByteVC1DecParam* ByteVC1_alloc_default_param();

_h_dll_export void ByteVC1_free_param(ByteVC1DecParam* param);

_h_dll_export void ByteVC1_set_param_threads(ByteVC1DecParam* param, int32_t threads);

_h_dll_export int32_t ByteVC1_get_param_threads(ByteVC1DecParam* param);

_h_dll_export void ByteVC1_set_param_frames(ByteVC1DecParam* param, int32_t frames);

_h_dll_export int32_t ByteVC1_get_param_frames(ByteVC1DecParam* param);

_h_dll_export void ByteVC1_set_param_output_method(ByteVC1DecParam* param, uint32_t output_method);

_h_dll_export uint32_t ByteVC1_get_param_output_method(ByteVC1DecParam* param);

_h_dll_export void ByteVC1_set_param_error_protection(ByteVC1DecParam* param, uint32_t error_protection);

_h_dll_export uint32_t ByteVC1_get_param_error_protection(ByteVC1DecParam* param);

_h_dll_export void ByteVC1_set_param_log_level(ByteVC1DecParam* param, int32_t log_level);

_h_dll_export int32_t ByteVC1_get_param_log_level(ByteVC1DecParam* param);

_h_dll_export void ByteVC1_set_param_crop_x0(ByteVC1DecParam* param, int32_t crop_x0);

_h_dll_export int32_t ByteVC1_get_param_crop_x0(ByteVC1DecParam* param);

_h_dll_export void ByteVC1_set_param_crop_y0(ByteVC1DecParam* param, int32_t crop_y0);

_h_dll_export int32_t ByteVC1_get_param_crop_y0(ByteVC1DecParam* param);

_h_dll_export void ByteVC1_set_param_crop_width(ByteVC1DecParam* param, int32_t crop_width);

_h_dll_export int32_t ByteVC1_get_param_crop_width(ByteVC1DecParam* param);

_h_dll_export void ByteVC1_set_param_crop_height(ByteVC1DecParam* param, uint32_t crop_height);

_h_dll_export uint32_t ByteVC1_get_param_crop_height(ByteVC1DecParam* param);

_h_dll_export void ByteVC1_get_version(char * version);

_h_dll_export int ByteVC1_get_linesize_Y(int width);

_h_dll_export int ByteVC1_get_linesize_UV(int width);

_h_dll_export ByteVC1DecContext * ByteVC1_dec_create(ByteVC1DecParam * param);

_h_dll_export void ByteVC1_dec_flush(ByteVC1DecContext * ctx, bool clear_cache);

_h_dll_export void ByteVC1_dec_destroy(ByteVC1DecContext * ctx);

_h_dll_export int ByteVC1_dec_decode(ByteVC1DecContext * ctx, TTPacket * packet, TTFrame * frame);

_h_dll_export DecStat ByteVC1_send_packet(ByteVC1DecContext * ctx, TTPacket * packet);

_h_dll_export DecStat ByteVC1_get_frame(ByteVC1DecContext * ctx, TTFrame * frame);

_h_dll_export int ByteVC1_return_frame(ByteVC1DecContext * dec_ctx, TTFrame * frame);

_h_dll_export DecStat ByteVC1_get_async_frame(ByteVC1DecContext * ctx, TTFrame * frame);

_h_dll_export int ByteVC1_return_async_frame(ByteVC1DecContext * dec_ctx, TTFrame * frame);

_h_dll_export void ByteVC1_dec_async_destroy(ByteVC1DecContext * ctx);

_h_dll_export int ByteVC1_get_bit_depth(ByteVC1DecContext * ctx);

_h_dll_export int ByteVC1_get_pix_fmt(ByteVC1DecContext * ctx);

_h_dll_export uint32_t get_next_access_unit(unsigned char * data, unsigned int size, unsigned int * au_size);
/*level none: 0, error: 1, warning: 2, info: 3, debug: 4, full: 5*/
typedef int (*ByteVC1_log_callback) (void* avcl, int level, const char* fmt, ...); /* same as ffmpeg av_log, avcl is invalid*/
_h_dll_export void ByteVC1_set_log_callback(ByteVC1DecContext* ctx, ByteVC1_log_callback callback);
_h_dll_export void ByteVC1_set_log_level(ByteVC1DecContext* ctx, int level);
_h_dll_export void ByteVC1_set_avcl(ByteVC1DecContext* ctx, void* avcl);
#ifdef __cplusplus
}
#endif
#endif
