/*
 * ByteDance HEIF Decoder utils: definations and structures
 * 
 * Author Jiexi Wang (wangjiexi@bytedance.com)
 *
 * Copyright (c) 2017-2019 bytedance
 * 
 * Date 2017-10-19
 *
 * Current viersion 1.9.5.9
 *
 * This file is part of libttheif
 */

#ifndef TT_HEIF_DEC
#define TT_HEIF_DEC

#include <stdint.h>
#include <stdbool.h>

typedef struct HeifOutputStream {
    uint32_t size;
    uint8_t * data;
    uint32_t exif_size;
    uint8_t * exif_data;
    uint64_t *duration_table;
    uint32_t frame_num;
    uint32_t width;
    uint32_t height;
    uint64_t duration; //total duration
    uint64_t single_duration;
    uint8_t bit_depth;
    uint8_t * icc_data;
    uint32_t icc_size;
    uint8_t pix_fmt;
} HeifOutputStream;

typedef struct HeifDecodingParam {
    uint32_t in_sample;
    bool use_wpp;
    bool decode_rect;
    struct {
        uint32_t x; // postion-x for rectangle area
        uint32_t y; // postion-y for rectangle area
        uint32_t w; // width for rectangle area
        uint32_t h; // height for rectangle area
    } rect;
    bool use_extern_buffer;
} HeifDecodingParam;

typedef struct HeifColrInfo {
    uint32_t color_type;
    uint16_t color_primaries;
    uint16_t transfer_characteristics;
    uint16_t matrix_coefficients;
    uint8_t full_range_flag;
} HeifColrInfo;

// no need to free.
typedef struct HeifImageInfo {
    uint32_t exif_size;
    uint8_t * exif_data;
    uint32_t width;
    uint32_t height;
    uint64_t duration; //total duration ms
    uint32_t rotation;
    uint32_t frame_nums;
    bool is_sequence;
    bool has_thum;
    uint32_t thum_offset;
    uint32_t thum_size;
    uint8_t * icc_data;
    uint32_t icc_size;
    bool has_alpha;
    uint8_t bit_depth;
    HeifColrInfo colr_info;
    uint8_t chroma_format;
} HeifImageInfo;

#ifndef _TTHEIF_INTERNAL_COMPILE_

typedef struct ByteVC1DecContext ByteVC1DecContext;

typedef struct TTFrame TTFrame;

typedef struct TTBytevc1DecoderContext {
    ByteVC1DecContext * ctx;
    TTFrame * frame;
    uint32_t in_sample;
    bool wpp;
    bool decode_rect;
    struct {
        uint32_t x;
        uint32_t y;
        uint32_t w;
        uint32_t h;
    } rect;
} TTBytevc1DecoderContext;

#else

typedef struct TTBytevc1DecoderContext TTBytevc1DecoderContext;

#endif


typedef struct TTHeifBox TTHeifBox;
typedef struct TTSampleInfos TTSampleInfos;

typedef struct TTHEIFContext {
    TTBytevc1DecoderContext *dec_ctx;
    TTHeifBox *heif_box;
} TTHEIFContext;

#if defined(WIN32)
#define HEIF_DLL_EXPROT __declspec(dllexport)
#else
#define HEIF_DLL_EXPROT __attribute__ ((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Note: if decoding failed, the 'size' field of returned HeifOutputStream is 0,
// and the 'data' field of returned HeifOutputStream is NULL

// decode the heif file data to rgb data, and output the width and height of the image, wpp to use 2-threads
HEIF_DLL_EXPROT HeifOutputStream heif_decode_to_rgb(uint8_t * heif_data, uint32_t data_size, HeifDecodingParam * param);

// decode the heif file data to rgb data, and output the width and height of the image, wpp to use 2-threads
HEIF_DLL_EXPROT HeifOutputStream heif_decode_to_rgba(uint8_t * heif_data, uint32_t data_size, HeifDecodingParam * param);

// decode the heif file data to yuv420p data, and output the width and height of the image, wpp to use 2-threads
HEIF_DLL_EXPROT HeifOutputStream heif_decode_to_yuv420p(uint8_t * heif_data, uint32_t data_size, HeifDecodingParam * param);

//decode the heif file data to rgba data extern buffer
HEIF_DLL_EXPROT HeifOutputStream heif_decode_to_rgba_extern_buffer(uint8_t * heif_data, uint32_t data_size, uint8_t * dst_data, uint32_t dst_size, HeifDecodingParam * param);

// release output stream for using extern buffer api.
HEIF_DLL_EXPROT void heif_release_output_stream_extern(HeifOutputStream *output, HeifDecodingParam * param);

// only parse the undecoded bytevc1 data
HEIF_DLL_EXPROT HeifOutputStream heif_decode_to_bytevc1(uint8_t * heif_data, uint32_t data_size);

HEIF_DLL_EXPROT HeifOutputStream heif_decode_to_rgb565(uint8_t * heif_data, uint32_t data_size, HeifDecodingParam * param);

//HeifOutputStream heif_decode_to_png(uint8_t * heif_data, uint32_t data_size);

// only parse width, height and rotation angle, return true if parsing succeeded
HEIF_DLL_EXPROT bool heif_parse_meta(uint8_t * heif_data, uint32_t data_size, HeifImageInfo *heif_info);

// only parse width/height/rotation/is_sequence/duration, return true if parsing succeeded ,not need to free heif_info
HEIF_DLL_EXPROT bool heif_parse_simple_meta(uint8_t * heif_data, uint32_t data_size, HeifImageInfo *heif_info);

// judge whether this file is a .heic file
HEIF_DLL_EXPROT bool heif_judge_file_type(uint8_t * heif_data, uint32_t data_size);

// check whether this file is decodable
// returned 0: this file is decodable
// returned 1: this file is broken
// returned 2: no bytevc1 stream
// returned 3: this file is not supported
HEIF_DLL_EXPROT int check_heif_file(uint8_t * heif_data, uint32_t heif_size);

HEIF_DLL_EXPROT void heif_get_version(char version[16]);

//decode-animation
HEIF_DLL_EXPROT void heif_anim_decoder_init(TTBytevc1DecoderContext *dec_ctx, HeifDecodingParam * param);
// input: *data: bs-bytevc1 stream, size: bs-bytevc1 size
// output: return pos_start, *au_size: packet size
HEIF_DLL_EXPROT int heif_anim_get_one_packet(uint8_t *data, uint32_t size, uint32_t *au_size);

HEIF_DLL_EXPROT HeifOutputStream heif_anim_parse_bytevc1_stream(uint8_t * heif_data, uint32_t data_size);

HEIF_DLL_EXPROT HeifOutputStream heif_anim_decode_to_yuv420p(TTBytevc1DecoderContext *dec_ctx, uint8_t * bytevc1_data, uint32_t data_size);

HEIF_DLL_EXPROT HeifOutputStream heif_anim_decode_to_rgb(TTBytevc1DecoderContext *dec_ctx, uint8_t * bytevc1_data, uint32_t data_size);

HEIF_DLL_EXPROT HeifOutputStream heif_anim_decode_to_rgba(TTBytevc1DecoderContext *dec_ctx, uint8_t * bytevc1_data, uint32_t data_size);

HEIF_DLL_EXPROT void heif_anim_decoder_close(TTBytevc1DecoderContext *dec_ctx);

HEIF_DLL_EXPROT TTBytevc1DecoderContext * create_bytevc1_decoder();

HEIF_DLL_EXPROT void destroy_bytevc1_decoder(TTBytevc1DecoderContext* decoder);

HEIF_DLL_EXPROT void heif_release_output_stream(HeifOutputStream *output);

// for animated image progressive decoding
HEIF_DLL_EXPROT HeifOutputStream heif_anim_decode_one_frame(TTHEIFContext * heif_ctx, uint8_t *data, uint32_t size, uint32_t frame_index);

HEIF_DLL_EXPROT void heif_anim_heif_ctx_init(TTHEIFContext *heif_ctx, HeifDecodingParam * param);

HEIF_DLL_EXPROT int heif_anim_parse_heif_box(TTHEIFContext * heif_ctx, uint8_t * heif_data, uint32_t data_size);

HEIF_DLL_EXPROT void heif_anim_heif_ctx_release(TTHEIFContext *heif_ctx);

HEIF_DLL_EXPROT int heif_anim_get_current_frame_index(TTHEIFContext * heif_ctx, uint32_t cur_data_size);

HEIF_DLL_EXPROT HeifOutputStream heif_decode_thumb_to_rgba(uint8_t * heif_data, uint32_t data_size);

HEIF_DLL_EXPROT int heif_parse_thumb(uint8_t * heif_data, uint32_t data_size, HeifImageInfo *heif_info);

HEIF_DLL_EXPROT HeifOutputStream heif_repack_data(uint8_t * heif_data, uint32_t data_size);

#ifdef __cplusplus
}
#endif

#endif
