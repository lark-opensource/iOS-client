//
//  bef_effect_image_decoder_api.h
//          effect_sdk
//
//  Created by chaizhong on 2022/10/28.
//  Copyright © 2022 bytedance. All rights reserved.

#ifndef bef_effect_image_decode_api_h
#define bef_effect_image_decode_api_h

#include "bef_effect_image_decode_define.h"
#include "bef_effect_public_define.h"

/** 
 * set image decoder methods
 * @param methods image decoder methods struct handle
 * @param type image type
 * @return 0: error, 1: success
 */
BEF_SDK_API int bef_effect_set_image_decoder_methods(imageType type, image_decoder_methods* methods);

#endif /* bef_effect_image_decode_api_h */
