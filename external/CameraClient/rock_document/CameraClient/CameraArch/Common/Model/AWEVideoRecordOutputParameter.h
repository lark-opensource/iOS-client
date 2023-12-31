//
//  AWEViewRecordOutputParameter.h
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/3/6.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CreationKitArch/AWEVideoPublishViewModelDefine.h>

@class AWEVideoPublishViewModel;

@interface AWEVideoRecordOutputParameter : NSObject
 
/**
 *  max write-in/bitrate size limit
 */
+ (BOOL)enable1080pCapturePreview;

/// !! Use +[self expectedMaxRecordWriteSizeForPublishModel:] instead of this method to determine record resolution for camera
+ (CGSize)maximumRecordWriteSize;
+ (NSUInteger)recordWriteBitrate;

/// record mutiple resolution not supported
/// @param publishModel publishModel
+ (CGSize)expectedMaxRecordWriteSizeForPublishModel:(AWEVideoPublishViewModel *)publishModel;

+ (CGSize)maximumImportCompositionSize;
+ (NSUInteger)importCompositionBitrate;
// composite resolution of multiple imported videos
+ (NSString *)assetExportPreset;
+ (NSString *)assetExportPresetWithSize:(CGSize)size;
+ (NSString *)currentDynamicBitrateJsonStringWithVideoSource:(AWEVideoSource)videoSource;
+ (nullable NSString *)normalHDBitrateSettings;
+ (nullable NSDictionary *)currentSpeedSetting;

/**
*   max preview size limit
*/
+ (CGSize)maximumImportPreviewSize;

/**
*   max edit size limit
*/
+ (CGSize)maximumRecordEditSize;
+ (CGSize)maximumImportEditSize;
+ (CGSize)currentMaxEditSize;

/**
*  max export size limit
*/
+ (CGSize)maximumRecordExportSize;
+ (CGSize)maximumImportExportSize;
+ (CGSize)currentMaxExportSize;

/**
*   max watermark size limit
*/
+ (CGSize)maximumRecordWaterMarkSize;
+ (CGSize)maximumImportWaterMarkSize;
+ (CGSize)currentMaxWaterMarkSize;

/**
*   maximum frame rate limit for import multiple video composition /video editing preview / video export
*
*/
+ (NSUInteger)editVideoMaximumFrameRate;
+ (NSUInteger)editVideoDefaultFrameRate;

#pragma mark - Configure

// Configure the model and VE SDK limited resolution parameters
+ (void)configPublishViewModelOutputParametersWith:(AWEVideoPublishViewModel *)publishViewModel;
// Update the model and SDK limited params using current settings
+ (void)updatePublishViewModelOutputParametersWith:(AWEVideoPublishViewModel *)publishViewModel;

// Configure multi-segment sdk resolution limits
+ (void)configRecordingMultiSegmentMaximumResolutionLimit;
+ (void)configImportingMultiSegmentMaximumResolutionLimit;
+ (void)configImportingMaximumPreviewResolutionLimit;

// Resize
+ (BOOL)issourceSize:(CGSize)sourceSize exceedLimitWithTargetSize:(CGSize)targetSize;
+ (CGSize)getSizeWithSourceSize:(CGSize)sourceSize targetSize:(CGSize)targetSize;

@end
