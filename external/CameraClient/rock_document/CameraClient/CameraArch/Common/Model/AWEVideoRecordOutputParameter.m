//
//  AWEViewRecordOutputParameter.m
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/3/6.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWEVideoRecordOutputParameter.h"
#import <CameraClient/ACCConfigKeyDefines.h>
#import <AVFoundation/AVAssetExportSession.h>
#import <CreativeKit/ACCMacros.h>
#import <CameraClient/AWEVideoRecordOutputParameter.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <TTVideoEditor/IESMMParamModule.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <TTVideoEditor/IESMMMediaSizeUtil.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreationKitArch/ACCRepoTranscodingModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import "AWERepoContextModel.h"
#import "AWERepoVideoInfoModel.h"
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CameraClient/ACCRepoAudioModeModel.h>
#import "ACCSpeedProbeProtocol.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>

@interface AWEVideoRecordOutputParameter ()

/**
 *   enable multiple size limits
 */
@property (nonatomic, assign) BOOL enableRecordMultiSegmentVideoSize;
@property (nonatomic, assign) BOOL enableImportMultiSegmentVideoSize;

/**
 *   max write-in/bitrate size limit
 */
@property (nonatomic, strong) NSString *maximumRecordWriteSizeString;
@property (nonatomic, assign) CGSize maximumRecordWriteSize;
@property (nonatomic, strong) NSNumber *recordWriteBitrateNumber;
@property (nonatomic, assign) NSUInteger recordWriteBitrate;

@property (nonatomic, strong) NSString *maximumImportCompositionSizeString;
@property (nonatomic, assign) CGSize maximumImportCompositionSize;
@property (nonatomic, strong) NSNumber *importCompositionBitrateNumber;
@property (nonatomic, assign) NSUInteger importCompositionBitrate;

// composite resolution of multiple imported videos
@property (nonatomic, strong) NSString *assetExportPreset;

// dynamic bitrate
@property (nonatomic, strong) NSString *dynamicBitrateJsonString;
@property (nonatomic, copy) NSString *dynamicHDBitrateJsonString;

/**
 *   max preview size limit
 */
@property (nonatomic, copy) NSString *maximumImportPreviewSizeSting;
@property (nonatomic, assign) CGSize maximumImportPreviewSize;

/**
 *   max edit size limit
 */
@property (nonatomic, copy) NSString *maximumRecordEditSizeString;
@property (nonatomic, copy) NSString *maximumImportEditSizeSting;
@property (nonatomic, assign) CGSize maximumRecordEditSize;
@property (nonatomic, assign) CGSize maximumImportEditSize;

/**
 *  max export size limit
 */
@property (nonatomic, copy) NSString *maximumRecordExportSizeString;
@property (nonatomic, copy) NSString *maximumImportExportSizeString;
@property (nonatomic, assign) CGSize maximumRecordExportSize;
@property (nonatomic, assign) CGSize maximumImportExportSize;

/**
 *   max watermark size limit
 */
@property (nonatomic, copy) NSString *maximumRecordWaterMarkSizeString;
@property (nonatomic, copy) NSString *maximumImportWaterMarkSizeString;
@property (nonatomic, assign) CGSize maximumRecordWaterMarkSize;
@property (nonatomic, assign) CGSize maximumImportWaterMarkSize;

/**
 *   maximum frame rate limit for import multiple video composition /video editing preview / video export
 *
 */
@property (nonatomic, assign) NSUInteger editVideoMaximumFrameRate;
@property (nonatomic, assign) NSUInteger editVideoDefaultFrameRate;

+ (AWEVideoRecordOutputParameter *)sharedParameter;
+ (NSString *)selectVideoResolutionWithSizeArray:(NSArray<NSString *> *)sizeArray index:(NSUInteger)index;

@end

@implementation AWEVideoRecordOutputParameter

+ (AWEVideoRecordOutputParameter *)sharedParameter {
    static AWEVideoRecordOutputParameter *_sharedParameter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedParameter = [[self alloc] initWithRecordBitrateCategory:ACCConfigInt(kConfigInt_video_record_bitrate_category)
                                                       recordSizeArray:ACCConfigArray(kConfigArray_video_record_size)
                                                    recordBitrateArray:ACCConfigArray(kConfigArray_video_record_bitrate)
                                                    uploadSizeCategory:ACCConfigInt(kConfigInt_video_upload_size_category)
                                                 uploadBitrateCategory:ACCConfigInt(kConfigInt_video_upload_bitrate_category)
                                                       uploadSizeArray:ACCConfigArray(kConfigArray_upload_video_size)
                                                    uploadBitrateArray:ACCConfigArray(kConfigArray_upload_video_bitrate)
                                             editVideoMaximumFrameRate:@(ACCConfigInt(kConfigInt_edit_video_maximum_frame_rate_limited))
                                           recordEditVideoSizeCategory:ACCConfigInt(kConfigInt_record_edit_video_size_category)
                                          recordExportVideSizeCategory:ACCConfigInt(kConfigInt_record_export_video_size_category)
                                      recordWatermarkVideoSizeCategory:ACCConfigInt(kConfigInt_record_watermark_video_size_category)
                                           uploadEditVideoSizeCategory:ACCConfigInt(kConfigInt_upload_edit_video_size_category)
                                          uploadExportVideSizeCategory:ACCConfigInt(kConfigInt_upload_export_video_size_category)
                                      uploadWatermarkVideoSizeCategory:ACCConfigInt(kConfigInt_upload_watermark_video_size_category)
                                        uploadPreviewVideoSizeCategory:ACCConfigInt(kConfigInt_studio_upload_preview_video_size_category)];
    });

    return _sharedParameter;
}

- (instancetype)initWithRecordBitrateCategory:(NSUInteger)category
                              recordSizeArray:(NSArray <NSString *> *)recordSizeArray
                           recordBitrateArray:(NSArray <NSNumber *> *)recordBitrateArray
                           uploadSizeCategory:(NSUInteger)uploadSizeCategory
                        uploadBitrateCategory:(NSUInteger)uploadBitrateCategory
                              uploadSizeArray:(NSArray <NSString *> *)uploadSizeArray
                           uploadBitrateArray:(NSArray <NSNumber *> *)uploadBitrateArray
                    editVideoMaximumFrameRate:(NSNumber *)editVideoMaximumFrameRate
                  recordEditVideoSizeCategory:(NSUInteger)recordEditVideoSizeCategory
                 recordExportVideSizeCategory:(NSUInteger)recordExportVideoSizeCategory
             recordWatermarkVideoSizeCategory:(NSUInteger)recordWatermarkVideoSizeCategory
                  uploadEditVideoSizeCategory:(NSUInteger)uploadEditVideoSizeCategory
                 uploadExportVideSizeCategory:(NSUInteger)uploadExportVideoSizeCategory
             uploadWatermarkVideoSizeCategory:(NSUInteger)uploadWatermarkVideoSizeCategory
               uploadPreviewVideoSizeCategory:(NSUInteger)uploadPreviewVideoSizeCategory
{
    NSString *recordSizeString = [AWEVideoRecordOutputParameter selectVideoResolutionWithSizeArray:recordSizeArray index:category];
    NSString *recordEditVideoSizeString = [AWEVideoRecordOutputParameter selectVideoResolutionWithSizeArray:recordSizeArray index:recordEditVideoSizeCategory];
    NSString *recordExportVideSizeString = [AWEVideoRecordOutputParameter selectVideoResolutionWithSizeArray:recordSizeArray index:recordExportVideoSizeCategory];
    NSString *recordWatermarkVideoSizeString = [AWEVideoRecordOutputParameter selectVideoResolutionWithSizeArray:recordSizeArray index:recordWatermarkVideoSizeCategory];
    
    NSNumber *recordBitrate = @(2.5);
    if (recordBitrateArray.count > category) {
        recordBitrate = recordBitrateArray[category];
    }
    
    NSString *uploadSizeString = [AWEVideoRecordOutputParameter selectVideoResolutionWithSizeArray:uploadSizeArray index:uploadSizeCategory];
    NSString *uploadEditVideoSizeString = [AWEVideoRecordOutputParameter selectVideoResolutionWithSizeArray:uploadSizeArray index:uploadEditVideoSizeCategory];
    NSString *uploadExportVideSizeString = [AWEVideoRecordOutputParameter selectVideoResolutionWithSizeArray:uploadSizeArray index:uploadExportVideoSizeCategory];
    NSString *uploadWatermarkVideoSizeString = [AWEVideoRecordOutputParameter selectVideoResolutionWithSizeArray:uploadSizeArray index:uploadWatermarkVideoSizeCategory];
    NSString *uploadPreviewVideoSizeString = [AWEVideoRecordOutputParameter selectVideoResolutionWithSizeArray:uploadSizeArray index:uploadPreviewVideoSizeCategory];
    
    NSNumber *uploadBitrate = @(2.5);
    if (uploadBitrateArray.count > uploadBitrateCategory) {
        uploadBitrate = uploadBitrateArray[uploadBitrateCategory];
    }
    
    BOOL enableRecordMultiSegmentVideoSize = ACCConfigBool(kConfigBool_enable_record_multi_segment_video_size);
    BOOL enableImportMultiSegmentVideoSize = ACCConfigBool(kConfigBool_enable_import_multi_segment_video_size);
    
    NSDictionary *resolutionParameters  = @{
        @"recordSizeArray" : recordSizeArray ?: @{},
        @"recordWriteBitrateArray" : recordBitrateArray ?: @{},
        @"maximumRecordWriteSizeIndex" : @(category),
        @"enableRecordMultiSegmentVideoSize" : @(enableRecordMultiSegmentVideoSize),
        @"maximumRecordEditSizeIndex" : @(recordEditVideoSizeCategory),
        @"maximumRecordExportSizeIndex" : @(recordExportVideoSizeCategory),
        @"maximumRecordWaterMarkSizeIndex" : @(recordWatermarkVideoSizeCategory),
        @"importSizeArray" : uploadSizeArray ?: @{},
        @"maximumImportCompositionSizeIndex" : @(uploadSizeCategory),
        @"enableImportMultiSegmentVideoSize" : @(enableImportMultiSegmentVideoSize),
        @"maximumImportEditSizeIndex" : @(uploadEditVideoSizeCategory),
        @"maximumImportExportSizeIndex" : @(uploadExportVideoSizeCategory),
        @"maximumImportWaterMarkSizeIndex" : @(uploadWatermarkVideoSizeCategory),
        @"importCompositionBitrateArray" : uploadBitrateArray ?: @{},
        @"importCompositionBitrateIndex" : @(uploadBitrateCategory)
    };
    
    NSString *dynamicBitrateJsonString = ACCConfigString(kConfigString_dynamic_bitrate_json_string);
    AWELogToolInfo2(@"resolution", AWELogToolTagRecord, @"the resolution of the server configuration:%@, dynamicBitrateJsonString:%@", resolutionParameters, dynamicBitrateJsonString);
    
    return [self initWithMaximumRecordWriteSizeString:recordSizeString
                             recordWriteBitrateNumber:recordBitrate
                   maximumImportCompositionSizeString:uploadSizeString
                       importCompositionBitrateNumber:uploadBitrate
                            editVideoMaximumFrameRate:editVideoMaximumFrameRate
                          maximumRecordEditSizeString:recordEditVideoSizeString
                        maximumRecordExportSizeString:recordExportVideSizeString
                     maximumRecordWaterMarkSizeString:recordWatermarkVideoSizeString
                           maximumImportEditSizeSting:uploadEditVideoSizeString
                        maximumImportExportSizeString:uploadExportVideSizeString
                     maximumImportWaterMarkSizeString:uploadWatermarkVideoSizeString
                        maximumImportPreviewSizeSting:uploadPreviewVideoSizeString
                    enableRecordMultiSegmentVideoSize:enableRecordMultiSegmentVideoSize
                    enableImportMultiSegmentVideoSize:enableImportMultiSegmentVideoSize
                             dynamicBitrateJsonString:dynamicBitrateJsonString];
}

- (instancetype)initWithMaximumRecordWriteSizeString:(NSString *)maximumRecordWriteSizeString
                            recordWriteBitrateNumber:(NSNumber *)recordWriteBitrateNumber
                  maximumImportCompositionSizeString:(NSString *)maximumImportCompositionSizeString
                      importCompositionBitrateNumber:(NSNumber *)importCompositionBitrateNumber
                           editVideoMaximumFrameRate:(NSNumber *)editVideoMaximumFrameRate
                         maximumRecordEditSizeString:(NSString *)maximumRecordEditSizeString
                       maximumRecordExportSizeString:(NSString *)maximumRecordExportSizeString
                    maximumRecordWaterMarkSizeString:(NSString *)maximumRecordWaterMarkSizeString
                          maximumImportEditSizeSting:(NSString *)maximumImportEditSizeSting
                       maximumImportExportSizeString:(NSString *)maximumImportExportSizeString
                    maximumImportWaterMarkSizeString:(NSString *)maximumImportWaterMarkSizeString
                       maximumImportPreviewSizeSting:(NSString *)maximumImportPreviewSizeSting
                   enableRecordMultiSegmentVideoSize:(BOOL)enableRecordMultiSegmentVideoSize
                   enableImportMultiSegmentVideoSize:(BOOL)enableImportMultiSegmentVideoSize
                            dynamicBitrateJsonString:(NSString *)dynamicBitrateJsonString
{
    self = [super init];
    if (self) {
        // multi-segment resolution in recording chain
        _maximumRecordWriteSizeString = maximumRecordWriteSizeString;
        _recordWriteBitrateNumber = recordWriteBitrateNumber;
        _maximumRecordEditSizeString = maximumRecordEditSizeString;
        _maximumRecordExportSizeString = maximumRecordExportSizeString;
        _maximumRecordWaterMarkSizeString = maximumRecordWaterMarkSizeString;
        _enableRecordMultiSegmentVideoSize = enableRecordMultiSegmentVideoSize;
       
        NSDictionary *recordResolution = @{
            @"enable1080pCapturePreview" :@([AWEVideoRecordOutputParameter enable1080pCapturePreview]),
            @"maximumRecordWriteSize" : maximumRecordWriteSizeString ?: @"null",
            @"recordWriteBitrate" : recordWriteBitrateNumber,
            @"enableRecordMultiSegmentVideoSize" : @(enableRecordMultiSegmentVideoSize),
            @"maximumRecordEditSize" : maximumRecordEditSizeString ?: @"null",
            @"maximumRecordExportSize" : maximumRecordExportSizeString ?: @"null",
            @"maximumRecordWaterMarkSize" : maximumRecordWaterMarkSizeString ?: @"null"
        };
        
        // multi-segment resolution in importing chain
        _maximumImportCompositionSizeString = maximumImportCompositionSizeString;
        _importCompositionBitrateNumber = importCompositionBitrateNumber;
        _maximumImportEditSizeSting = maximumImportEditSizeSting;
        _maximumImportExportSizeString = maximumImportExportSizeString;
        _maximumImportWaterMarkSizeString = maximumImportWaterMarkSizeString;
        _maximumImportPreviewSizeSting = maximumImportPreviewSizeSting;
        _enableImportMultiSegmentVideoSize = enableImportMultiSegmentVideoSize;
        
        NSDictionary *importResolution = @{
            @"maximumImportCompositionSize" : maximumImportCompositionSizeString ?: @"null",
            @"importCompositionBitrate" : importCompositionBitrateNumber,
            @"enableImportMultiSegmentVideoSize" : @(enableImportMultiSegmentVideoSize),
            @"maximumImportEditSize" : maximumImportEditSizeSting ?: @"null",
            @"maximumImportExportSize" : maximumImportExportSizeString ?: @"null",
            @"maximumImportWaterMarkSize" : maximumImportWaterMarkSizeString ?: @"null"
        };
        
        _editVideoMaximumFrameRate = editVideoMaximumFrameRate.unsignedIntegerValue;
        _editVideoDefaultFrameRate = 30;
        _dynamicBitrateJsonString = dynamicBitrateJsonString;
        _dynamicHDBitrateJsonString = ACCConfigString(kConfigString_vesdk_dynamic_hd_bitrate_json);
        
        AWELogToolInfo2(@"resolution", AWELogToolTagRecord, @"record resolution configuration:%@, import resolution configuration:%@, edit maximum frame rate:%lu, dynamicHDBitrateJsonString:%@", recordResolution, importResolution, (unsigned long)_editVideoMaximumFrameRate,_dynamicHDBitrateJsonString);
    }
    return self;
}

- (NSString *)assetExportPreset
{
    return [self assetExportPresetWithSize:[self maximumImportCompositionSize]];
}

- (NSString *)assetExportPresetWithSize:(CGSize)size
{
    if (size.width > size.height) {
        size = CGSizeMake(size.height, size.width);
    }
    NSString *assetExportPreset = AVAssetExportPreset960x540;
    if (ACC_FLOAT_EQUAL_TO(size.width, 480))
    {
        assetExportPreset = AVAssetExportPreset640x480;
    }
    else if (ACC_FLOAT_EQUAL_TO(size.width, 540))
    {
        assetExportPreset = AVAssetExportPreset960x540;
    }
    else if (ACC_FLOAT_EQUAL_TO(size.width, 720))
    {
        assetExportPreset = AVAssetExportPreset1280x720;
    }
    else if (ACC_FLOAT_EQUAL_TO(size.width, 1080))
    {
        assetExportPreset = AVAssetExportPreset1920x1080;
    }
    else if (ACC_FLOAT_EQUAL_TO(size.width, 2160))
    {
        if (@available(iOS 9.0, *))
        {
            assetExportPreset = AVAssetExportPreset3840x2160;
        } else {
            assetExportPreset = AVAssetExportPreset960x540;
        }
    }
    else
    {
        assetExportPreset = AVAssetExportPreset640x480;
    }
    AWELogToolInfo2(@"resolution", AWELogToolTagImport, @"assetExportPreset:%@, maximumImportCompositionSize:%@", assetExportPreset, NSStringFromCGSize(size));
    return assetExportPreset;
}

#pragma mark - helper

- (CGSize)videoSizeConversionWithString:(NSString *)videoSizeString
{
    CGSize defalutSize = CGSizeMake(540, 960);
    if (!videoSizeString || videoSizeString.length == 0 || ![videoSizeString containsString:@"x"]) {
        AWELogToolInfo2(@"resolution", AWELogToolTagRecord, @"unexcept conversion video size:540x960");
        return defalutSize;
    }
    
    NSArray *array = [videoSizeString componentsSeparatedByString:@"x"];
    
    if (array.count < 2) {
        AWELogToolInfo2(@"resolution", AWELogToolTagRecord, @"unexcept conversion video size:540x960");
        return defalutSize;
    }
    
    NSInteger width = [array[0] integerValue];
    NSInteger height = [array[1] integerValue];
    
    if (width > 0 && height > 0) {
        return CGSizeMake(width, height);
    }
    AWELogToolInfo2(@"resolution", AWELogToolTagRecord, @"unexcept conversion video size:540x960");
    return defalutSize;
}
    
- (CGSize)conversionToTargetVideoSizeWith:(NSString *)targetVideoSizeString
                   defaultVideoSizeString:(NSString *)defaultVideoSizeString
              enableMultiSegmentVideoSize:(BOOL)enableMultiSegmentVideoSize
{
    CGSize conversionVideoSize;
    if (enableMultiSegmentVideoSize) {
        conversionVideoSize = [self videoSizeConversionWithString:targetVideoSizeString];
    } else {
        conversionVideoSize = [self videoSizeConversionWithString:defaultVideoSizeString];
    }
    return  conversionVideoSize;
}

+ (NSString *)selectVideoResolutionWithSizeArray:(NSArray<NSString *> *)sizeArray index:(NSUInteger)index
{
    if (sizeArray.count > index) {
        NSString *sizeString = sizeArray[index];
        if ([sizeString isKindOfClass:[NSString class]] && sizeString.length) {
            return sizeString;
        } else {
            AWELogToolInfo2(@"resolution", AWELogToolTagRecord, @"unexcept select video resolution 540x960");
            return @"540x960";
        }
    } else {
        AWELogToolInfo2(@"resolution", AWELogToolTagRecord, @"sizeArray:%@, index:%@, unexcept select video resolution 540x960", sizeArray, @(index));
        return @"540x960";
    }
}

#pragma mark - Bitrate

- (NSUInteger)recordWriteBitrate
{
    if(_recordWriteBitrate == 0) {
        if ([self.recordWriteBitrateNumber isEqualToNumber:@(0)]) {
            return 2500 * 1024;
        }
        _recordWriteBitrate = (NSUInteger)(([self.recordWriteBitrateNumber floatValue] * 1000) * 1024);
    }
    return _recordWriteBitrate;
}

- (NSUInteger)importCompositionBitrate
{
    if (_importCompositionBitrate == 0) {
        if ([self.importCompositionBitrateNumber isEqualToNumber:@(0)]) {
            return 2500 * 1024;
        }
        _importCompositionBitrate = (NSUInteger)(([self.importCompositionBitrateNumber floatValue] * 1000) * 1024);
    }
    return _importCompositionBitrate;
}

- (NSString *)dynamicBitrateJsonString
{
    if (_dynamicBitrateJsonString.length > 0) {
        return _dynamicBitrateJsonString;
    } else {
        return nil;
    }
}

#pragma mark - Frame rate

- (NSUInteger)editVideoMaximumFrameRate {
    if (_editVideoMaximumFrameRate == 0) {
        return self.editVideoDefaultFrameRate;
    }
    return _editVideoMaximumFrameRate;
}

#pragma mark - record

- (CGSize)maximumRecordWriteSize
{
    if (CGSizeEqualToSize(_maximumRecordWriteSize, CGSizeZero)) {
        _maximumRecordWriteSize = [self videoSizeConversionWithString:self.maximumRecordWriteSizeString];
    }
    return _maximumRecordWriteSize;
}

- (CGSize)maximumRecordEditSize
{
    if (CGSizeEqualToSize(_maximumRecordEditSize, CGSizeZero)) {
        _maximumRecordEditSize = [self conversionToTargetVideoSizeWith:self.maximumRecordEditSizeString
                                                defaultVideoSizeString:self.maximumRecordWriteSizeString enableMultiSegmentVideoSize:self.enableRecordMultiSegmentVideoSize];
    }
    return _maximumRecordEditSize;
}

- (CGSize)maximumRecordExportSize
{
    if (CGSizeEqualToSize(_maximumRecordExportSize, CGSizeZero)) {
        _maximumRecordExportSize = [self conversionToTargetVideoSizeWith:self.maximumRecordExportSizeString defaultVideoSizeString:self.maximumRecordWriteSizeString enableMultiSegmentVideoSize:self.enableRecordMultiSegmentVideoSize];
    }
    if ([self.class enable1080pCapturePreview] &&
        [self enableHDPublishSettingOn] &&
        ACCConfigBool(kConfigBool_enable_use_hd_export_setting)) {
        return CGSizeMake(1080, 1920);
    }
    NSDictionary* speedSetting = [AWEVideoRecordOutputParameter currentSpeedSetting];
    NSString *recordExportSizeIndex = @"studio_record_export_video_size_index";
    if (speedSetting && [speedSetting acc_objectForKey:recordExportSizeIndex]) {
        NSInteger exportIndex = [speedSetting acc_integerValueForKey:recordExportSizeIndex];
        return [self videoSizeConversionWithString:[AWEVideoRecordOutputParameter selectVideoResolutionWithSizeArray:ACCConfigArray(kConfigArray_video_record_size) index:exportIndex]];
    }
    return _maximumRecordExportSize;
}

- (CGSize)maximumRecordWaterMarkSize
{
    if (CGSizeEqualToSize(_maximumRecordWaterMarkSize, CGSizeZero)) {
        _maximumRecordWaterMarkSize = [self conversionToTargetVideoSizeWith:self.maximumRecordWaterMarkSizeString defaultVideoSizeString:self.maximumRecordWriteSizeString enableMultiSegmentVideoSize:self.enableRecordMultiSegmentVideoSize];
    }
    return _maximumRecordWaterMarkSize;
}

#pragma mark - import

- (CGSize)maximumImportCompositionSize
{
    if (CGSizeEqualToSize(_maximumImportCompositionSize, CGSizeZero)) {
        _maximumImportCompositionSize = [self videoSizeConversionWithString:self.maximumImportCompositionSizeString];
    }
    return _maximumImportCompositionSize;
 
}

- (CGSize)maximumImportEditSize
{
    if (CGSizeEqualToSize(_maximumImportEditSize, CGSizeZero)) {
        _maximumImportEditSize = [self conversionToTargetVideoSizeWith:self.maximumImportEditSizeSting defaultVideoSizeString:self.maximumImportCompositionSizeString enableMultiSegmentVideoSize:self.enableImportMultiSegmentVideoSize];
    }
    return _maximumImportEditSize;
}

- (CGSize)maximumImportExportSize
{
    if (CGSizeEqualToSize(_maximumImportExportSize, CGSizeZero)) {
        _maximumImportExportSize = [self conversionToTargetVideoSizeWith:self.maximumImportExportSizeString defaultVideoSizeString:self.maximumImportCompositionSizeString enableMultiSegmentVideoSize:self.enableImportMultiSegmentVideoSize];
    }
    if ([self enableHDPublishSettingOn]) {
        return CGSizeMake(1080, 1920);
    }
    NSDictionary* speedSetting = [AWEVideoRecordOutputParameter currentSpeedSetting];
    NSString *uploadExportSizeIndex = @"studio_upload_export_video_size_index";
    if (speedSetting && [speedSetting acc_objectForKey:uploadExportSizeIndex]) {
        NSInteger exportIndex = [speedSetting acc_integerValueForKey:uploadExportSizeIndex];
        return [self videoSizeConversionWithString:[AWEVideoRecordOutputParameter selectVideoResolutionWithSizeArray:ACCConfigArray(kConfigArray_upload_video_size) index:exportIndex]];
    }
    return _maximumImportExportSize;
}

- (CGSize)maximumImportWaterMarkSize
{
    if (CGSizeEqualToSize(_maximumImportWaterMarkSize, CGSizeZero)) {
        _maximumImportWaterMarkSize = [self conversionToTargetVideoSizeWith:self.maximumImportWaterMarkSizeString defaultVideoSizeString:self.maximumImportCompositionSizeString enableMultiSegmentVideoSize:self.enableImportMultiSegmentVideoSize];
    }
    return _maximumImportWaterMarkSize;
}

- (CGSize)maximumImportPreviewSize
{
    if (CGSizeEqualToSize(_maximumImportPreviewSize, CGSizeMake(0, 0))) {
        _maximumImportPreviewSize = [self conversionToTargetVideoSizeWith:self.maximumImportPreviewSizeSting defaultVideoSizeString:self.maximumImportCompositionSizeString enableMultiSegmentVideoSize:self.enableImportMultiSegmentVideoSize];
    }
    return _maximumImportPreviewSize;
}

#pragma mark - Public

+ (BOOL)enable1080pCapturePreview
{
    return ACCConfigBool(kConfigBool_enable_1080p_capture_preview);
}

#pragma mark - //Record

+ (CGSize)maximumRecordWriteSize
{
    return [self sharedParameter].maximumRecordWriteSize;
}

+ (CGSize)expectedMaxRecordWriteSizeForPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    NSAssert(publishModel.repoContext.videoSource == AWEVideoSourceCapture, @"only designed for capture mode");
    NSAssert(publishModel.repoTranscoding.outputWidth > 0 && publishModel.repoTranscoding.outputHeight > 0, @"record resolution should be configured before calling this method!");
    CGSize targetSize = [self targetRecordVideoSizeForPublishModel:publishModel];
    return targetSize;
}

+ (CGSize)maximumRecordEditSize
{
    return [self sharedParameter].maximumRecordEditSize;
}

+ (CGSize)maximumRecordExportSize
{
    return [self sharedParameter].maximumRecordExportSize;
}

+ (CGSize)maximumRecordWaterMarkSize
{
    return [self sharedParameter].maximumRecordWaterMarkSize;
}

+ (NSUInteger)recordWriteBitrate
{
    return [self sharedParameter].recordWriteBitrate;
}

#pragma mark - //Import

+ (CGSize)maximumImportCompositionSize
{
    return [self sharedParameter].maximumImportCompositionSize;
}

+ (CGSize)maximumImportEditSize
{
    return [self sharedParameter].maximumImportEditSize;
}

+ (CGSize)maximumImportExportSize
{
    return [self sharedParameter].maximumImportExportSize;
}

+ (CGSize)maximumImportWaterMarkSize
{
    return [self sharedParameter].maximumImportWaterMarkSize;
}

+ (CGSize)maximumImportPreviewSize
{
    return [self sharedParameter].maximumImportPreviewSize;
}

+ (NSUInteger)importCompositionBitrate
{
    return [self sharedParameter].importCompositionBitrate;
}

+ (NSString *)assetExportPreset
{
    return [self sharedParameter].assetExportPreset;
}

+ (NSString *)assetExportPresetWithSize:(CGSize)size
{
    return [[self sharedParameter] assetExportPresetWithSize:size];
}

+ (NSUInteger)editVideoMaximumFrameRate
{
    return [self sharedParameter].editVideoMaximumFrameRate;
}

+ (NSUInteger)editVideoDefaultFrameRate
{
    return [self sharedParameter].editVideoDefaultFrameRate;
}

#pragma mark - // VE transparam

+ (CGSize)currentMaxEditSize {
    return [IESMMParamModule sharedInstance].maxEditSize;
}

+ (CGSize)currentMaxExportSize
{
    return [IESMMParamModule sharedInstance].maxExportSize;
}

+ (CGSize)currentMaxWaterMarkSize
{
    return [IESMMParamModule sharedInstance].maxWaterMarkSize;
}

+ (NSString *)currentDynamicBitrateJsonStringWithVideoSource:(AWEVideoSource)videoSource
{
    NSDictionary* speedSetting = [self currentSpeedSetting];
    if (speedSetting) {
        NSString *bitrateSettings = [speedSetting acc_stringValueForKey:@"studio_vesdk_dynamic_bitrate_json"];
        if (!ACC_isEmptyString(bitrateSettings)) return bitrateSettings;
    }
    if (videoSource == AWEVideoSourceCapture) {
        if ([[self sharedParameter] enableHDPublishSettingOn] &&
            ACCConfigBool(kConfigBool_enable_use_hd_export_setting)) {
            return [self sharedParameter].dynamicHDBitrateJsonString;
        } else {
            return [self sharedParameter].dynamicBitrateJsonString;
        }
    } else {
        if ([[self sharedParameter] enableHDPublishSettingOn]) {
            return [self sharedParameter].dynamicHDBitrateJsonString;
        } else {
            return [self sharedParameter].dynamicBitrateJsonString;
        }
    }
}

+ (NSString *)normalHDBitrateSettings {
    return [self sharedParameter].dynamicHDBitrateJsonString;
}

#pragma mark - Utils
- (BOOL)enableHDPublishSettingOn {
    NSString *key = @"kAWEVideoPublishSettingsHDPublishSaveKey";
    NSString *userID = [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) currentLoginUserModel].userID;
    NSString *hdPublishSaveKey = userID.length?[NSString stringWithFormat:@"%@_%@", userID, key]:key;
    id value = [ACCCache() objectForKey:hdPublishSaveKey];
    return ACCConfigBool(kConfigBool_enable_1080p_publishing) && value ? [ACCCache() boolForKey:hdPublishSaveKey] : ACCConfigBool(kConfigBool_use_1080P_default_value);
}

// Configure the model and VE SDK limited resolution parameters
+ (void)configPublishViewModelOutputParametersWith:(AWEVideoPublishViewModel *)publishViewModel
{
    ACCRepoTranscodingModel *repoTranscoding = publishViewModel.repoTranscoding;
    // configuration bit rate
    if (repoTranscoding.bitRate == 0) {
        if (publishViewModel.repoDraft.isDraft) { // 支持动态码率的草稿，bitRate都应有值，没有值说明是不支持动态码率的老版本留下的草稿，此时应使用老版本的码率
            repoTranscoding.bitRate = 2500 * 1024;
        } else {
            if (publishViewModel.repoContext.videoSource == AWEVideoSourceAlbum) {
                repoTranscoding.bitRate = [AWEVideoRecordOutputParameter importCompositionBitrate];
            } else {
                repoTranscoding.bitRate = [AWEVideoRecordOutputParameter recordWriteBitrate];
            }
        }
    }
    
    // configuration record/uplaod output limited Size
    if (repoTranscoding.outputWidth == 0 || repoTranscoding.outputHeight == 0) {
        if (publishViewModel.repoDraft.isDraft) { // 支持动态码率的草稿，output*都应有值，没有值说明是不支持动态码率的老版本留下的草稿，此时应使用老版本的size。iPhoneX老版本因为AB存在不同size的草稿。
            repoTranscoding.outputWidth = 540;
            repoTranscoding.outputHeight = 960;
            AWELogToolInfo2(@"resolution", AWELogToolTagDraft, @"restore lost resolution fialed. transParamVideoSize:%@, videoType:%ld, videoSource:%ld.",  NSStringFromCGSize(publishViewModel.repoVideoInfo.video.transParam.videoSize), (long)publishViewModel.repoContext.videoType, (long)publishViewModel.repoContext.videoSource);
        } else {
            AWELogToolInfo2(@"resolution", AWELogToolTagDraft, @"config resolution transParamVideoSize:%@, videoType:%ld, videoSource:%ld, isDraft:%@, isBackup:%@.", NSStringFromCGSize(publishViewModel.repoVideoInfo.video.transParam.videoSize), (long) publishViewModel.repoContext.videoType, (long) publishViewModel.repoContext.videoSource, @(publishViewModel.repoDraft.isDraft), @(publishViewModel.repoDraft.isBackUp));
            if (publishViewModel.repoContext.videoSource == AWEVideoSourceAlbum) {
                // multi-segment resolution in importing chain
                repoTranscoding.outputWidth = [AWEVideoRecordOutputParameter maximumImportCompositionSize].width;
                repoTranscoding.outputHeight = [AWEVideoRecordOutputParameter maximumImportCompositionSize].height;
            } else {
                // multi-segment resolution in recording chain
            }
        }
    }
    
    if (publishViewModel.repoContext.videoSource == AWEVideoSourceAlbum) {
        [self configImportingMultiSegmentMaximumResolutionLimit];
    } else {
        [self renewRecordResolutionIfNeed:publishViewModel];
        [self configRecordingMultiSegmentMaximumResolutionLimit];
    }
    
    // config dynamic json string
    publishViewModel.repoVideoInfo.video.transParam.bitrateSetting = [self currentDynamicBitrateJsonStringWithVideoSource:publishViewModel.repoContext.videoSource];
}

+ (void)updatePublishViewModelOutputParametersWith:(AWEVideoPublishViewModel *)publishViewModel {
    ACCRepoTranscodingModel *repoTranscoding = publishViewModel.repoTranscoding;
    if (publishViewModel.repoContext.videoSource == AWEVideoSourceAlbum) {
        // bitrate
        repoTranscoding.bitRate = [AWEVideoRecordOutputParameter importCompositionBitrate];
        // resolution
        /// multi-segment resolution in importing chain
        repoTranscoding.outputWidth = [AWEVideoRecordOutputParameter maximumImportCompositionSize].width;
        repoTranscoding.outputHeight = [AWEVideoRecordOutputParameter maximumImportCompositionSize].height;
        [self configImportingMultiSegmentMaximumResolutionLimit];
    } else {
        repoTranscoding.bitRate = [AWEVideoRecordOutputParameter recordWriteBitrate];
        // multi-segment resolution in recording chain
        [self renewRecordResolutionIfNeed:publishViewModel];
        [self configRecordingMultiSegmentMaximumResolutionLimit];
    }
    // config dynamic json string
    IESMMTranscoderParam *transParam = publishViewModel.repoVideoInfo.video.transParam;
    transParam.bitrateSetting = [self currentDynamicBitrateJsonStringWithVideoSource:publishViewModel.repoContext.videoSource];
    // update video transParam
    transParam.videoSize = CGSizeMake(repoTranscoding.outputWidth, repoTranscoding.outputHeight);
    transParam.bitrate = (int)repoTranscoding.bitRate;
    
    AWELogToolInfo2(@"resolution", AWELogToolTagRecord, @"update publish settings. resolution:%@, bitrate:%zd, dynamic bitrate json:%@.",
                    NSStringFromCGSize(CGSizeMake(repoTranscoding.outputWidth, repoTranscoding.outputHeight)), repoTranscoding.bitRate, transParam.bitrateSetting);
}

+ (void)renewRecordResolutionIfNeed:(AWEVideoPublishViewModel *)publishViewModel
{
    CGSize currentSize = CGSizeMake(publishViewModel.repoTranscoding.outputWidth, publishViewModel.repoTranscoding.outputHeight);
    CGSize targetVideoSize = [self targetRecordVideoSizeForPublishModel:publishViewModel];
    if (!CGSizeEqualToSize(targetVideoSize, CGSizeZero) && !CGSizeEqualToSize(currentSize, targetVideoSize)) {
        publishViewModel.repoTranscoding.outputWidth = targetVideoSize.width;
        publishViewModel.repoTranscoding.outputHeight = targetVideoSize.height;
        AWELogToolError2(@"resolution", AWELogToolTagDraft, @"renew resolution, old:%@, new: %@, max record resolution setting: %@",
                         NSStringFromCGSize(currentSize), NSStringFromCGSize(targetVideoSize), NSStringFromCGSize([self maximumRecordWriteSize]));
    }
}

+ (CGSize)targetRecordVideoSizeForPublishModel:(AWEVideoPublishViewModel *)publishModel {
    BOOL isCapture = publishModel.repoContext.videoSource == AWEVideoSourceCapture;
    CGSize targetVideoSize = [self maximumRecordWriteSize];
    if (publishModel.repoDuet.isDuet) {
        // publishModel.outputWidth&Height represents single input size, not suitable for case like duet (multiple input)
    } else if (publishModel.repoContext.isKaraokeAudio || publishModel.repoAudioMode.isAudioMode || publishModel.repoContext.videoType == AWEVideoTypeNewYearWish) {
        targetVideoSize = ACCConfigBool(kConfigBool_enable_use_hd_export_setting) ? CGSizeMake(1080.f, 1920.f) : CGSizeMake(720.f, 1280.f);
    } else if (isCapture) {
        CGSize maxVideoSize = CGSizeZero;
        NSInteger maxResolution = -1;
        for (AVAsset *asset in publishModel.repoVideoInfo.video.videoAssets.copy) {
            AVAssetTrack *vTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
            CGSize videoSize = CGSizeApplyAffineTransform(vTrack.naturalSize, vTrack.preferredTransform);
            videoSize = CGSizeMake(fabs(videoSize.width), fabs(videoSize.height));
            if (videoSize.width <= 0 || videoSize.height <= 0) {
                continue;
            }
            NSInteger resolution = videoSize.width * videoSize.height;
            if (resolution > maxResolution) {
                maxResolution = resolution;
                maxVideoSize = videoSize;
            }
        }
        if (maxResolution > 0) {
            targetVideoSize = maxVideoSize;
        }
    }
    return targetVideoSize;
}

+ (void)configRecordingMultiSegmentMaximumResolutionLimit
{
    [IESMMParamModule sharedInstance].maxEditSize = [AWEVideoRecordOutputParameter maximumRecordEditSize];
    [IESMMParamModule sharedInstance].maxExportSize = [AWEVideoRecordOutputParameter maximumRecordExportSize];
    [IESMMParamModule sharedInstance].maxWaterMarkSize = [AWEVideoRecordOutputParameter maximumRecordWaterMarkSize];
}

+ (void)configImportingMultiSegmentMaximumResolutionLimit
{
    [IESMMParamModule sharedInstance].maxEditSize = [AWEVideoRecordOutputParameter maximumImportEditSize];
    [IESMMParamModule sharedInstance].maxExportSize = [AWEVideoRecordOutputParameter maximumImportExportSize];
    [IESMMParamModule sharedInstance].maxWaterMarkSize = [AWEVideoRecordOutputParameter maximumImportWaterMarkSize];
}

+ (void)configImportingMaximumPreviewResolutionLimit
{
    [IESMMParamModule sharedInstance].maxPreviewSize = [AWEVideoRecordOutputParameter maximumImportPreviewSize];
}

+ (BOOL)issourceSize:(CGSize)sourceSize exceedLimitWithTargetSize:(CGSize)targetSize {
    return [IESMMMediaSizeUtil issourceSize:sourceSize exceedLimitWithTargetSize:targetSize];
}

// needResize
+ (CGSize)getSizeWithSourceSize:(CGSize)sourceSize targetSize:(CGSize)targetSize {
    return [IESMMMediaSizeUtil getSizeWithSourceSize:sourceSize targetSize:targetSize];
}

+ (NSDictionary*)currentSpeedSetting {
    __block NSMutableDictionary* speedSetting = nil;
    if (!ACCConfigBool(kConfigBool_improve_video_quality_by_upload_speed)) {
        return speedSetting;
    }
    NSArray* settings = ACCConfigArray(kConfigArray_improve_video_quality_upload_speed_settings);
    if (ACCSpeedProbe().dataValid) {
        [settings enumerateObjectsUsingBlock:^(NSDictionary* obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSInteger speed = [obj acc_integerValueForKey:@"max_speed"];
            if (speed > 0 && ACCSpeedProbe().probeSpeed < speed) {
                speedSetting = [settings[idx] mutableCopy];
                [speedSetting setObject:@(idx) forKey:@"acc_speed_index"];
                *stop = YES;
            }
        }];
    } else {
        speedSetting = [[settings acc_objectAtIndex:0] mutableCopy];
        [speedSetting setObject:@(-1) forKey:@"acc_speed_index"];
    }
    return speedSetting;
}

@end
