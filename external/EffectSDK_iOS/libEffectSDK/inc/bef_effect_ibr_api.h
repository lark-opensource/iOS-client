//
//  bef_effect_ibr_api.h
//  effect_sdk
//
//  Created by 徐以波 on 2021/11/15.
//
#ifndef bef_effect_ibr_api_h
#define bef_effect_ibr_api_h

#include "bef_effect_ibr_define.h"
#include "bef_effect_public_define.h"

/** 
 * set ibr decoder methods
 * @param methods ibr decoder methods struct handle
 * @return 0: error, 1: success
 */
BEF_SDK_API int bef_effect_set_ibr_decoder_methods(ibr_decoder_methods* methods);

#endif /* bef_effect_ibr_api_h */
