#ifndef bef_effect_codec_api_h
#define bef_effect_codec_api_h

#include "bef_framework_public_base_define.h"
#include "bef_effect_codec_define.h"

/** 
 * set encoder callback
 * @param encoder encoder callback struct
 * @return 0: error, 1: success
 */
BEF_SDK_API int bef_effect_codec_set_encoder(MoshEncoder* encoder);

/** 
 * set decoder callback
 * @param decoder decoder callback struct
 * @return 0: error, 1: success
 */
BEF_SDK_API int bef_effect_codec_set_decoder(MoshDecoder* decoder);

/** 
 * set decoded buffer asynchronously
 * @param handle decoder handle
 * @param nativeBuffer  pixel buffer (CVPixelBufferRef)
 * @return 0: error, 1: success
 */
BEF_SDK_API int bef_effect_codec_set_decoded_frame(mosh_codec_handle handle, void* nativeBuffer);
#endif /* bef_effect_codec_api_h */
