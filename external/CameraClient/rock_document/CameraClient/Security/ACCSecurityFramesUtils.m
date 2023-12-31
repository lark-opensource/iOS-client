//
//  ACCSecurityFramesUtils.m
//  AWEStudioService-Pods-Aweme
//
//  Created by lixingdong on 2021/4/13.
//

#import "ACCSecurityFramesUtils.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCMonitorToolProtocol.h>
#import <CameraClient/ACCConfigKeyDefines.h>

NSString * const ACCSecurityFramesErrorDomain = @"com.aweme.security";

@implementation ACCSecurityExportModel

@end

@implementation ACCSecurityFramesUtils

+ (NSError *)errorWithErrorCode:(NSInteger)errorCode
{
    NSString *message = [self errorMessageWithErrorCode:errorCode] ?: @"";
    return [NSError errorWithDomain:ACCSecurityFramesErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey : message}];
}

+ (NSString *)errorMessageWithErrorCode:(NSInteger)errorCode
{
    NSString *message = @"";
    switch (errorCode) {
        case ACCSecurityFramesErrorEmptySecurityFrames:
            message = @"抽帧为空";
            break;
            
        case ACCSecurityFramesErrorEmptyFragmentInfo:
            message = @"抽帧fragmentInfo为空";
            break;
            
        case ACCSecurityFramesErrorInvalidAVASSetURL:
            message = @"AVASSetURL对应文件不存在";
            break;
        
        case ACCSecurityFramesErrorInvalidAVASSet:
            message = @"AVASSet异常";
            break;
            
        case ACCSecurityFramesErrorInvalidImageAssetURL:
            message = @"ImageAssetURL对应文件不存在";
            break;
            
        case ACCSecurityFramesErrorInvalidImageAsset:
            message = @"ImageAsset异常，抽帧失败";
            break;
            
        case ACCSecurityFramesErrorInvalidFragment:
            message = @"fragmentInfo异常，抽帧失败";
            break;
            
        default:
            break;
    }
    
    return message;
}

+ (void)showACCMonitorAlertWithErrorCode:(NSInteger)errorCode
{
    acc_dispatch_main_async_safe(^{
        NSString *message = [self errorMessageWithErrorCode:errorCode] ?: @"";
        [ACCMonitorTool() showWithTitle:message
                                  error:nil
                                  extra:@{@"tag": @"frames"}
                                  owner:@"raomengyun"
                                options:ACCMonitorToolOptionModelAlert|ACCMonitorToolOptionReportToQiaoFu];
    });
}

+ (NSTimeInterval)recordFramesInterval
{
    NSTimeInterval interval = (NSTimeInterval)ACCConfigDouble(kConfigDouble_studio_record_media_frame_interval);
    if (ACC_FLOAT_EQUAL_ZERO(interval)) {
        interval = 2.0;
    }
    return interval;
}

+ (NSTimeInterval)uploadFramesInterval
{
    NSTimeInterval interval = (NSTimeInterval)ACCConfigDouble(kConfigDouble_studio_upload_media_frame_interval);
    if (ACC_FLOAT_EQUAL_ZERO(interval)) {
        interval = 0.5;
    }
    return interval;
}

+ (CGSize)framesResolution
{
    NSInteger width = (NSInteger)ACCConfigInt(kConfigInt_studio_media_frame_resolution);
    if (width == 0) {
        width = 360;
    }
    
    NSInteger height = 16.0 / 9.0 * width;
    
    return CGSizeMake(width, height);
}

+ (CGSize)framesResolutionWithType:(ACCSecurityFrameType)type {
    NSInteger width = (NSInteger)ACCConfigInt(kConfigInt_studio_media_frame_resolution);
    if (width == 0) {
        width = 360;
    }
    
    if (type == ACCSecurityFrameTypeAIRecommond) {
        // 针对智能配乐和groot物种识别提升抽帧分辨率
        if (width < 432) {
            width = 432; // 抽帧目标分辨率提升至 (432x768)
        }
    }
    
    NSInteger height = 16.0 / 9.0 * width;
    
    return CGSizeMake(width, height);
}

+ (CGSize)highHramesResolution
{
    NSInteger width = (NSInteger)ACCConfigInt(kConfigInt_studio_high_frame_resolution);
    if (width == 0) {
        width = 540;
    }
    
    NSInteger height = 16.0 / 9.0 * width;
    
    return CGSizeMake(width, height);
}

+ (CGFloat)framesCompressionRatio
{
    NSTimeInterval ratio = (NSTimeInterval)ACCConfigDouble(kConfigDouble_studio_media_frame_compression_ratio);
    if (ACC_FLOAT_EQUAL_ZERO(ratio)) {
        ratio = 0.6;
    }
    return ratio;
}

@end
