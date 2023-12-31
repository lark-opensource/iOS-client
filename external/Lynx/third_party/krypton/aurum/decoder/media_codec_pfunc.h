// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_KRYPTON_AURUM_MEDIA_CODEC_PFUNCS_H_
#define LYNX_KRYPTON_AURUM_MEDIA_CODEC_PFUNCS_H_

#ifdef AURUM_NDKVER_LT21

#include <stdint.h>
#include <sys/types.h>

typedef enum {
  AMEDIA_OK = 0,

  /**
   * This indicates required resource was not able to be allocated.
   */
  AMEDIACODEC_ERROR_INSUFFICIENT_RESOURCE = 1100,

  /**
   * This indicates the resource manager reclaimed the media resource used by
   * the codec. With this error, the codec must be released, as it has moved to
   * terminal state.
   */
  AMEDIACODEC_ERROR_RECLAIMED = 1101,

  AMEDIA_ERROR_BASE = -10000,
  AMEDIA_ERROR_UNKNOWN = AMEDIA_ERROR_BASE,
  AMEDIA_ERROR_MALFORMED = AMEDIA_ERROR_BASE - 1,
  AMEDIA_ERROR_UNSUPPORTED = AMEDIA_ERROR_BASE - 2,
  AMEDIA_ERROR_INVALID_OBJECT = AMEDIA_ERROR_BASE - 3,
  AMEDIA_ERROR_INVALID_PARAMETER = AMEDIA_ERROR_BASE - 4,
  AMEDIA_ERROR_INVALID_OPERATION = AMEDIA_ERROR_BASE - 5,
  AMEDIA_ERROR_END_OF_STREAM = AMEDIA_ERROR_BASE - 6,
  AMEDIA_ERROR_IO = AMEDIA_ERROR_BASE - 7,
  AMEDIA_ERROR_WOULD_BLOCK = AMEDIA_ERROR_BASE - 8,

  AMEDIA_DRM_ERROR_BASE = -20000,
  AMEDIA_DRM_NOT_PROVISIONED = AMEDIA_DRM_ERROR_BASE - 1,
  AMEDIA_DRM_RESOURCE_BUSY = AMEDIA_DRM_ERROR_BASE - 2,
  AMEDIA_DRM_DEVICE_REVOKED = AMEDIA_DRM_ERROR_BASE - 3,
  AMEDIA_DRM_SHORT_BUFFER = AMEDIA_DRM_ERROR_BASE - 4,
  AMEDIA_DRM_SESSION_NOT_OPENED = AMEDIA_DRM_ERROR_BASE - 5,
  AMEDIA_DRM_TAMPER_DETECTED = AMEDIA_DRM_ERROR_BASE - 6,
  AMEDIA_DRM_VERIFY_FAILED = AMEDIA_DRM_ERROR_BASE - 7,
  AMEDIA_DRM_NEED_KEY = AMEDIA_DRM_ERROR_BASE - 8,
  AMEDIA_DRM_LICENSE_EXPIRED = AMEDIA_DRM_ERROR_BASE - 9,

  AMEDIA_IMGREADER_ERROR_BASE = -30000,
  AMEDIA_IMGREADER_NO_BUFFER_AVAILABLE = AMEDIA_IMGREADER_ERROR_BASE - 1,
  AMEDIA_IMGREADER_MAX_IMAGES_ACQUIRED = AMEDIA_IMGREADER_ERROR_BASE - 2,
  AMEDIA_IMGREADER_CANNOT_LOCK_IMAGE = AMEDIA_IMGREADER_ERROR_BASE - 3,
  AMEDIA_IMGREADER_CANNOT_UNLOCK_IMAGE = AMEDIA_IMGREADER_ERROR_BASE - 4,
  AMEDIA_IMGREADER_IMAGE_NOT_LOCKED = AMEDIA_IMGREADER_ERROR_BASE - 5,

} media_status_t;

// @file NdkMediaCodec.h

struct ANativeWindow;
typedef struct ANativeWindow ANativeWindow;

struct AMediaCodec;
typedef struct AMediaCodec AMediaCodec;

struct AMediaFormat;
typedef struct AMediaFormat AMediaFormat;

struct AMediaCrypto;
typedef struct AMediaCrypto AMediaCrypto;

struct AMediaCodecBufferInfo {
  int32_t offset;
  int32_t size;
  int64_t presentationTimeUs;
  uint32_t flags;
};
typedef struct AMediaCodecBufferInfo AMediaCodecBufferInfo;
typedef struct AMediaCodecCryptoInfo AMediaCodecCryptoInfo;

enum {
  AMEDIACODEC_BUFFER_FLAG_CODEC_CONFIG = 2,
  AMEDIACODEC_BUFFER_FLAG_END_OF_STREAM = 4,
  AMEDIACODEC_BUFFER_FLAG_PARTIAL_FRAME = 8,

  AMEDIACODEC_CONFIGURE_FLAG_ENCODE = 1,
  AMEDIACODEC_INFO_OUTPUT_BUFFERS_CHANGED = -3,
  AMEDIACODEC_INFO_OUTPUT_FORMAT_CHANGED = -2,
  AMEDIACODEC_INFO_TRY_AGAIN_LATER = -1,
};

/**
 * Called when an input buffer becomes available.
 * The specified index is the index of the available input buffer.
 */
typedef void (*AMediaCodecOnAsyncInputAvailable)(AMediaCodec *codec,
                                                 void *userdata, int32_t index);
/**
 * Called when an output buffer becomes available.
 * The specified index is the index of the available output buffer.
 * The specified bufferInfo contains information regarding the available output
 * buffer.
 */
typedef void (*AMediaCodecOnAsyncOutputAvailable)(
    AMediaCodec *codec, void *userdata, int32_t index,
    AMediaCodecBufferInfo *bufferInfo);
/**
 * Called when the output format has changed.
 * The specified format contains the new output format.
 */
typedef void (*AMediaCodecOnAsyncFormatChanged)(AMediaCodec *codec,
                                                void *userdata,
                                                AMediaFormat *format);
/**
 * Called when the MediaCodec encountered an error.
 * The specified actionCode indicates the possible actions that client can take,
 * and it can be checked by calling AMediaCodecActionCode_isRecoverable or
 * AMediaCodecActionCode_isTransient. If both
 * AMediaCodecActionCode_isRecoverable() and AMediaCodecActionCode_isTransient()
 * return false, then the codec error is fatal and the codec must be deleted.
 * The specified detail may contain more detailed messages about this error.
 */
typedef void (*AMediaCodecOnAsyncError)(AMediaCodec *codec, void *userdata,
                                        media_status_t error,
                                        int32_t actionCode, const char *detail);

struct AMediaCodecOnAsyncNotifyCallback {
  AMediaCodecOnAsyncInputAvailable onAsyncInputAvailable;
  AMediaCodecOnAsyncOutputAvailable onAsyncOutputAvailable;
  AMediaCodecOnAsyncFormatChanged onAsyncFormatChanged;
  AMediaCodecOnAsyncError onAsyncError;
};

/**
 * Create codec by name. Use this if you know the exact codec you want to use.
 * When configuring, you will need to specify whether to use the codec as an
 * encoder or decoder.
 */
typedef AMediaCodec *(*pf_AMediaCodec_createCodecByName)(const char *name);

/**
 * Create codec by mime type. Most applications will use this, specifying a
 * mime type obtained from media extractor.
 */
typedef AMediaCodec *(*pf_AMediaCodec_createDecoderByType)(
    const char *mime_type);

/**
 * Create encoder by name.
 */
typedef AMediaCodec *(*pf_AMediaCodec_createEncoderByType)(
    const char *mime_type);

/**
 * delete the codec and free its resources
 */
typedef media_status_t (*pf_AMediaCodec_delete)(AMediaCodec *);

/**
 * Configure the codec. For decoding you would typically get the format from an
 * extractor.
 */
typedef media_status_t (*pf_AMediaCodec_configure)(AMediaCodec *,
                                                   const AMediaFormat *format,
                                                   ANativeWindow *surface,
                                                   AMediaCrypto *crypto,
                                                   uint32_t flags);

/**
 * Start the codec. A codec must be configured before it can be started, and
 * must be started before buffers can be sent to it.
 */
typedef media_status_t (*pf_AMediaCodec_start)(AMediaCodec *);

/**
 * Stop the codec.
 */
typedef media_status_t (*pf_AMediaCodec_stop)(AMediaCodec *);

/*
 * Flush the codec's input and output. All indices previously returned from
 * calls to AMediaCodec_dequeueInputBuffer and AMediaCodec_dequeueOutputBuffer
 * become invalid.
 */
typedef media_status_t (*pf_AMediaCodec_flush)(AMediaCodec *);

/**
 * Get an input buffer. The specified buffer index must have been previously
 * obtained from dequeueInputBuffer, and not yet queued.
 */
typedef uint8_t *(*pf_AMediaCodec_getInputBuffer)(AMediaCodec *, size_t idx,
                                                  size_t *out_size);

/**
 * Get an output buffer. The specified buffer index must have been previously
 * obtained from dequeueOutputBuffer, and not yet queued.
 */
typedef uint8_t *(*pf_AMediaCodec_getOutputBuffer)(AMediaCodec *, size_t idx,
                                                   size_t *out_size);

/**
 * Get the index of the next available input buffer. An app will typically use
 * this with getInputBuffer() to get a pointer to the buffer, then copy the data
 * to be encoded or decoded into the buffer before passing it to the codec.
 */
typedef ssize_t (*pf_AMediaCodec_dequeueInputBuffer)(AMediaCodec *,
                                                     int64_t timeoutUs);

/*
 * __USE_FILE_OFFSET64 changes the type of off_t in LP32, which changes the ABI
 * of these declarations to  not match the platform. In that case, define these
 * APIs in terms of int32_t instead. Passing an off_t in this situation will
 * result in silent truncation unless the user builds with -Wconversion, but the
 * only alternative it to not expose them at all for this configuration, which
 * makes the whole API unusable.
 *
 * https://github.com/android-ndk/ndk/issues/459
 */
#if defined(__USE_FILE_OFFSET64) && !defined(__LP64__)
#define _off_t_compat int32_t
#else
#define _off_t_compat off_t
#endif /* defined(__USE_FILE_OFFSET64) && !defined(__LP64__) */

#if (defined(__cplusplus) && __cplusplus >= 201103L) || \
    __STDC_VERSION__ >= 201112L
#include <assert.h>
static_assert(sizeof(_off_t_compat) == sizeof(long),
              "_off_t_compat does not match the NDK ABI. See "
              "https://github.com/android-ndk/ndk/issues/459.");
#endif

/**
 * Send the specified buffer to the codec for processing.
 */
typedef media_status_t (*pf_AMediaCodec_queueInputBuffer)(
    AMediaCodec *, size_t idx, _off_t_compat offset, size_t size, uint64_t time,
    uint32_t flags);

#undef _off_t_compat

/**
 * Get the index of the next available buffer of processed data.
 */
typedef ssize_t (*pf_AMediaCodec_dequeueOutputBuffer)(
    AMediaCodec *, AMediaCodecBufferInfo *info, int64_t timeoutUs);
typedef AMediaFormat *(*pf_AMediaCodec_getOutputFormat)(AMediaCodec *);

/**
 * If you are done with a buffer, use this call to return the buffer to
 * the codec. If you previously specified a surface when configuring this
 * video decoder you can optionally render the buffer.
 */
typedef media_status_t (*pf_AMediaCodec_releaseOutputBuffer)(AMediaCodec *,
                                                             size_t idx,
                                                             bool render);

// @file NdkMediaMuxer.h

struct AMediaMuxer;
typedef struct AMediaMuxer AMediaMuxer;

typedef enum {
  AMEDIAMUXER_OUTPUT_FORMAT_MPEG_4 = 0,
  AMEDIAMUXER_OUTPUT_FORMAT_WEBM = 1,
} OutputFormat;

/**
 * Create new media muxer
 */
typedef AMediaMuxer *(*pf_AMediaMuxer_new)(int fd, OutputFormat format);

/**
 * Delete a previously created media muxer
 */
typedef media_status_t (*pf_AMediaMuxer_delete)(AMediaMuxer *);

/**
 * Set and store the geodata (latitude and longitude) in the output file.
 * This method should be called before AMediaMuxer_start. The geodata is stored
 * in udta box if the output format is AMEDIAMUXER_OUTPUT_FORMAT_MPEG_4, and is
 * ignored for other output formats.
 * The geodata is stored according to ISO-6709 standard.
 *
 * Both values are specified in degrees.
 * Latitude must be in the range [-90, 90].
 * Longitude must be in the range [-180, 180].
 */
typedef media_status_t (*pf_AMediaMuxer_setLocation)(AMediaMuxer *,
                                                     float latitude,
                                                     float longitude);

/**
 * Sets the orientation hint for output video playback.
 * This method should be called before AMediaMuxer_start. Calling this
 * method will not rotate the video frame when muxer is generating the file,
 * but add a composition matrix containing the rotation angle in the output
 * video if the output format is AMEDIAMUXER_OUTPUT_FORMAT_MPEG_4, so that a
 * video player can choose the proper orientation for playback.
 * Note that some video players may choose to ignore the composition matrix
 * during playback.
 * The angle is specified in degrees, clockwise.
 * The supported angles are 0, 90, 180, and 270 degrees.
 */
typedef media_status_t (*pf_AMediaMuxer_setOrientationHint)(AMediaMuxer *,
                                                            int degrees);

/**
 * Adds a track with the specified format.
 * Returns the index of the new track or a negative value in case of failure,
 * which can be interpreted as a media_status_t.
 */
typedef ssize_t (*pf_AMediaMuxer_addTrack)(AMediaMuxer *,
                                           const AMediaFormat *format);

/**
 * Start the muxer. Should be called after AMediaMuxer_addTrack and
 * before AMediaMuxer_writeSampleData.
 */
typedef media_status_t (*pf_AMediaMuxer_start)(AMediaMuxer *);

/**
 * Stops the muxer.
 * Once the muxer stops, it can not be restarted.
 */
typedef media_status_t (*pf_AMediaMuxer_stop)(AMediaMuxer *);

/**
 * Writes an encoded sample into the muxer.
 * The application needs to make sure that the samples are written into
 * the right tracks. Also, it needs to make sure the samples for each track
 * are written in chronological order (e.g. in the order they are provided
 * by the encoder.)
 */
typedef media_status_t (*pf_AMediaMuxer_writeSampleData)(
    AMediaMuxer *muxer, size_t trackIdx, const uint8_t *data,
    const AMediaCodecBufferInfo *info);

// @file NdkMediaFormat.h

typedef AMediaFormat *(*pf_AMediaFormat_new)();
typedef media_status_t (*pf_AMediaFormat_delete)(AMediaFormat *);

/**
 * Human readable representation of the format. The returned string is owned by
 * the format, and remains valid until the next call to toString, or until the
 * format is deleted.
 */
typedef const char *(*pf_AMediaFormat_toString)(AMediaFormat *);

typedef bool (*pf_AMediaFormat_getInt32)(AMediaFormat *, const char *name,
                                         int32_t *out);
typedef bool (*pf_AMediaFormat_getInt64)(AMediaFormat *, const char *name,
                                         int64_t *out);
typedef bool (*pf_AMediaFormat_getFloat)(AMediaFormat *, const char *name,
                                         float *out);
typedef bool (*pf_AMediaFormat_getSize)(AMediaFormat *, const char *name,
                                        size_t *out);
/**
 * The returned data is owned by the format and remains valid as long as the
 * named entry is part of the format.
 */
typedef bool (*pf_AMediaFormat_getBuffer)(AMediaFormat *, const char *name,
                                          void **data, size_t *size);
/**
 * The returned string is owned by the format, and remains valid until the next
 * call to getString, or until the format is deleted.
 */
typedef bool (*pf_AMediaFormat_getString)(AMediaFormat *, const char *name,
                                          const char **out);

typedef void (*pf_AMediaFormat_setInt32)(AMediaFormat *, const char *name,
                                         int32_t value);
typedef void (*pf_AMediaFormat_setInt64)(AMediaFormat *, const char *name,
                                         int64_t value);
typedef void (*pf_AMediaFormat_setFloat)(AMediaFormat *, const char *name,
                                         float value);
/**
 * The provided string is copied into the format.
 */
typedef void (*pf_AMediaFormat_setString)(AMediaFormat *, const char *name,
                                          const char *value);
/**
 * The provided data is copied into the format.
 */
typedef void (*pf_AMediaFormat_setBuffer)(AMediaFormat *, const char *name,
                                          const void *data, size_t size);

#define DEFINE_MEDIA_FORMAT_KEYS                                          \
  DEFINE_FUNC(AAC_PROFILE, "aac-profile")                                 \
  DEFINE_FUNC(BIT_RATE, "bit-rate")                                       \
  DEFINE_FUNC(CHANNEL_COUNT, "channel-count")                             \
  DEFINE_FUNC(CHANNEL_MASK, "channel-mask")                               \
  DEFINE_FUNC(COLOR_FORMAT, "color-format")                               \
  DEFINE_FUNC(DURATION, "duration")                                       \
  DEFINE_FUNC(FLAC_COMPRESSION_LEVEL, "flac-compression-level")           \
  DEFINE_FUNC(FRAME_RATE, "frame-rate")                                   \
  DEFINE_FUNC(HEIGHT, "height")                                           \
  DEFINE_FUNC(IS_ADTS, "is-adts")                                         \
  DEFINE_FUNC(IS_AUTOSELECT, "is-autoselect")                             \
  DEFINE_FUNC(IS_DEFAULT, "is-default")                                   \
  DEFINE_FUNC(IS_FORCED_SUBTITLE, "is-forced-subtitle")                   \
  DEFINE_FUNC(I_FRAME_INTERVAL, "is-forced-subtitle")                     \
  DEFINE_FUNC(LANGUAGE, "language")                                       \
  DEFINE_FUNC(MAX_HEIGHT, "max-height")                                   \
  DEFINE_FUNC(MAX_INPUT_SIZE, "max-input-size")                           \
  DEFINE_FUNC(MAX_WIDTH, "max-width")                                     \
  DEFINE_FUNC(MIME, "mime")                                               \
  DEFINE_FUNC(PUSH_BLANK_BUFFERS_ON_STOP, "push-blank-buffers-on-stop")   \
  DEFINE_FUNC(REPEAT_PREVIOUS_FRAME_AFTER, "repeat-previous-frame-after") \
  DEFINE_FUNC(SAMPLE_RATE, "sample-rate")                                 \
  DEFINE_FUNC(STRIDE, "stride")                                           \
  DEFINE_FUNC(WIDTH, "width")

#define DEFINE_FUNC(name, value) extern const char *AMEDIAFORMAT_KEY_##name;
DEFINE_MEDIA_FORMAT_KEYS
#undef DEFINE_FUNC

#define DEFINE_MEDIA_CODEC_FUNCS               \
  DEFINE_FUNC(AMediaCodec_createCodecByName)   \
  DEFINE_FUNC(AMediaCodec_createDecoderByType) \
  DEFINE_FUNC(AMediaCodec_createEncoderByType) \
  DEFINE_FUNC(AMediaCodec_configure)           \
  DEFINE_FUNC(AMediaCodec_start)               \
  DEFINE_FUNC(AMediaCodec_stop)                \
  DEFINE_FUNC(AMediaCodec_flush)               \
  DEFINE_FUNC(AMediaCodec_delete)              \
  DEFINE_FUNC(AMediaCodec_getOutputFormat)     \
  DEFINE_FUNC(AMediaCodec_dequeueInputBuffer)  \
  DEFINE_FUNC(AMediaCodec_getInputBuffer)      \
  DEFINE_FUNC(AMediaCodec_queueInputBuffer)    \
  DEFINE_FUNC(AMediaCodec_dequeueOutputBuffer) \
  DEFINE_FUNC(AMediaCodec_getOutputBuffer)     \
  DEFINE_FUNC(AMediaCodec_releaseOutputBuffer) \
  DEFINE_FUNC(AMediaFormat_new)                \
  DEFINE_FUNC(AMediaFormat_delete)             \
  DEFINE_FUNC(AMediaFormat_getInt32)           \
  DEFINE_FUNC(AMediaFormat_getInt64)           \
  DEFINE_FUNC(AMediaFormat_getFloat)           \
  DEFINE_FUNC(AMediaFormat_getSize)            \
  DEFINE_FUNC(AMediaFormat_getBuffer)          \
  DEFINE_FUNC(AMediaFormat_setInt32)           \
  DEFINE_FUNC(AMediaFormat_setInt64)           \
  DEFINE_FUNC(AMediaFormat_setFloat)           \
  DEFINE_FUNC(AMediaFormat_setString)          \
  DEFINE_FUNC(AMediaFormat_setBuffer)          \
  DEFINE_FUNC(AMediaFormat_toString)           \
  DEFINE_FUNC(AMediaMuxer_new)                 \
  DEFINE_FUNC(AMediaMuxer_delete)              \
  DEFINE_FUNC(AMediaMuxer_setLocation)         \
  DEFINE_FUNC(AMediaMuxer_setOrientationHint)  \
  DEFINE_FUNC(AMediaMuxer_addTrack)            \
  DEFINE_FUNC(AMediaMuxer_start)               \
  DEFINE_FUNC(AMediaMuxer_stop)                \
  DEFINE_FUNC(AMediaMuxer_writeSampleData)

#define DEFINE_FUNC(name) extern pf_##name name;
DEFINE_MEDIA_CODEC_FUNCS
#undef DEFINE_FUNC

extern bool LoadHostMediaCodec();

#endif  // #ifdef AURUM_NDKVER_LT21

#endif  // #ifndef LYNX_KRYPTON_AURUM_MEDIA_CODEC_PFUNCS_H_
