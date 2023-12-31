#ifndef bef_effect_codec_define_h
#define bef_effect_codec_define_h

#include "bef_effect_public_define.h"

#define CODEC_NUM_DATA_POINTERS 8
#define CODEC_FLOW_DATA_SIZE 2
#define CODEC_RESULT_ERROR              0  // return successfully
#define CODEC_RESULT_SUCCESS            1  // return successfully

typedef enum CodecPictureType
{
    CODEC_PICTURE_TYPE_NONE = 0, ///< Undefined
    CODEC_PICTURE_TYPE_I,     ///< Intra
    CODEC_PICTURE_TYPE_P,     ///< Predicted
} CodecPictureType;

typedef enum CodecPixelFormat
{
    CODEC_PIX_FMT_NONE = -1,
    CODEC_PIX_FMT_YUV420P,   ///< planar YUV 4:2:0, 12bpp, (1 Cr & Cb sample per 2x2 Y samples)
    CODEC_PIX_FMT_YUYV422,   ///< packed YUV 4:2:2, 16bpp, Y0 Cb Y1 Cr
    CODEC_PIX_FMT_RGB24,     ///< packed RGB 8:8:8, 24bpp, RGBRGB...
    CODEC_PIX_FMT_BGR24,     ///< packed RGB 8:8:8, 24bpp, BGRBGR...
} CodecPixelFormat;

typedef void* mosh_codec_handle;
typedef struct CodecParams
{
    int side; // 0: encoder, 1: decoder
    int type; // 0: VE, 1: vc0, 2: ffmpeg
} CodecParams;

// 编码后/解码前码流
typedef struct CodecPacket
{
    uint8_t* data; //h264 码流
    int   size; //data size
    int   type; //CodecPictureType I帧或P帧
} CodecPacket;

// 编码前/解码后帧
typedef struct CodecFrame
{
    int key_frame;     //1: keyFrame, 0: not
    int width, height; // frame's
    int pict_type;     // CodecPictureType I帧或P帧
    int format;        // CodecPixelFormat 
    uint8_t* data[CODEC_NUM_DATA_POINTERS]; //pointer to the picture/channel planes.
    int linesize[CODEC_NUM_DATA_POINTERS]; // size in bytes of each picture line.

    uint8_t* flow[CODEC_FLOW_DATA_SIZE]; //光流 buffer，双通道
    uint8_t* mask;                       //光流 mask
    int flowBytesPerRow[2]; 
    int maskBytesPerRow;
    void* pixelbufferRef; // CVPixelBuffer
} CodecFrame;

typedef int(*mosh_encoder_create_handle)(mosh_codec_handle* handle);
typedef int(*mosh_encoder_release_handle)(mosh_codec_handle handle);
typedef int(*mosh_encoder_encode_frame)(mosh_codec_handle handle, CodecFrame* pFrame, CodecPacket** dst);
typedef int(*mosh_encoder_release_encode_frame)(mosh_codec_handle handle, CodecPacket* dst);

typedef struct MoshEncoder
{
    mosh_encoder_create_handle createHandle;
    mosh_encoder_release_handle releaseHandle;
    mosh_encoder_encode_frame encodeFrame;
    mosh_encoder_release_encode_frame releaseFrame;
    CodecParams params;
} MoshEncoder;

// create decoder
typedef int(*mosh_decoder_create_handle)(mosh_codec_handle* handle); 

// release decoder
typedef int(*mosh_decoder_release_handle)(mosh_codec_handle handle);

/** 
 * decode one frame
 * @param pStream stream which will be decoded
 * @param dst the decoded frame, memory is not alocated by caller, caller is responesible to call mosh_decoder_release_decode_frame to release memory.
 */
typedef int(*mosh_decoder_get_decode_frame)(mosh_codec_handle handle, CodecPacket* pStream, CodecFrame** dst);

/** 
 * decode one frame asynchronously(for iOS)
 * @param pStream stream which will be decoded
 */
typedef int(*mosh_decoder_get_decode_frame_async)(mosh_codec_handle handle, CodecPacket* pStream);

/** 
 * release frame memory
 * @param dst the decoded frame which will be released
 */
typedef int(*mosh_decoder_release_decode_frame)(mosh_codec_handle handle, CodecFrame* dst);

typedef struct MoshDecoder
{
    mosh_decoder_create_handle createHandle;
    mosh_decoder_release_handle releaseHandle;
    mosh_decoder_get_decode_frame decodeFrame;
    mosh_decoder_get_decode_frame_async asyncDecodeFrame;
    mosh_decoder_release_decode_frame releaseFrame;
    CodecParams params;
} MoshDecoder;

#endif /* bef_effect_codec_define_h */
