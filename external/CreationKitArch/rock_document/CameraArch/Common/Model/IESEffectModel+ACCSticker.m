//

#import "IESEffectModel+ACCSticker.h"

#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <CreationKitArch/AWEStickerMusicManager.h>
#import <objc/runtime.h>
#import <CreationKitInfra/NSDictionary+ACCAddBaseApiPropertyKey.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>

NSString * const AWEEffectTagDisableReshape = @"disable_reshape";
NSString * const AWEEffectTagDisableSmooth = @"disable_smooth";
NSString * const AWEEffectTagDisableBeautifyFilter = @"disable_beautify_filter";
NSString * const AWEEffectTagDisableTanning = @"disable_contour";
NSString * const AWEEffectTagNewYear = @"new_year";
NSString * const AWEEffectTagRecognition = @"recognition";
NSString * const AWEEffectTagMute = @"mute";
NSString * const AWEEffectTagTransferTouch = @"transfer_touch";
NSString * const AWEEffectTagStrongBeat = @"strong_beat";
NSString * const AWEEffectTagIsWeather = @"weather";
NSString * const AWEEffectTagIsTime = @"time";
NSString * const AWEEffectTagIsDate = @"date";
NSString * const AWEEffectTagIsLocked = @"lock";
NSString * const AWEEffectTagIsInstrument = @"instrument";
NSString * const AWEEffectTagCameraFront = @"camera_front";
NSString * const AWEEffectTagCameraZoom = @"zoomin";
NSString * const AWEEffectTagCameraBack = @"camera_back";
NSString * const AWEEffectTagDairy = @"dairy";
NSString * const AWEEffectTagVoiceRecognization = @"voice_recognization";
NSString * const AWEEffectTagValantineStarTag = @"wvalantine_star_tag"; // White Valentine's Day Star sticker
NSString * const AWEEffectTag2DText = @"text2d";
NSString * const AWEEffectTagCanUseAmazingEngine = @"bCanAmazing510"; // Is it possible to use a new rendering engine? After vesdk510, it will be changed from "bcanuseamapping" to "bcanamazing510"
NSString * const AWEEffectTagIsMusicLyric = @"LyricsSticker";
NSString * const AWEEffectTagIsMagnifier = @"MagnifierSticker";
NSString * const AWEEffectTagMultiScanBgVideo = @"MultiScanBgVideo";
NSString * const AWEEffectTypeKeepWhenEditing = @"KeepWhenEditing";
NSString * const AWEEffectTypeAdaptive = @"Adaptive";
NSString * const AWEEffectTypeFaceReplace3D = @"FaceReplace3D";
NSString * const AWEDuetLayoutTypeGreenScreen = @"green_screen";

static NSString *const ACCEffectTypeDaily = @"daily";
static NSString *const ACCEffectTypeAnimatedDateSticker = @"date_sticker_by_chen";

@implementation ACCStickerMultiSegPropClipModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"xPoints" : @"xPoints",
        @"yPoints" : @"yPoints",
        @"duration" : @"duration",
    };
}

@end

@interface IESEffectModel ()

@property (nonatomic, strong) IESMMEffectStickerInfo *innerEffectStickerInfo;

@end

@implementation IESEffectModel (ACCSticker)

- (void)setDownloadStatus:(AWEEffectDownloadStatus)downloadStatus
{
    objc_setAssociatedObject(self, @selector(downloadStatus), @(downloadStatus), OBJC_ASSOCIATION_ASSIGN);
}

- (NSString *)commerceWebURL
{
    return [[self.extra acc_jsonValueDecoded] acc_stringValueForKey:@"commerce_sticker_web_url"];
}

- (NSString *)commerceOpenURL
{
    return [[self.extra acc_jsonValueDecoded] acc_stringValueForKey:@"commerce_sticker_open_url"];
}

- (NSString *)commerceBuyText
{
    return [[self.extra acc_jsonValueDecoded] acc_stringValueForKey:@"commerce_sticker_buy_text"];
}

- (AWECommerceStickerType)commerceStickerType
{
    return [[self.extra acc_jsonValueDecoded] acc_integerValueForKey:@"commerce_sticker_type"];
}

- (void)setExtraDictionary:(NSDictionary *)extraDictionary
{
    objc_setAssociatedObject(self, @selector(extraDictionary), extraDictionary, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSDictionary *)extraDictionary
{
    return objc_getAssociatedObject(self, _cmd);
}

- (AWEEffectDownloadStatus)downloadStatus
{
    return (AWEEffectDownloadStatus)[objc_getAssociatedObject(self, @selector(downloadStatus)) integerValue];
}

- (NSString *)propSelectedFrom
{
    return objc_getAssociatedObject(self, @selector(propSelectedFrom));
}

- (void)setPropSelectedFrom:(NSString *)propSelectedFrom
{
    objc_setAssociatedObject(self, @selector(propSelectedFrom), propSelectedFrom, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)localUnCompressPath
{
    return objc_getAssociatedObject(self, @selector(localUnCompressPath));
}

- (void)setLocalUnCompressPath:(NSString *)localUnCompressPath
{
    objc_setAssociatedObject(self, @selector(localUnCompressPath), localUnCompressPath, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)localVoiceEffectTag
{
    return objc_getAssociatedObject(self, @selector(localVoiceEffectTag));
}

- (void)setLocalVoiceEffectTag:(NSString *)localVoiceEffectTag
{
    objc_setAssociatedObject(self, @selector(localVoiceEffectTag), localVoiceEffectTag, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSDictionary *)recordTrackInfos {
    return objc_getAssociatedObject(self, @selector(recordTrackInfos));
}

- (void)setRecordTrackInfos:(NSDictionary *)recordTrackInfos
{
    objc_setAssociatedObject(self, @selector(recordTrackInfos), recordTrackInfos, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (ACCPropSelectionSource)selectionSource
{
    return (ACCPropSelectionSource)[objc_getAssociatedObject(self, @selector(downloadStatus)) integerValue];
}

- (void)setSelectionSource:(ACCPropSelectionSource)selectionSource
{
    objc_setAssociatedObject(self, @selector(selectionSource), @(selectionSource), OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)useRemoveBg
{
    return [objc_getAssociatedObject(self, @selector(useRemoveBg)) boolValue];
}

- (void)setUseRemoveBg:(BOOL)useRemoveBg
{
    objc_setAssociatedObject(self, @selector(useRemoveBg), @(useRemoveBg), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)customStickerFilePath {
    return objc_getAssociatedObject(self, @selector(customStickerFilePath));
}

- (void)setCustomStickerFilePath:(NSString *)customStickerFilePath
{
    objc_setAssociatedObject(self, @selector(customStickerFilePath), customStickerFilePath, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSArray *)uploadFramePaths
{
    return objc_getAssociatedObject(self, @selector(uploadFramePaths));
}

- (void)setUploadFramePaths:(NSArray *)uploadFramePaths
{
    objc_setAssociatedObject(self, @selector(uploadFramePaths), uploadFramePaths, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSInteger)guideVideoThresholdCount
{
    NSDictionary *extraJson = [self acc_analyzeSDKExtra];
    return [extraJson acc_intValueForKey:@"guide_video_threshold_count"];
}

- (BOOL)infoStickerBlockStory {
    if (self.extra.length > 0) {
        NSData *extraData = [self.extra dataUsingEncoding:NSUTF8StringEncoding];
        if (extraData.length > 0) {
            NSError *error = nil;
            id jsonObject = [NSJSONSerialization JSONObjectWithData:extraData options:0 error:&error];
            if (error != nil) {
                AWELogToolError2(@"sticker", AWELogToolTagRecord, @"sticker extra serialization failed: %@", error);
            }
            if ([jsonObject isKindOfClass:[NSDictionary class]]) {
                return [(NSDictionary *)jsonObject acc_boolValueForKey:@"info_sticker_block_story"];
            }
        }
    }
    
    return NO;
}

#pragma mark - analyze extra and SDKExtra common

- (NSDictionary *)acc_analyzeExtra
{
    if (!ACC_isEmptyString(self.extra)) {
        NSData *extraData = [self.extra dataUsingEncoding:NSUTF8StringEncoding];
        if (extraData.length > 0) {
            NSError *error = nil;
            id JSONObject = [NSJSONSerialization JSONObjectWithData:extraData options:0 error:&error];
            if (error != nil) {
                AWELogToolError2(@"prop", AWELogToolTagRecord, @"prop extra serialization failed: %@", error);
                return nil;
            }
            if ([JSONObject isKindOfClass:[NSDictionary class]]) {
                return (NSDictionary *)JSONObject;
            }
        }
    }
    return nil;
}

- (NSDictionary *)acc_analyzeSDKExtra
{
    if (!ACC_isEmptyString(self.sdkExtra)) {
        NSData *extraData = [self.sdkExtra dataUsingEncoding:NSUTF8StringEncoding];
        if (extraData.length > 0) {
            NSError *error = nil;
            id JSONObject = [NSJSONSerialization JSONObjectWithData:extraData options:0 error:&error];
            if (error != nil) {
                AWELogToolError2(@"prop", AWELogToolTagRecord, @"prop sdkextra serialization failed: %@", error);
                return nil;
            }
            if ([JSONObject isKindOfClass:[NSDictionary class]]) {
                return (NSDictionary *)JSONObject;
            }
        }
    }
    return nil;
}

#pragma mark - analyze type methods

- (BOOL)isTypeAR
{
    return [self.types containsObject:IESEffectTypeAR];
}

- (BOOL)isTypeARMatting
{
    return [self.types containsObject:IESEffectTypeAR] && [self.types containsObject:IESEffectTypeARPhotoFace];
}

- (BOOL)isTypeARKit
{
    return [self.types containsObject:IESEffectTypeARKit];
}

- (BOOL)isTypeParticleJoint
{
    return [self.types containsObject:IESEffectTypeParticleJoint];
}

- (BOOL)isTypeTouchGes
{
    return [self.types containsObject:IESEffectTypeTouchGes];
}

- (BOOL)isTypeStabilizationOff
{
    return [self.types containsObject:IESEffectTypeStabilizationOff];
}

- (BOOL)needKeepWhenEditing
{
    return [self.types containsObject:AWEEffectTypeKeepWhenEditing];
}

- (BOOL)hasMakeupFeature
{
    return [self.types containsObject:IESEffectTypeMakeup];
}

- (BOOL)isTypeAdaptive
{
    return [self.types containsObject:AWEEffectTypeAdaptive];
}

- (BOOL)isTypeFaceReplace3D
{
    return [self.types containsObject:AWEEffectTypeFaceReplace3D];
}

#pragma mark - analyze type methods

- (BOOL)isTypeNewYear
{
    return [self.tags containsObject:AWEEffectTagNewYear];
}

- (BOOL)isTypeRecognition
{
    return [self.tags containsObject:AWEEffectTagRecognition];
}

- (BOOL)isTypeMute
{
    return [self.tags containsObject:AWEEffectTagMute];
}

- (BOOL)isTypeTimeInfo
{
    BOOL isTimeInfo = NO;
    for (NSString *str in self.tags) {
        if ([str hasPrefix:@"time"]) {
            isTimeInfo = YES;
            break;
        }
    }
    return isTimeInfo;
}

- (BOOL)isTypeMusicLyric
{
    return [self.tags containsObject:AWEEffectTagIsMusicLyric];
}

- (BOOL)isTypeMagnifier
{
    return [self.tags containsObject:AWEEffectTagIsMagnifier];
}

- (BOOL)isTypeMultiScanBgVideo
{
    return [self.tags containsObject:AWEEffectTagMultiScanBgVideo];
}

- (BOOL)isDaily
{
    return [self.tags containsObject:ACCEffectTypeDaily];
}

- (BOOL)isAnimatedDateSticker
{
    return [self.tags containsObject:ACCEffectTypeAnimatedDateSticker];
}

- (BOOL)isUploadSticker
{
    return [self.tags acc_match:^BOOL(NSString * _Nonnull item) {
        return [item.lowercaseString isEqualToString:@"uploadimagesticker"];
    }] != nil;
}

- (BOOL)isDuetGreenScreen
{
    NSDictionary *extra = [self acc_analyzeExtra];
    NSData *jsonData = [[extra objectForKey:@"duet_layout_mode"] dataUsingEncoding:NSUTF8StringEncoding];
    if (jsonData) {
        NSError *error = nil;
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
        if (error) {
            AWELogToolError(AWELogToolTagNone, @"%s %@", __PRETTY_FUNCTION__, error);
            return NO;
        }

        NSString *effectName = ACCDynamicCast([dictionary objectForKey:@"name"], NSString);
        return [effectName isEqualToString:AWEDuetLayoutTypeGreenScreen];
    }
    return NO;
}

- (double)effectTimeLength
{
    double length = 0.0;
    for (NSString *str in self.tags) {
        if ([str hasPrefix:@"time"]) {
            NSRange range = [str rangeOfString:@":"];
            if ([str containsString:@":"] && range.location != NSNotFound) {
                NSUInteger totalCount = str.length;
                NSRange validTimeRange = NSMakeRange(range.location + range.length, totalCount - range.location - range.length);
                NSString *subString = [str substringWithRange:validTimeRange];
                length = [subString doubleValue];
            }
        }
    }
    return length;
}

- (ACCGameType)gameType
{
    if (self.isEffectControlGame) {
        return ACCGameTypeEffectControlGame;
    }
    return ACCGameTypeNone;
}

- (NSString *)welfareActivityID
{
    NSDictionary *extraInfo = [self acc_analyzeExtra];
    return [extraInfo acc_stringValueForKey:@"welfare_activity_id"];
}

- (NSString *)challengeID
{
    for (NSString *tag in self.tags) {
        NSString *challengePrefixString = @"challenge:";
        NSString *trimedTag = [tag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([trimedTag hasPrefix:challengePrefixString]) {
            NSUInteger startIndex = [challengePrefixString length];
            return [[tag substringFromIndex:startIndex] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }
    }
    return nil;
}

- (NSArray *)gestureRedPacketHandActionArray
{
    NSDictionary *handActionDict = [self handActionDict];
    NSMutableArray *retArray = [@[] mutableCopy];
    NSString *prefixString = @"gesture_redpacket:";
    
    for (NSString *tag in self.tags) {
        // gesture_redpacket:1:heart_b
        NSString *trimedTag = [tag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([trimedTag hasPrefix:prefixString]) {
            NSArray *componentArray = [trimedTag componentsSeparatedByString:@":"];
            if (componentArray.lastObject) {
                NSString *handAction = [componentArray.lastObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if (handActionDict[handAction]) {
                    [retArray addObject:handActionDict[handAction]];
                }
            }
        }
    }
    return retArray;
}

- (NSArray<NSString *> *)dynamicIconURLs
{
    // todo: huanglixuan will remove this logic later after server gives a new param called "url_prefix"
    NSDictionary *extraInfo = [self acc_analyzeExtra];
    NSString *dynamicURLs = [extraInfo acc_stringValueForKey:@"dynamic_icon"];

    __block NSMutableArray<NSString *> *dynamicIconURLArray = [NSMutableArray array];

    if (!ACC_isEmptyString(dynamicURLs)) {
        __block NSMutableArray<NSString *> *urlPrefixArray = [NSMutableArray array];
        [self.iconDownloadURLs enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSRange range = [obj rangeOfString:@"/" options:NSBackwardsSearch];
            NSUInteger index = range.location;
            NSString *removedSubstring = [obj substringFromIndex:index];
            [urlPrefixArray acc_addObject:[obj stringByReplacingOccurrencesOfString:removedSubstring withString:@""]];
        }];

        [urlPrefixArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *completeURL = [NSString stringWithFormat:@"%@/%@", obj, dynamicURLs];
            [dynamicIconURLArray acc_addObject:completeURL];
        }];
    }

    return [dynamicIconURLArray copy];
}

- (NSDictionary *)handActionDict
{
    return @{
             @"heart_a"         :@(IESMMHandsActionHeartA),
             @"heart_b"         :@(IESMMHandsActionHeartB),
             @"heart_c"         :@(IESMMHandsActionHeartC),
             @"heart_d"         :@(IESMMHandsActionHeartD),
             @"ok"              :@(IESMMHandsActionOK),
             @"hand_open"       :@(IESMMHandsActionHandOpen),
             @"thumb_up"        :@(IESMMHandsActionThumbUp),
             @"thumb_down"      :@(IESMMHandsActionThumbDown),
             @"rock"            :@(IESMMHandsActionRock),
             @"namaste"         :@(IESMMHandsActionNamaste),
             @"palm_up"         :@(IESMMHandsActionPlamUp),
             @"fist"            :@(IESMMHandsActionFist),
             @"index_finger_up" :@(IESMMHandsActionIndexFingerUp),
             @"double_finger_up":@(IESMMHandsActionDoubleFingerUp),
             @"victory"         :@(IESMMHandsActionVictory),
             @"big_v"           :@(IESMMHandsActionBigV),
             @"phonecall"       :@(IESMMHandsActionPhoneCall),
             @"beg"             :@(IESMMHandsActionBeg),
             @"thanks"          :@(IESMMHandsActionThanks),
             };
}

- (NSInteger)gestureRedPacketActivityType
{
    NSString *prefixString = @"gesture_redpacket:";
    for (NSString *tag in self.tags) {
        NSString *trimedTag = [tag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([trimedTag hasPrefix:prefixString]) {
            NSArray *componentArray = [trimedTag componentsSeparatedByString:@":"];
            if (componentArray.count == 3) {
                NSString *typeStr = componentArray[1];
                return typeStr.integerValue;
            }
        }
    }
    return 0;
}

- (BOOL)isPreviewable
{
    __block BOOL previewable = YES;
    [self.tags enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj hasPrefix:@"lock"]) {
            NSArray *lockedTags = [obj componentsSeparatedByString:@":"];
            previewable = lockedTags.count >= 2 ? [[lockedTags objectAtIndex:1] boolValue] : YES;
            *stop = YES;
        }
    }];
    return previewable;
}

- (BOOL)isLocked
{
    __block BOOL locked = NO;
    [self.tags enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj hasPrefix:@"lock"]) {
            locked = YES;
            *stop = YES;
        }
    }];
    return locked;
}

- (NSString *)activityId
{
    __block NSString *lockedInfo = @"";
    [self.tags enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj hasPrefix:@"lock"]) {
            lockedInfo = obj;
            *stop = YES;
        }
    }];
    NSArray *lockedInfoArray = [lockedInfo componentsSeparatedByString:@":"];
    NSString *activityID = lockedInfoArray.count == 3 ? lockedInfoArray.lastObject : @"";
    return activityID;
}

- (BOOL)isTypeVoiceRecognization
{
    return [self.tags containsObject:AWEEffectTagVoiceRecognization] || [self audioGraphMicSource];
}

- (BOOL)isTypeWeather
{
    return [self.tags containsObject:AWEEffectTagIsWeather];
}

- (BOOL)isTypeTime
{
    return [self.tags containsObject:AWEEffectTagIsTime];
}

- (BOOL)isTypeDate
{
    return [self.tags containsObject:AWEEffectTagIsDate];
}

- (BOOL)isTypeDairy
{
    return [self.tags containsObject:AWEEffectTagDairy];
}

- (BOOL)disableReshape
{
    return [self.tags containsObject:AWEEffectTagDisableReshape];
}

- (BOOL)disableSmooth
{
    return [self.tags containsObject:AWEEffectTagDisableSmooth];
}

- (BOOL)disableBeautifyFilter
{
    return [self.tags containsObject:AWEEffectTagDisableBeautifyFilter];
}

- (BOOL)isStrongBeatSticker
{
    return [self.tags containsObject:AWEEffectTagStrongBeat];
}

- (BOOL)isTypeValantineStarSticker
{
    return [self.tags containsObject:AWEEffectTagValantineStarTag];
}

- (BOOL)isTypeInstrument
{
    return [self.tags containsObject:AWEEffectTagIsInstrument] || [self.types containsObject:AWEEffectTagIsInstrument];
}

- (BOOL)needTransferTouch
{
    return [self.tags containsObject:AWEEffectTagTransferTouch];
}

- (BOOL)isTypeCameraFront
{
    return [self.tags containsObject:AWEEffectTagCameraFront];
}

- (BOOL)isTypeCameraZoom
{
    return [self.tags containsObject:AWEEffectTagCameraZoom];
}

- (BOOL)isTypeCameraBack
{
    return [self.tags containsObject:AWEEffectTagCameraBack];
}

- (BOOL)isType2DText
{
    return [self.tags containsObject:AWEEffectTag2DText];
}

- (BOOL)canUseAmazingEngine
{
    return [self.tags containsObject:AWEEffectTagCanUseAmazingEngine];
}

#pragma mark - analyze extra methods

- (BOOL)isTypePhotoSensitive
{
    NSDictionary *extraInfo = [self acc_analyzeExtra];
    if (extraInfo) {
        return  [extraInfo acc_boolValueForKey:@"photosensitive"];
    }
    return NO;
}

- (BOOL)isTypeMusicBeat
{
    NSDictionary *extraInfo = [self acc_analyzeExtra];
    BOOL isMusicBeat = [extraInfo acc_boolValueForKey:@"is_music_beat"] || self.audioGraphMusicSource;
    return isMusicBeat;
}

- (BOOL)isMultiSegProp
{
    NSDictionary *multiSegDict = [[self acc_analyzeSDKExtra] acc_dictionaryValueForKey:@"multi_segments"];
    NSArray *clipDict = [multiSegDict acc_arrayValueForKey:@"clips"];
    return !ACC_isEmptyArray(clipDict);
}

- (NSArray<ACCStickerMultiSegPropClipModel *> *)clipsArray
{
    NSArray *clips = objc_getAssociatedObject(self, _cmd);
    if (clips) {
        return clips;
    }
    
    NSDictionary *multiSegDict = [[self acc_analyzeSDKExtra] acc_dictionaryValueForKey:@"multi_segments"];
    NSArray *clipDict = [multiSegDict acc_arrayValueForKey:@"clips"];
    if (ACC_isEmptyArray(clipDict)) {
        return nil;
    }
    
    NSError *error = nil;
    NSArray <ACCStickerMultiSegPropClipModel *>* cilpArray = [MTLJSONAdapter modelsOfClass:ACCStickerMultiSegPropClipModel.class fromJSONArray:clipDict error:&error];
    __block CGFloat currentDuration = 0;
    [cilpArray enumerateObjectsUsingBlock:^(ACCStickerMultiSegPropClipModel * _Nonnull clip, NSUInteger idx, BOOL * _Nonnull stop) {
        clip.start = currentDuration;
        currentDuration = currentDuration + clip.duration;
        clip.end = currentDuration;
    }];
    [cilpArray sortedArrayUsingComparator:^NSComparisonResult(ACCStickerMultiSegPropClipModel * _Nonnull obj1, ACCStickerMultiSegPropClipModel * _Nonnull obj2) {
        return obj1.start < obj2.start;
    }];
    
    if (error == nil) {
        objc_setAssociatedObject(self, @selector(clipsArray), cilpArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return cilpArray;
}

- (BOOL)hasCommerceEnter
{
    return (!ACC_isEmptyString(self.commerceWebURL) || !ACC_isEmptyString(self.commerceOpenURL)) && !ACC_isEmptyString(self.commerceBuyText) && self.commerceStickerType == AWECommerceStickerTypeCommon;
}

- (void)setInnerEffectStickerInfo:(IESMMEffectStickerInfo *)innerEffectStickerInfo
{
    objc_setAssociatedObject(self, @selector(innerEffectStickerInfo), innerEffectStickerInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (IESMMEffectStickerInfo *)innerEffectStickerInfo
{
    return objc_getAssociatedObject(self, _cmd);
}

- (IESMMEffectStickerInfo *)effectStickerInfo
{
    if (!self.innerEffectStickerInfo) {
        self.innerEffectStickerInfo = [[IESMMEffectStickerInfo alloc] init];
        self.innerEffectStickerInfo.path = self.resourcePath;
        self.innerEffectStickerInfo.stickerID = [self.effectIdentifier intValue];
        // Can use making "no need" by @ Zhao Mingwei
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wdeprecated-declarations"
//        self.innerEffectStickerInfo.canUseAmazing = [self canUseAmazingEngine];
//#pragma clang diagnostic pop
        
        self.innerEffectStickerInfo.stickerTag = self.extra;
        VERecorderBackendMode backendMode = VERecorderBackendMode_None;
        if ([self audioGraphMusicSource]) {
            backendMode |= VERecorderBackendMode_Bgm;
        }
        if ([self audioGraphMicSource]) {
            backendMode |= VERecorderBackendMode_Mic;
        }
        self.innerEffectStickerInfo.backnedMode = backendMode;
        self.innerEffectStickerInfo.backendUseOutput = [self audioGraphUseOutput];
    }
    return self.innerEffectStickerInfo;
}

@end

@implementation IESEffectModel (EffectControlGame)

- (BOOL)isEffectControlGame
{
    NSDictionary *sdkExtra = [self acc_analyzeSDKExtra];
    if (sdkExtra) {
        NSString *type = [sdkExtra acc_stringValueForKey:@"type"];
        return [type isEqualToString:@"effectControlGame"];
    }
    return NO;
}

@end

#pragma mark - Pixaloop

@implementation IESEffectModel (Pixaloop)

- (NSDictionary *)pixaloopExtra
{
    return [self acc_analyzeExtra];
}

- (NSDictionary *)pixaloopSDKExtra
{
    return [self acc_analyzeSDKExtra];
}

- (BOOL)isPixaloopSticker
{
    NSDictionary *sdkExtra = [self pixaloopSDKExtra];
    if (sdkExtra) {
        NSString *pixaloopImgK = [sdkExtra acc_pixaloopImgK:@"pl"];
        return !ACC_isEmptyString(pixaloopImgK);
    }
    return NO;
}

- (BOOL)isMultiAssetsPixaloopProp
{
    NSDictionary *pixaloopInfo = [[self pixaloopSDKExtra] acc_objectForKey:@"pl"];
    BOOL hasMinCount = [pixaloopInfo acc_objectForKey:@"min_count"] != nil;
    BOOL hasMaxCount = [pixaloopInfo acc_objectForKey:@"max_count"] != nil;
    BOOL hasDefaultNum = [pixaloopInfo acc_objectForKey:@"default_num"] != nil;
    return hasMinCount && hasMaxCount && hasDefaultNum;
}

- (BOOL)isVideoBGPixaloopSticker
{
    NSDictionary *sdkExtra = [self pixaloopSDKExtra];
    if (sdkExtra) {
        NSString *pixaloopImgK = [sdkExtra acc_pixaloopImgK:@"vl"];
        return !ACC_isEmptyString(pixaloopImgK);
    }
    return NO;
}

@end

@implementation NSDictionary (Pixaloop)

- (NSArray<NSString *> *)acc_pixaloopAlg:(NSString*)key
{
    NSDictionary *pl = [self acc_dictionaryValueForKey:key];
    if ([pl isKindOfClass:[NSDictionary class]]) {
        NSArray *alg = [pl acc_arrayValueForKey:@"alg"];
        if ([alg isKindOfClass:[NSArray class]]) {
            return alg;
        }
    }
    return nil;
}

- (NSString *)acc_pixaloopImgK:(NSString*)key
{
    NSDictionary *pl = [self acc_dictionaryValueForKey:key];
    if ([pl isKindOfClass:[NSDictionary class]]) {
        return [pl acc_stringValueForKey:@"imgK"];
    }
    return nil;
}

- (NSString *)acc_pixaloopRelation:(NSString*)key
{
    NSDictionary *pl = [self acc_dictionaryValueForKey:key];
    if ([pl isKindOfClass:[NSDictionary class]]) {
        return [pl acc_stringValueForKey:@"relation"];
    }
    return nil;
}

- (NSString *)acc_pixaloopResourcePath:(NSString*)key
{
    NSDictionary *pl = [self acc_dictionaryValueForKey:key];
    if ([pl isKindOfClass:[NSDictionary class]]) {
        NSString *path = [pl acc_stringValueForKey:@"vPath"];
        if (ACC_isEmptyString(path)) {
            NSArray *pathArray = [pl acc_arrayValueForKey:@"multi_vPath"];
            if (!ACC_isEmptyArray(pathArray)) {
                NSUInteger index = arc4random() % pathArray.count;
                path = [pathArray objectAtIndex:index];
            }
        }
        return path;
    }
    return nil;
}

- (BOOL)acc_pixaloopLoading:(NSString*)key
{
    NSDictionary *pl = [self acc_dictionaryValueForKey:key];
    if ([pl isKindOfClass:[NSDictionary class]]) {
        return [pl acc_boolValueForKey:@"loading"];
    }
    return NO;
}

- (NSString *)acc_pixaloopText
{
    return [self acc_stringValueForKey:@"pixaloop_text"];
}

- (NSString *)acc_pixaloopVideoCover
{
    return [self acc_stringValueForKey:@"pixaloop_video_cover"];
}

- (NSString *)acc_pixaloopPictureCover
{
    return [self acc_stringValueForKey:@"pixaloop_picture_cover"];
}

- (NSString *)acc_illegalPhotoHint
{
    return [self acc_stringValueForKey:@"mv_algorithm_hint"];
}

- (NSString *)acc_mvResolutionLimitedToast{
    return [self acc_stringValueForKey:@"mv_resolution_limited_toast"];
}

- (NSInteger)acc_mvResolutionLimitedWidth{
    return [self acc_integerValueForKey:@"mv_resolution_limited_width"];
}

- (NSInteger)acc_mvResolutionLimitedHeight{
    return [self acc_integerValueForKey:@"mv_resolution_limited_height"];
}

- (NSString *)acc_savePhotoHint
{
    return [self acc_stringValueForKey:@"mv_auto_save_toast"];
}

- (NSString *)acc_algorithmArrNeedSavePhoto
{
    return [self acc_stringValueForKey:@"mv_server_algorithm_result_save_keys"];
}

- (BOOL)acc_enableMVOriginAudio {
    return [self acc_boolValueForKey:@"enable_mv_origin_audio"];
}


- (NSString *)acc_effectAlgorithmHint
{
    return [self acc_stringValueForKey:@"effect_algorithm_hint"];
}

- (NSInteger)acc_albumFilterNumber:(NSString *)key
{
    NSDictionary *pl = [self acc_dictionaryValueForKey:key];
    if ([pl isKindOfClass:[NSDictionary class]]) {
        return [pl acc_integerValueForKey:@"albumFilter"];
    }
    return 0;
}

- (NSInteger)acc_maxAssetsSelectionCount
{
    return [self acc_integerValueForKey:@"max_count"];
}

- (NSInteger)acc_minAssetsSelectionCount
{
    return [self acc_integerValueForKey:@"min_count"];
}

- (NSInteger)acc_defaultAssetsSelectionCount
{
    return [self acc_integerValueForKey:@"default_num"];
}

@end

#pragma mark - BindingMusic

@implementation IESEffectModel (BindingMusic)
- (BOOL)acc_isForceBindingMusic
{
    if (self.musicIDs.count > 0) {
        NSString *musicID = self.musicIDs.firstObject;
        if (musicID.length > 0) {
            // Is it music strong binding
            return [AWEStickerMusicManager musicIsForceBindStickerWithExtra:self.extra];
        }
    }
    return NO;
}
@end

#pragma mark - ACCARConfiguration

@implementation IESEffectModel (ACCARConfiguration)

- (NSDictionary *)acc_ARConfigurationDictionary {
    NSString *extra = self.sdkExtra;
    if (extra) {
        NSData *extraData = [extra dataUsingEncoding:NSUTF8StringEncoding];
        if (extraData) {
            NSError *parseError = nil;
            id jsonObject = [NSJSONSerialization JSONObjectWithData:extraData options:0 error:&parseError];
            if ([jsonObject isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dict = (NSDictionary *)jsonObject;
                NSDictionary *worldTracking = (NSDictionary *)[dict acc_dictionaryValueForKey:@"worldTracking"];
                if ([worldTracking isKindOfClass:[NSDictionary class]]) {
                    return worldTracking;
                }
            }
        }
    }
    return nil;
}

@end

#pragma mark - SlowMotion

@implementation IESEffectModel (SlowMotion)

- (BOOL)acc_isCannotCancelMusic
{
    NSDictionary *extraInfo = [self acc_analyzeExtra];
    if (extraInfo) {
        return [extraInfo acc_boolValueForKey:@"cannot_cancel_music"];
    }
    return NO;
}

- (BOOL)acc_useEffectRecordRate
{
    NSDictionary *extraInfo = [self acc_analyzeExtra];
    
    if ([self isMultiSegProp]) {
        return NO;
    }
    
    if (extraInfo) {
        return [extraInfo acc_boolValueForKey:@"forbid_speed_bar"];
    }
    
    return NO;
}

- (BOOL)acc_forbidSpeedBarSelection
{
    return [self isMultiSegProp] || [self acc_useEffectRecordRate];
}

- (BOOL)acc_isTypeSlowMotion
{
    NSDictionary *sdkExtra = [self acc_analyzeSDKExtra];
    if (sdkExtra) {
        return [sdkExtra acc_boolValueForKey:@"triggered_slow_motion"];
    }
    return NO;
}

@end

#pragma mark - Audio Graph

@implementation IESEffectModel (AudioGraph)

- (void)analyzeAudioGraph
{
    NSDictionary *dict = [[self.sdkExtra acc_jsonValueDecoded] acc_dictionaryValueForKey:@"audio_graph"];
    [self setIsTypeAudioGraph:dict!=nil];
    NSArray *sources = [dict acc_arrayValueForKey:@"sources"];
    [sources enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *stringObj = (NSString *)([obj isKindOfClass:[NSString class]] ? obj : nil);
        if ([stringObj isEqualToString:@"mic"]) {
            [self setAudioGraphMicSource:YES];
        } else if ([stringObj isEqualToString:@"music"]) {
            [self setAudioGraphMusicSource:YES];
        }
    }];
    [self setAudioGraphUseOutput:[dict acc_boolValueForKey:@"use_output"]];
    [self setAudioGraphAnalyzed:YES];
}

- (BOOL)audioGraphAnalyzed
{
    return [objc_getAssociatedObject(self, @selector(audioGraphAnalyzed)) boolValue];
}

- (void)setAudioGraphAnalyzed:(BOOL)analyzed
{
    objc_setAssociatedObject(self, @selector(audioGraphAnalyzed), @(analyzed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isTypeAudioGraph
{
    if (![self audioGraphAnalyzed]) {
        [self analyzeAudioGraph];
    }
    return [objc_getAssociatedObject(self, @selector(isTypeAudioGraph)) boolValue];
}

- (void)setIsTypeAudioGraph:(BOOL)isAudioGraph
{
    objc_setAssociatedObject(self, @selector(isTypeAudioGraph), @(isAudioGraph), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)audioGraphMicSource
{
    if (![self audioGraphAnalyzed]) {
        [self analyzeAudioGraph];
    }
    return [objc_getAssociatedObject(self, @selector(audioGraphMicSource)) boolValue];
}

- (void)setAudioGraphMicSource:(BOOL)micSource
{
    objc_setAssociatedObject(self, @selector(audioGraphMicSource), @(micSource), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)audioGraphMusicSource
{
    if (![self audioGraphAnalyzed]) {
        [self analyzeAudioGraph];
    }
    return [objc_getAssociatedObject(self, @selector(audioGraphMusicSource)) boolValue];
}

- (void)setAudioGraphMusicSource:(BOOL)musicSource
{
    objc_setAssociatedObject(self, @selector(audioGraphMusicSource), @(musicSource), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)audioGraphUseOutput
{
    if (![self audioGraphAnalyzed]) {
        [self analyzeAudioGraph];
    }
    return [objc_getAssociatedObject(self, @selector(audioGraphUseOutput)) boolValue];
}

- (void)setAudioGraphUseOutput:(BOOL)useOutput
{
    objc_setAssociatedObject(self, @selector(audioGraphUseOutput), @(useOutput), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
