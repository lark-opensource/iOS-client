//
//  MVPBaseServiceContainer+MVP.m
//  MVP
//
//  Created by liyingpeng on 2020/12/30.
//

#import "MVPBaseServiceContainer+MVP.h"
#import "MODResourceBundle.h"
#import "MODFontImpl.h"
#import "ACCVideoConfig.h"
#import "MODSettingsImpl.h"
#import "MODACCNetServiceImpl.h"
#import "MODModuleConfig.h"
#import "AWEACCWebImageImpl.h"
#import "MVPACCDraftImpl.h"
#import "LVDAlertService.h"
#import "MODStudioServiceImpl.h"
#import "MODUserServiceImpl.h"
#import "MODCommerceServiceImpl.h"
#import "MODModelFactoryServiceImpl.h"
#import "MODFriendsServiceImpl.h"
#import "MODStudioLiteRedPacket.h"
#import "MODBeautyComponentConfig.h"
#import <CameraClient/ACCAlertDefaultImpl.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreativeKit/ACCConfigProtocol.h>
#import <CreativeKit/ACCConfigImpl.h>
#import <CameraClient/ACCSmartMovieManagerProtocol.h>
#import <CameraClient/ACCCreativePathManager.h>
#import <CreationKitBeauty/ACCBeautyDefine.h>
#import <CreationKitInfra/ACCRecordFilterDefines.h>
#import <CreationKitBeauty/CKBConfigKeyDefines.h>
#import "LarkVideoDirector/LarkVideoDirector-Swift.h"

@implementation MVPBaseServiceContainer (MVP)

// ABTest

IESProvidesSingleton(ACCConfigGetterProtocol)
{
    ACCConfigImpl *config = [[ACCConfigImpl alloc] init];
    [config setString:[LVDCameraI18N getLocalizedStringWithKey:@"com_mig_beauty" defaultStr:NULL] forKey:kConfigString_beauty_button_title.firstObject];
    [config setBoolValue:YES forKey:ACCConfigBool_enable_front_torch.firstObject];
    [config setBoolValue:YES forKey:kConfigBool_enable_1080p_capture_preview.firstObject];
    [config setBoolValue:YES forKey:kConfigBool_enable_1080p_publishing.firstObject];
    [config setBoolValue:YES forKey:kConfigBool_enable_use_hd_export_setting.firstObject];
    [config setArray:@[@"1920x1080"] forKey:kConfigArray_video_record_size.firstObject];
    [config setBoolValue:YES forKey:kConfigBool_enable_record_3min_optimize.firstObject];
    [config setBoolValue:YES forKey:kConfigBool_enable_lightning_style_record_button.firstObject];
    [config setBoolValue:YES forKey:kConfigBool_enable_exposure_compensation.firstObject];
    [config setBoolValue:YES forKey:kConfigBool_studio_enable_record_beauty_switch.firstObject];
    [config setIntValue:AWEBeautyCellIconStyleSquare forKey:kConfigInt_beauty_effect_icon_style.firstObject];
    [config setIntValue:AWEFilterCellIconStyleSquare forKey:kConfigInt_filter_icon_style.firstObject];
    [config setBoolValue:NO forKey:kConfigInt_filter_box_should_show.firstObject];
    [config setBoolValue:YES forKey:ACCConfigBOOL_enable_continuous_flash_and_torch.firstObject];
    [config setBoolValue:NO forKey:kConfigBool_is_torch_perform_immediately.firstObject];
    [config setDoubleValue:0.1 forKey:kConfigDouble_torch_record_wait_duration.firstObject];
    [config setIntValue:ACCViewFrameOptimizeFullDisplay forKey:kConfigInt_view_frame_optimize_type.firstObject];
    [config setBoolValue:NO forKey:kConfigBool_add_last_used_filter.firstObject];
    [config setBoolValue:YES forKey:ACCConfigBool_enable_torch_auto_mode.firstObject];
    [config setBoolValue:NO forKey:kConfigBool_beauty_category_switch_default_value.firstObject];
    return config;
}

IESProvidesSingleton(ACCResourceBundleProtocol)
{
    return [[MODResourceBundle alloc] init];
}

IESProvidesSingleton(ACCFontProtocol)
{
    return [[MODFontImpl alloc] init];
}

// Extension

IESProvidesSingleton(ACCVideoConfigProtocol)
{
    return [[ACCVideoConfig alloc] init];
}

IESProvidesSingleton(ACCModuleConfigProtocol)
{
    return [[MODModuleConfig alloc] init];
}

IESProvidesSingleton(ACCStudioServiceProtocol)
{
    return [[MODStudioServiceImpl alloc] init];
}

IESProvidesSingleton(ACCUserServiceProtocol)
{
    return [[MODUserServiceImpl alloc] init];
}

IESProvidesSingleton(ACCCommerceServiceProtocol)
{
    return [[MODCommerceServiceImpl alloc] init];
}

IESProvidesSingleton(ACCModelFactoryServiceProtocol)
{
    return [[MODModelFactoryServiceImpl alloc] init];
}

IESProvidesSingleton(ACCFriendsServiceProtocol)
{
    return [[MODFriendsServiceImpl alloc] init];
}

IESProvidesSingleton(ACCCreativePathManagable)
{
    return [ACCCreativePathManager manager];
}

// UICommon

IESProvides(ACCAlertProtocol)
{
    return [[LVDAlertService alloc] init];
}

IESProvides(ACCWebImageProtocol)
{
    return [[AWEACCWebImageImpl alloc] init];
}

// Infra

IESProvidesSingleton(ACCSettingsProtocol)
{
     return [[MODSettingsImpl alloc] init];
}

IESProvides(ACCNetServiceProtocol)
{
    return [[MODACCNetServiceImpl alloc] init];
}

IESProvidesSingleton(ACCDraftProtocol)
{
    return [[MVPACCDraftImpl alloc] init];
}

IESProvides(ACCStudioLiteRedPacket)
{
    return [[MODStudioLiteRedPacket alloc] init];
}

// Recorder
IESProvidesSingleton(ACCBeautyComponentConfigProtocol)
{
    return [[MODBeautyComponentConfig alloc] init];
}

OBJC_EXTERN id<ACCSmartMovieManagerProtocol> acc_sharedSmartMovieManager() {
    return nil;
}

@end
