//
//  CKConfigKeysDefines.h
//  CreationKitArch
//
//  Created by Howie He on 2021/4/2.
//

#ifndef CKConfigKeysDefines_h
#define CKConfigKeysDefines_h

#import <CreationKitInfra/ACCConfigManager.h>

// Use Filter Composer Panel
#define kConfigBool_enable_composer_filter \
ACCConfigKeyDefaultPair(@"use_filter_composer", @(NO))

// no title
#define kConfigInt_color_filter_panel \
ACCConfigKeyDefaultPair(@"colorFilterPanel", @(0))

// Internal test tool status
#define kConfigInt_effect_test_status_code \
ACCConfigKeyDefaultPair(@"effectTestStatusCode", @(0))

// New tailoring
#define kConfigBool_enable_new_clips \
ACCConfigKeyDefaultPair(@"acc_enable_cut_optimized", @(NO))

// Using effectcam props
#define kConfigBool_use_effect_cam_key \
ACCConfigKeyDefaultPair(@"acc_useEffectCamKey", @(NO))

// Using online model environment
#define kConfigBool_use_online_algrithm_model_environment \
ACCConfigKeyDefaultPair(@"use_online_algrithm_model_environment", @(YES))

// [TikTok] Optimize the prop list request function
#define kConfigInt_platform_optimize_strategy \
ACCConfigKeyDefaultPair(@"platformOptimizeStrategy", @(0))

// settings
#define kConfigDict_builtin_effect_covers \
ACCConfigKeyDefaultPair(@"builtin_effect_covers", @{})

#define kConfigArray_effect_colors \
ACCConfigKeyDefaultPair(@"acc_config_effect_colors", (@[@"#F33636",@"#9CCB65", @"#29B5F6", @"#F36836", @"#67BB6B", @"#426DF4", @"#F38F36", @"#2DC184", @"#554BBC",@"#F9A725", @"#25A69A", @"#6330E4",@"#FFCA27", @"#26C6DA", @"#7F57C2", @"#FFEE58", @"#E92747", @"#AB47BC", @"#D4E157", @"#EC3F7A"]))

//cache allowlist
#define kConfigArray_cache_clean_exclusion_list \
ACCConfigKeyDefaultPair(@"aweme_base_conf.tmp_cache_whitelist", @[@"com.apple.dyld"])

// Smart cover 3.0
#define kConfigInt_cover_style \
ACCConfigKeyDefaultPair(@"tool_cover_style", @(0))

// The cover selection page supports clipping
#define kConfigBool_enable_cover_clip \
ACCConfigKeyDefaultPair(@"enable_video_cover_clip", @(NO))

// Use online props
#define kConfigBool_use_online_effect_channel \
ACCConfigKeyDefaultPair(@"useOnlineEffectChannel", @(NO))

#define kConfigBool_use_TTEffect_platform_sdk \
ACCConfigKeyDefaultPair(@"acc_use_TTEffect_platform_sdk", @(NO))

// Is there a story tab in the camera
#define kConfigBool_enable_story_tab_in_recorder \
ACCConfigKeyDefaultPair(@"acc_enable_story_tab_in_recorder", @(YES))

// Yes: Click to record, No: Click to shoot, press to record
#define kConfigBool_story_tab_tap_hold_record \
ACCConfigKeyDefaultPair(@"acc_story_mode_interaction", @(YES))

// build in effects
#define kConfigArray_filter_effect_build_in_effects_info \
ACCConfigKeyDefaultPair(@"acc_filter_effect_build_in_effects_info", @[])

#endif /* CKConfigKeysDefines_h */
