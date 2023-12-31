//
//  ACCFilterConfigKeyDefines.h
//  CameraClient
//
//  Created by bytedance on 2021/5/20.
//

#ifndef ACCFilterConfigKeyDefines_h
#define ACCFilterConfigKeyDefines_h

//Filter panel icon type (square / circle)
#define kConfigInt_filter_icon_style \
ACCConfigKeyDefaultPair(@"studio_filter_icon_style", @(0))

#define kConfigInt_filter_box_should_show \
ACCConfigKeyDefaultPair(@"studio_filter_box_should_show", @(YES))

//Does the cold start camera remember the last filter added
#define kConfigBool_add_last_used_filter \
ACCConfigKeyDefaultPair(@"add_last_used_filter", @(YES))

//Whether to insert "normal" filter when sliding switch
#define kConfigBool_insert_normal_filter \
ACCConfigKeyDefaultPair(@"acc_insert_normal_filter", @(NO))

//"normal" filter name displayed
#define kConfigString_insert_normal_filter_name_display \
ACCConfigKeyDefaultPair(@"acc_insert_normal_filter_name_display", @"")

//Does the filter vibrate slightly after application
#define kConfigBool_apply_filter_enable_taptic \
ACCConfigKeyDefaultPair(@"acc_apply_filter_enable_taptic", @(NO))

#endif /* ACCFilterConfigKeyDefines_h */
