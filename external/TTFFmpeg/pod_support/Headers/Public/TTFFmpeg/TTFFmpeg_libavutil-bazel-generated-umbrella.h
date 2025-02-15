#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "libavutil/adler32.h"
#import "libavutil/aes.h"
#import "libavutil/aes_ctr.h"
#import "libavutil/arm64/avconfig.h"
#import "libavutil/arm64/ffversion.h"
#import "libavutil/armv7/avconfig.h"
#import "libavutil/armv7/ffversion.h"
#import "libavutil/attributes.h"
#import "libavutil/audio_fifo.h"
#import "libavutil/avassert.h"
#import "libavutil/avconfig.h"
#import "libavutil/avstring.h"
#import "libavutil/avutil.h"
#import "libavutil/base64.h"
#import "libavutil/blowfish.h"
#import "libavutil/bprint.h"
#import "libavutil/bswap.h"
#import "libavutil/buffer.h"
#import "libavutil/camellia.h"
#import "libavutil/cast5.h"
#import "libavutil/channel_layout.h"
#import "libavutil/check_info.h"
#import "libavutil/common.h"
#import "libavutil/config.h"
#import "libavutil/cpu.h"
#import "libavutil/crc.h"
#import "libavutil/des.h"
#import "libavutil/dict.h"
#import "libavutil/display.h"
#import "libavutil/dovi_meta.h"
#import "libavutil/downmix_info.h"
#import "libavutil/drm.h"
#import "libavutil/encryption_info.h"
#import "libavutil/error.h"
#import "libavutil/eval.h"
#import "libavutil/ffversion.h"
#import "libavutil/fifo.h"
#import "libavutil/file.h"
#import "libavutil/frame.h"
#import "libavutil/hash.h"
#import "libavutil/hmac.h"
#import "libavutil/hwcontext.h"
#import "libavutil/hwcontext_cuda.h"
#import "libavutil/hwcontext_dxva2.h"
#import "libavutil/hwcontext_qsv.h"
#import "libavutil/hwcontext_vaapi.h"
#import "libavutil/hwcontext_vdpau.h"
#import "libavutil/hwcontext_videotoolbox.h"
#import "libavutil/imgutils.h"
#import "libavutil/intfloat.h"
#import "libavutil/intreadwrite.h"
#import "libavutil/lfg.h"
#import "libavutil/log.h"
#import "libavutil/macros.h"
#import "libavutil/mastering_display_metadata.h"
#import "libavutil/mathematics.h"
#import "libavutil/md5.h"
#import "libavutil/mdl_info_wrapper.h"
#import "libavutil/mem.h"
#import "libavutil/motion_vector.h"
#import "libavutil/murmur3.h"
#import "libavutil/opt.h"
#import "libavutil/parseutils.h"
#import "libavutil/pixdesc.h"
#import "libavutil/pixelutils.h"
#import "libavutil/pixfmt.h"
#import "libavutil/random_seed.h"
#import "libavutil/rational.h"
#import "libavutil/rc4.h"
#import "libavutil/replaygain.h"
#import "libavutil/reverse.h"
#import "libavutil/ripemd.h"
#import "libavutil/samplefmt.h"
#import "libavutil/sha.h"
#import "libavutil/sha512.h"
#import "libavutil/spherical.h"
#import "libavutil/stereo3d.h"
#import "libavutil/tea.h"
#import "libavutil/thread.h"
#import "libavutil/threadmessage.h"
#import "libavutil/time.h"
#import "libavutil/time_internal.h"
#import "libavutil/timecode.h"
#import "libavutil/timestamp.h"
#import "libavutil/tree.h"
#import "libavutil/ttexport.h"
#import "libavutil/ttmapp.h"
#import "libavutil/twofish.h"
#import "libavutil/version.h"
#import "libavutil/x86_64/avconfig.h"
#import "libavutil/x86_64/ffversion.h"
#import "libavutil/xtea.h"

FOUNDATION_EXPORT double TTFFmpegVersionNumber;
FOUNDATION_EXPORT const unsigned char TTFFmpegVersionString[];