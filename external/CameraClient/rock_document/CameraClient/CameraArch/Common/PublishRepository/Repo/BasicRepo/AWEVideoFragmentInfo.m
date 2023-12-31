//
//  AWEVideoFragmentInfo.m
//  CameraClient
//
//  Created by haoyipeng on 2020/10/14.
//

#import "AWEVideoFragmentInfo.h"
#import "AWEVideoFragmentInfo_private.h"
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/NSArray+ACCAdditions.h>

@implementation AWEVideoPublishChallengeInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"challengeId" : @"challengeId",
        @"challengeName" : @"challengeName",
    };
}

- (id)copyWithZone:(NSZone *)zone
{
    AWEVideoPublishChallengeInfo *copy = [[AWEVideoPublishChallengeInfo alloc] init];
    copy.challengeName = self.challengeName;
    copy.challengeId = self.challengeId;
    return copy;
}

@end


@implementation ACCEffectTrackParams

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"needTrackInEdit" : @"needTrackInEdit",
        @"needTrackInPublish" : @"needTrackInPublish",
        @"params" : @"params"
    };
}

@end

@implementation AWEPictureToVideoInfo

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"propID" : @"propID",
        @"stickerTextArray" : @"stickerTextArray",
        @"arTextArray" : @"arTextArray",
        @"challengeInfos" : @"challengeInfos",
        @"editPageButtonStyle" : @"editPageButtonStyle",
        @"hasFlowerActivitySticker" : @"hasFlowerActivitySticker",
        @"hasSmartScanSticker" : @"hasSmartScanSticker"
    };
}

+ (NSValueTransformer *)challengeInfosJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:AWEVideoPublishChallengeInfo.class];
}

@end

@implementation ACCSecurityFrameInsetsModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"top":@"top",
        @"left":@"left",
        @"bottom":@"bottom",
        @"right":@"right",
    };
}

- (instancetype)initWithInsets:(UIEdgeInsets)insets
{
    self = [super init];
    if (self) {
        self.top = insets.top;
        self.bottom = insets.bottom;
        self.left = insets.left;
        self.right = insets.right;
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    ACCSecurityFrameInsetsModel *copy = [[ACCSecurityFrameInsetsModel alloc] init];
    copy.top = self.top;
    copy.bottom = self.bottom;
    copy.left = self.left;
    copy.right = self.right;
    
    return copy;
}

@end

@interface AWEVideoFragmentInfo ()

@end

@implementation AWEVideoFragmentInfo

@synthesize background = _background;

@synthesize beautify = _beautify;

@synthesize beautifyUsed = _beautifyUsed;

@synthesize cameraPosition = _cameraPosition;

@synthesize colorFilterId = _colorFilterId;

@synthesize colorFilterName = _colorFilterName;

@synthesize composerBeautifyEffectInfo = _composerBeautifyEffectInfo;

@synthesize composerBeautifyInfo = _composerBeautifyInfo;

@synthesize composerBeautifyUsed = _composerBeautifyUsed;

@synthesize musicEffect = _musicEffect;

@synthesize propBindMusicIdArray = _propBindMusicIdArray;

@synthesize propRecId = _propRecId;

@synthesize speed = _speed;

@synthesize stickerGradeKey = _stickerGradeKey;

@synthesize stickerId = _stickerId;

@synthesize useStabilization = _useStabilization;

@synthesize watermark = _watermark;

@synthesize stickerSavePhotoInfo = _stickerSavePhotoInfo;

@synthesize arTextArray = _arTextArray;

@synthesize backgroundID = _backgroundID;

@synthesize delayRecordModeType = _delayRecordModeType;

@synthesize eye = _eye;

@synthesize frameCount = _frameCount;

@synthesize isReshoot = _isReshoot;

@synthesize originalFrames = _originalFrames;

@synthesize originalFramesArray = _originalFramesArray;

@synthesize propIndexPath = _propIndexPath;

@synthesize propSelectedFrom = _propSelectedFrom;

@synthesize backgroundType = _backgroundType;

@synthesize clipRange = _clipRange;

@synthesize recordMode = _recordMode;

@synthesize recordDuration = _recordDuration;

@synthesize pic2VideoSource = _pic2VideoSource;

@synthesize stickerVideoAssetURL = _stickerVideoAssetURL;

@synthesize stickerTextArray = _stickerTextArray;

@synthesize stickerBGPlayedPercent = _stickerBGPlayedPercent;

@synthesize smooth = _smooth;

@synthesize shape = _shape;

@synthesize reshape = _reshape;

@synthesize figureAppearanceDurationInMS = _figureAppearanceDurationInMS;

- (instancetype)initWithSourceType:(AWEVideoFragmentSourceType)sourceType
{
    self = [super init];
    if (self) {
        _speed = 1.0;
        _shape = - 1.0;
        _stickerBGPlayedPercent = 0;
        _activityTimerange = [@[] mutableCopy];
        _originalFramesArray = [@[] mutableCopy];
        _challengeInfos = @[];
        
        _sourceType = sourceType;
    }
    
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error
{
    self = [super initWithDictionary:dictionaryValue error:error];
    if (self) {
        [self setupChallengeWithDictionary:dictionaryValue];
    }
    return self;
}

- (void)setupChallengeWithDictionary:(NSDictionary *)dictionaryValue {
    if (self.challengeID && self.challengeName) {
        // challengeName、challengeID 向下兼容
        NSString *challengeID = self.challengeID;
        NSString *challengeName = self.challengeName;
        if (challengeID.length > 0 && challengeName.length > 0) {
            AWEVideoPublishChallengeInfo *challengeInfo = [[AWEVideoPublishChallengeInfo alloc] init];
            challengeInfo.challengeId = challengeID;
            challengeInfo.challengeName = challengeName;
            
            NSMutableArray *challengeInfos = [self.challengeInfos mutableCopy];
            if (challengeInfos.count) {
                bool hasSameId = NO;
                for (AWEVideoPublishChallengeInfo *challenge in challengeInfos) {
                    if ([challenge.challengeId isEqualToString:challengeID]) {
                        hasSameId = YES;
                        break;
                    }
                }
                if (!hasSameId) {
                    [challengeInfos addObject:challengeInfo];
                }
                self.challengeInfos = [challengeInfos copy];
            } else {
                self.challengeInfos = @[challengeInfo];
            }
        }
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _speed = 1.0;
        _shape = - 1.0;
        _stickerBGPlayedPercent = 0;
        _activityTimerange = [@[] mutableCopy];
        _originalFramesArray = [@[] mutableCopy];
        _challengeInfos = @[];
    }
    return self;
}

- (NSString *)stickerId
{
    if (!_stickerId) {
        _stickerId = @"";
    }
    return _stickerId;
}

- (NSString *)stickerName
{
    if (!_stickerName) {
        _stickerName = @"";
    }
    return _stickerName;
}

- (NSString *)colorFilterId
{
    if (!_colorFilterId) {
        _colorFilterId = @"";
    }
    return _colorFilterId;
}

- (NSString *)recordMode
{
    if (!_recordMode) {
        _recordMode = @"";
    }
    return _recordMode;
}

- (NSString *)background
{
    if (!_background) {
        _background = @"";
    }
    return _background;
}

- (NSString *)challengeID
{
    if (!_challengeID) {
        _challengeID = @"";
    }
    return _challengeID;
}

- (NSString *)musicEffect
{
    if (!_musicEffect) {
        _musicEffect = @"";
    }
    return _musicEffect;
}

- (AWEVideoStickerSavePhotoInfo *)stickerSavePhotoInfo
{
    if (!_stickerSavePhotoInfo) {
        _stickerSavePhotoInfo = [AWEVideoStickerSavePhotoInfo new];
    }
    return _stickerSavePhotoInfo;
}

- (AVAsset *)avAsset
{
    if (!_avAsset && _avAssetURL) {
        _avAsset = [AVURLAsset assetWithURL:_avAssetURL];
    }
    
    return _avAsset;
}

- (UIEdgeInsets)frameInset
{
    if (_frameInsetsModel) {
        _frameInset = UIEdgeInsetsMake(_frameInsetsModel.top, _frameInsetsModel.left, _frameInsetsModel.bottom, _frameInsetsModel.right);
    }
    
    return _frameInset;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{@"cameraPosition":@"cameraPosition",
             @"beautify":@"beautify",
             @"beautifyUsed":@"beautifyUsed",
             @"composerBeautifyUsed":@"composerBeautifyUsed",
             @"composerBeautifyInfo":@"composerBeautifyInfo",
             @"composerBeautifyEffectInfo":@"composerBeautifyEffectInfo",
             @"stickerId":@"stickerId",
             @"stickerName":@"stickerName",
             @"appliedUseOutputProp":@"appliedUseOutputProp",
             @"stickerSavePhotoInfo":@"stickerSavePhotoInfo",
             @"stickerGradeKey":@"stickerGradeKey",
             @"selectedLiveDuetImageIndex":@"selectedLiveDuetImageIndex",
             @"propBindMusicIdArray":@"propBindMusicIdArray",
             @"colorFilterId":@"colorFilterId",
             @"colorFilterName":@"colorFilterName",
             @"hasDeselectionBeenMadeRecently" : @"hasDeselectionBeenMadeRecently",
             @"recordMode":@"recordMode",
             @"background":@"background",
             @"speed":@"speed",
             @"musicEffect":@"musicEffect",
             @"useStabilization" : @"useStabilization",
             @"watermark" : @"watermark",
             @"challengeID" : @"challengeID",
             @"challengeName" : @"challengeName",
             @"challengeInfos" : @"challengeInfos",
             @"isCommerce" : @"isCommerce",
             @"smooth" : @"smooth",
             @"reshape" : @"reshape",
             @"shape" : @"shape",
             @"eye" : @"eye",
             @"frameCount" : @"frameCount",
             @"recordDuration" : @"recordDuration",
             @"activityTimerange" : @"activity_timerange",
             @"activityType" : @"activityType",
             @"stickerPoiId" : @"stickerPoiId",
             @"needSelectedStickerPoi" : @"needSelectedStickerPoi",
             @"mappedShortPoiId" : @"mappedShortPoiId",
             @"arTextArray" : @"arTextArray",
             @"stickerTextArray" : @"stickerTextArray",
             @"welfareActivityID" : @"welfareActivityID",
             @"originalFramesArray" : @"originalFramesArray",
             @"delayRecordModeType" : @"delayRecordModeType",
             @"pic2VideoSource" : @"pic2VideoSource",
             @"backgroundID" : @"backgroundID",
             @"backgroundType" : @"backgroundType",
             @"clipRange": @"clipRange",
             @"stickerVideoAssetURL" : @"stickerVideoAssetURL",
             @"stickerBGPlayedPercent" : @"stickerBGPlayedPercent",
             @"propSelectedFrom" : @"propSelectedFrom",
             @"uploadStickerUsed" : @"uploadStickerUsed",
             @"effectTrackParams" : @"effectTrackParams",
             @"hasRedpacketSticker" : @"hasRedpacketSticker",
             @"hasFlowerActivitySticker" : @"hasFlowerActivitySticker",
             @"hasSmartScanSticker" : @"hasSmartScanSticker",
             @"sourceType":@"sourceType",
             @"avAssetURL":@"avAssetURL",
             @"imageAssetURL":@"imageAssetURL",
             @"clipTimeRange":@"clipTimeRange",
             @"frameInsetsModel":@"frameInsetsModel",
             @"stickerImageAssetPaths":@"stickerImageAssetPaths",
             @"assetOrientation":@"assetOrientation",
             @"figureAppearanceDurationInMS": @"figureAppearanceDurationInMS",
             @"stickerMatchId": @"stickerMatchId",
             @"isSupportExtractFrame" : @"isSupportExtractFrame",
             @"hasAutoApplyHotProp" : @"hasAutoApplyHotProp"
             };
}

+ (NSValueTransformer *)activityTimerangeJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:AWETimeRange.class];
}

+ (NSValueTransformer *)clipRangeJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:AWETimeRange.class];
}

+ (NSValueTransformer *)stickerSavePhotoInfoJsonTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:AWEVideoStickerSavePhotoInfo.class];
}

+ (NSValueTransformer *)challengeInfosJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:AWEVideoPublishChallengeInfo.class];
}

+ (NSValueTransformer *)effectTrackParamsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:ACCEffectTrackParams.class];
}

+ (NSValueTransformer *)frameInsetsModelJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:ACCSecurityFrameInsetsModel.class];
}

+ (NSValueTransformer *)clipTimeRangeJSONTransformer
{
    return [MTLValueTransformer transformerUsingForwardBlock:^id(NSDictionary *cmTimeRangeDic, BOOL *success, NSError *__autoreleasing *error) {
        NSInteger start = [cmTimeRangeDic[@"start"] integerValue];
        NSInteger duration = [cmTimeRangeDic[@"duration"] integerValue];
        CMTime startTime = CMTimeMake(start * 1000, 1000000);
        CMTime durationTime = CMTimeMake(duration * 1000, 1000000);
        return [NSValue valueWithCMTimeRange:CMTimeRangeMake(startTime, durationTime)];
    } reverseBlock:^id(NSValue *cmTimeRangeValue, BOOL *success, NSError *__autoreleasing *error) {
        CMTimeRange range = cmTimeRangeValue.CMTimeRangeValue;
        NSInteger start = CMTimeGetSeconds(range.start) * 1000;
        NSInteger duration = CMTimeGetSeconds(range.duration) * 1000;
        
        return @{
            @"start" : @(start),
            @"duration" : @(duration)
        };
    }];
}

- (void)deleteStickerSavePhotos:(NSString *)taskId
{
    if (self.stickerSavePhotoInfo.photoNames.count > 0) {
        [self.stickerSavePhotoInfo.photoNames enumerateObjectsUsingBlock:^(NSString * _Nonnull imageName, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *filePath  = [AWEDraftUtils generateStickerPhotoFilePathFromTaskId:taskId name:imageName];
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            if (error) {
                AWELogToolError(AWELogToolTagNone, @"%s %@", __PRETTY_FUNCTION__, error);
            }
        }];
    }
}

- (id)copyWithZone:(NSZone *)zone
{
    AWEVideoFragmentInfo *fragmentInfo = [[AWEVideoFragmentInfo alloc] init];
    fragmentInfo.cameraPosition = self.cameraPosition;
    fragmentInfo.beautify = self.beautify;
    fragmentInfo.beautifyUsed = self.beautifyUsed;
    fragmentInfo.composerBeautifyUsed = self.composerBeautifyUsed;
    fragmentInfo.composerBeautifyInfo = self.composerBeautifyInfo;
    fragmentInfo.composerBeautifyEffectInfo = self.composerBeautifyEffectInfo;
    fragmentInfo.colorFilterId = self.colorFilterId;
    fragmentInfo.colorFilterName = self.colorFilterName;
    fragmentInfo.recordMode = self.recordMode;
    fragmentInfo.hasDeselectionBeenMadeRecently = self.hasDeselectionBeenMadeRecently;
    fragmentInfo.background = self.background;
    fragmentInfo.stickerId = self.stickerId;
    fragmentInfo.stickerName = self.stickerName;
    fragmentInfo.appliedUseOutputProp = self.appliedUseOutputProp;
    fragmentInfo.stickerSavePhotoInfo = self.stickerSavePhotoInfo;
    fragmentInfo.selectedLiveDuetImageIndex = self.selectedLiveDuetImageIndex;
    fragmentInfo.propRecId = self.propRecId;
    fragmentInfo.stickerGradeKey = self.stickerGradeKey;
    fragmentInfo.propBindMusicIdArray = [self.propBindMusicIdArray copy];
    fragmentInfo.speed = self.speed;
    fragmentInfo.musicEffect = self.musicEffect;
    fragmentInfo.useStabilization = self.useStabilization;
    fragmentInfo.watermark = self.watermark;
    fragmentInfo.isReshoot = self.isReshoot;
    fragmentInfo.challengeInfos = [[NSArray alloc] initWithArray:self.challengeInfos copyItems:YES] ;
    fragmentInfo.isCommerce = self.isCommerce;
    fragmentInfo.smooth = self.smooth;
    fragmentInfo.reshape = self.reshape;
    fragmentInfo.shape = self.shape;
    fragmentInfo.eye = self.eye;
    fragmentInfo.frameCount = self.frameCount;
    fragmentInfo.recordDuration = self.recordDuration;
    fragmentInfo.propIndexPath = self.propIndexPath;
    fragmentInfo.propSelectedFrom = self.propSelectedFrom;
    fragmentInfo.stickerPoiId = self.stickerPoiId;
    fragmentInfo.needSelectedStickerPoi = self.needSelectedStickerPoi;
    fragmentInfo.mappedShortPoiId = self.mappedShortPoiId;
    fragmentInfo.arTextArray = self.arTextArray;
    fragmentInfo.stickerTextArray = self.stickerTextArray;
    fragmentInfo.welfareActivityID = self.welfareActivityID;
    fragmentInfo.editPageButtonStyle = self.editPageButtonStyle;
    fragmentInfo.needAddHashTagForStory = self.needAddHashTagForStory;
    fragmentInfo.originalFramesArray = self.originalFramesArray;
    fragmentInfo.stickerVideoAssetURL = self.stickerVideoAssetURL;
    fragmentInfo.stickerBGPlayedPercent = self.stickerBGPlayedPercent;
    fragmentInfo.hasAutoApplyHotProp = self.hasAutoApplyHotProp;

    fragmentInfo.activityTimerange = [[NSArray alloc] initWithArray:self.activityTimerange copyItems:YES];
    fragmentInfo.activityType = self.activityType;

    fragmentInfo.backgroundID = self.backgroundID;
    fragmentInfo.backgroundType = self.backgroundType;

    fragmentInfo.delayRecordModeType = self.delayRecordModeType;
    fragmentInfo.pic2VideoSource = self.pic2VideoSource;
    fragmentInfo.clipRange = self.clipRange;
    fragmentInfo.uploadStickerUsed = self.uploadStickerUsed;

    fragmentInfo.effectTrackParams = self.effectTrackParams;
    fragmentInfo.hasRedpacketSticker = self.hasRedpacketSticker;
    fragmentInfo.hasFlowerActivitySticker = self.hasFlowerActivitySticker;
    fragmentInfo.hasSmartScanSticker = self.hasSmartScanSticker;
    
    fragmentInfo.reshootTaskId = self.reshootTaskId;
    
    // Security
    fragmentInfo.sourceType = self.sourceType;
    fragmentInfo.avAsset = self.avAsset;
    fragmentInfo.avAssetURL = [self.avAssetURL copy];
    fragmentInfo.imageAsset = self.imageAsset;
    fragmentInfo.imageAssetURL = [self.imageAssetURL copy];
    fragmentInfo.clipTimeRange = [self.clipTimeRange copy];
    fragmentInfo.frameInset = self.frameInset;
    fragmentInfo.frameInsetsModel = [self.frameInsetsModel copy];
    fragmentInfo.assetOrientation = self.assetOrientation;
    fragmentInfo.stickerImageAssetPaths = self.stickerImageAssetPaths;

    fragmentInfo.stickerMatchId = self.stickerMatchId;
    fragmentInfo.isSupportExtractFrame = self.isSupportExtractFrame;
    
    return fragmentInfo;
}

- (void)convertToRelativePathWithTaskID:(NSString *)taskID
{
    self.stickerVideoAssetURL = [self p_convertToRelativePath:self.stickerVideoAssetURL withTaskID:taskID];
    self.avAssetURL = [self p_convertToRelativePath:self.avAssetURL withTaskID:taskID];
    self.imageAssetURL = [self p_convertToRelativePath:self.imageAssetURL withTaskID:taskID];
    self.stickerImageAssetPaths = [self.stickerImageAssetPaths acc_mapObjectsUsingBlock:^NSString * _Nonnull(NSString *  _Nonnull path, NSUInteger idex) {
        return [AWEDraftUtils relativePathFrom:path taskID:taskID];
    }];
    self.originalFramesArray = [self.originalFramesArray acc_mapObjectsUsingBlock:^NSString * _Nonnull(NSString * _Nonnull path, NSUInteger idex) {
        return [AWEDraftUtils relativePathFrom:path taskID:taskID];
    }];
}

- (void)convertToAbsolutePathWithTaskID:(NSString *)taskID
{
    self.stickerVideoAssetURL = [self p_convertToAbsolutePath:self.stickerVideoAssetURL withTaskID:taskID];
    self.avAssetURL = [self p_convertToAbsolutePath:self.avAssetURL withTaskID:taskID];
    self.imageAssetURL = [self p_convertToAbsolutePath:self.imageAssetURL withTaskID:taskID];
    self.stickerImageAssetPaths = [self.stickerImageAssetPaths acc_mapObjectsUsingBlock:^NSString * _Nonnull(NSString *  _Nonnull path, NSUInteger idex) {
        return [AWEDraftUtils absolutePathFrom:path taskID:taskID];
    }];
}

- (NSURL *)p_convertToRelativePath:(NSURL *)url withTaskID:(NSString *)taskID
{
    NSURL *targetURL = url;
    
    if (targetURL != nil) {
        // solve the inventory problem
        NSString *flagPath = [AWEDraftDirectoryFlag stringByAppendingPathComponent:taskID];
        if (![targetURL.path containsString:flagPath]
            && [[NSFileManager defaultManager] fileExistsAtPath:targetURL.path]) {
            NSString *newTargetPath = [[AWEDraftUtils generateDraftFolderFromTaskId:taskID] stringByAppendingPathComponent:targetURL.lastPathComponent];
            NSURL *newTargetURL = [NSURL fileURLWithPath:newTargetPath];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:newTargetURL.path]) {
                [[NSFileManager defaultManager] removeItemAtPath:newTargetURL.path error:nil];
            }
            NSError *error = nil;
            BOOL rst = [[NSFileManager defaultManager] copyItemAtURL:[NSURL fileURLWithPath:targetURL.path] toURL:newTargetURL error:&error];
            if (rst) {
                targetURL = newTargetURL;
            }
        }
        
        targetURL = [AWEDraftUtils draftFileURLFrom:targetURL.path taskID:taskID];
    }
    
    return targetURL;
}

- (NSURL *)p_convertToAbsolutePath:(NSURL *)url withTaskID:(NSString *)taskID
{
    // url本身是relative path
    NSString *absolutePath = [AWEDraftUtils absolutePathFrom:url.path taskID:taskID];
    if ([[NSFileManager defaultManager] fileExistsAtPath:absolutePath]) {
        return [AWEDraftUtils draftFileURLFrom:absolutePath taskID:taskID];
    }
    
    NSURL *targetURL = url;
    targetURL = [AWEDraftUtils draftFileURLFrom:targetURL.path taskID:taskID];

    if (targetURL != nil) {
        NSString *flagPath = [AWEDraftDirectoryFlag stringByAppendingPathComponent:taskID];
        if ([targetURL.path containsString:flagPath]) {
            targetURL = [NSURL fileURLWithPath:[AWEDraftUtils absolutePathFrom:targetURL.path taskID:taskID]];
        } else {
            // solve the inventory problem
            if ([[NSFileManager defaultManager] fileExistsAtPath:targetURL.path]) {
                NSString *newTargetPath = [[AWEDraftUtils generateDraftFolderFromTaskId:taskID] stringByAppendingPathComponent:targetURL.lastPathComponent];
                NSURL *newTargetURL = [NSURL fileURLWithPath:newTargetPath];
                
                if ([[NSFileManager defaultManager] fileExistsAtPath:newTargetURL.path]) {
                    [[NSFileManager defaultManager] removeItemAtPath:newTargetURL.path error:nil];
                }
                NSError *error = nil;
                BOOL rst = [[NSFileManager defaultManager] copyItemAtURL:[NSURL fileURLWithPath:targetURL.path] toURL:newTargetURL error:&error];
                if (rst) {
                    targetURL = newTargetURL;
                }
            }
        }
        
        targetURL = [AWEDraftUtils draftFileURLFrom:targetURL.path taskID:taskID];
    }
    
    return targetURL;
}

+ (nullable NSString *)effectTrackStringWithFragmentInfos:(NSArray<AWEVideoFragmentInfo *> *)fragmentInfos
                                                   filter:(BOOL(^)(ACCEffectTrackParams *param))filter
{
    __block NSString *formatString = @"";
    [fragmentInfos enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull fragmentInfo, NSUInteger fragmentInfoIdx, BOOL * _Nonnull stop) {
        [fragmentInfo.effectTrackParams enumerateObjectsUsingBlock:^(ACCEffectTrackParams * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            BOOL shouldAdd = YES;
            if (filter) {
                shouldAdd = filter(obj);
            }
            if (shouldAdd) {
                [obj.params enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * _Nonnull stop) {
                    NSAssert(![value isKindOfClass:NSDictionary.class] && ![value isKindOfClass:NSArray.class], @"value class(%@) is invalid", [value class]);
                    formatString = [formatString stringByAppendingFormat:@"%@:%@,", key, value];
                }];
            }
        }];
        
        NSRange range = [formatString rangeOfString:@"," options:NSBackwardsSearch];
        if (range.location != NSNotFound) {
            formatString = [formatString stringByReplacingCharactersInRange:range withString:@""];
        }
        
        if (fragmentInfoIdx < fragmentInfos.count - 1) {
            formatString = [formatString stringByAppendingString:@";"];
        }
    }];
    
    NSString *checkString = [formatString stringByReplacingOccurrencesOfString:@";" withString:@""];
    if (checkString.length == 0) {
        formatString = nil;
    }
    
    return formatString;
}

- (void)setOriginalFramesArray:(NSArray<NSString *> *)originalFramesArray
{
    _originalFramesArray = originalFramesArray;
}

@end
