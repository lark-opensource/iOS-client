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

#import "InputParameter.h"
#import "image_processing.h"
#import "internal_smash.h"
#import "jsonwrapper.hpp"
#import "smash_base.h"
#import "smash_cJSON.h"
#import "smash_module_tpl.h"
#import "smash_moment_base.h"
#import "smash_runtime_info.h"
#import "tt_bench.h"
#import "tt_common.h"
#import "tt_log.h"
#import "tt_utils.h"

FOUNDATION_EXPORT double smashVersionNumber;
FOUNDATION_EXPORT const unsigned char smashVersionString[];