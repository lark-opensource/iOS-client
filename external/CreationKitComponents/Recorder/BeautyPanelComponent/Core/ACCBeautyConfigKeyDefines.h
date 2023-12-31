//
//  ACCBeautyConfigKeyDefines.h
//  CameraClient-Pods-Aweme
//
//  Created by machao on 2021/5/24.
//

#ifndef ACCBeautyConfigKeyDefines_h
#define ACCBeautyConfigKeyDefines_h
#import <CreationKitInfra/ACCConfigManager.h>
#import <CreationKitArch/CKConfigKeysDefines.h>

typedef NS_OPTIONS(NSInteger, ACCRecordFirstFrameOptType) {
    ACCRecordFirstFrameOptTypeNone = 0,
    ACCRecordFirstFrameOptTypeLaunch = 1,
    ACCRecordFirstFrameOptTypeMainLoopBlock = 2,
    ACCRecordFirstFrameOptTypeAll = ACCRecordFirstFrameOptTypeLaunch | ACCRecordFirstFrameOptTypeMainLoopBlock
};

#define kConfigBool_studio_record_open_optimize \
ACCConfigKeyDefaultPair(@"studio_record_open_optimize",  @(NO))

#define kConfigBool_mvp_beauty_icon \
ACCConfigKeyDefaultPair(@"mvpBeautyIcon",  @(NO))

#define kConfigBool_muse_beauty_panel \
ACCConfigKeyDefaultPair(@"MuseBeautyPanel",  @(NO))

#define kConfigInt_beauty_effect_composer_group \
ACCConfigKeyDefaultPair(@"beautyEffectComposerGroup",  @(0))

#define kConfigBool_enable_advanced_composer \
ACCConfigKeyDefaultPair(@"enableAdvancedComposer",  @(YES))

#define kConfigInt_beauty_button_title_strategy \
ACCConfigKeyDefaultPair(@"beautyButtonTitleStrategy", @(0))

#define kConfigString_beauty_button_title \
ACCConfigKeyDefaultPair(@"acc_beauty_button_title", @"Beautify")

#define kConfigDouble_identification_as_male_threshold \
ACCConfigKeyDefaultPair(@"male_prob_threshold", @(0.8))

#define kConfigBool_show_title_in_video_camera \
ACCConfigKeyDefaultPair(@"show_title_in_video_camera", @(YES))

#define kConfigBool_default_beauty_on \
ACCConfigKeyDefaultPair(@"defaultBeautyOn", @(YES))

#define kConfigBool_studio_enable_record_beauty_switch \
ACCConfigKeyDefaultPair(@"studio_enable_record_beauty_switch", @(NO))

#define kConfigInt_beauty_effect_icon_style \
ACCConfigKeyDefaultPair(@"studio_beauty_icon_style", @(0))

#define kConfigInt_studio_enable_record_first_frame_opt \
ACCConfigKeyDefaultPair(@"studio_enable_record_first_frame_opt", @(0))

#define kConfigBool_studio_record_beauty_icon_show_yellow_dot \
ACCConfigKeyDefaultPair(@"record_beauty_icon_show_yellow_dot", @(NO))

// beauty primary panel
#define kConfigBool_studio_record_beauty_primary_panel_enable \
ACCConfigKeyDefaultPair(@"record_beauty_primary_panel_enable", @(NO))

#endif /* ACCBeautyConfigKeyDefines_h */
