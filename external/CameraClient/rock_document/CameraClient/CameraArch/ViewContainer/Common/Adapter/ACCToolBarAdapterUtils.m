//
//  ACCToolBarAdapterUtils.m
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/7/8.
//

#import "ACCToolBarAdapterUtils.h"
#import <CameraClient/ACCConfigKeyDefines.h>

@implementation ACCToolBarAdapterUtils

+ (BOOL)useAdaptedToolBarContainer
{
    return ACCConfigBool(kConfigBool_sidebar_text_disappear) || ACCConfigBool(kConfigBool_sidebar_record_turn_page);
}

+ (BOOL)useToolBarFoldStyle
{
    return ACCConfigBool(kConfigBool_sidebar_text_disappear);
}

+ (BOOL)useToolBarPageStyle
{
    return ACCConfigBool(kConfigBool_sidebar_record_turn_page);
}

+ (BOOL)showAllItemsPageStyle
{
    return ACCConfigBool(kConfigBool_sidebar_record_turn_page) && ACCConfigBool(kConfigBool_sidebar_edit_show_all);
}

+ (BOOL)modifyOrder
{
    return ACCConfigBool(kConfigBool_sidebar_modify_order);
}

@end
