//
//  ACCEditorStickerConfigAssembler.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/3/15.
//

#import "ACCEditorStickerConfigAssembler.h"

#import <CreationKitInfra/ACCLogHelper.h>
#import <CreationKitArch/ACCCustomFontProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCMacrosTool.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <EffectPlatformSDK/EffectPlatform+Additions.h>
#import <CreationKitArch/ACCTextStickerExtraModel.h>
#import "ACCConfigKeyDefines.h"

@implementation ACCEditorStickerNormalizedLocation

- (instancetype)init
{
    self = [super init];
    if (self) {
        _scale = 1;
        _x = 0.5;
        _y = 0.5;
    }
    return self;
}

@end

@implementation ACCEditorStickerConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        _location = [[ACCEditorStickerNormalizedLocation alloc] init];
        _deleteable = YES;
        _supportedGestureType = ACCStickerGestureTypeTap | ACCStickerGestureTypePan | ACCStickerGestureTypePinch | ACCStickerGestureTypeRotate;
        _editable = NO;
    }
    return self;
}

- (AWEInteractionStickerLocationModel *)locationModel
{
    AWEInteractionStickerLocationModel *locationModel = [[AWEInteractionStickerLocationModel alloc] init];
    
    locationModel.x = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", self.location.x]];
    locationModel.y = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", self.location.y]];
    locationModel.scale = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", self.location.scale]];
    locationModel.rotation = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%.4f", self.location.rotation]];
    locationModel.pts = [NSDecimalNumber decimalNumberWithString:@"-1"];
    return locationModel;
}

@end

@implementation ACCEditorInfoStickerConfig

@end

@implementation ACCEditorTextStickerConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.editable = YES;
    }
    return self;
}

- (ACCStickerTextModel *)textModel
{
    ACCStickerTextModel *textModel = [[ACCStickerTextModel alloc] init];
    textModel.content = self.text;
    textModel.textStyle = [self textModelTextStyle];
    textModel.fontColor = self.color;
    textModel.colorIndex = [NSIndexPath indexPathForItem:self.colorIndex inSection:0];
    AWEStoryFontModel *fontModel = [[ACCCustomFont() stickerFonts] acc_match:^BOOL(AWEStoryFontModel * _Nonnull item) {
        return [item.title isEqual:self.fontName];
    }];
    textModel.fontModel = fontModel;
    textModel.extraInfos = self.extraInfos;
    if (self.fontSize != nil) {
        textModel.fontSize = self.fontSize.floatValue;
    }
    textModel.isAutoAdded = self.isAutoAdded;
    textModel.isTaskSticker = self.isTaskSticker;
    return textModel;
}

- (ACCTextStickerExtraModel *)addHashtagExtraWithHashtagName:(NSString *)hashtagName
{
    if (ACC_isEmptyString(hashtagName)) {
        return nil;
    }
    
    if ([hashtagName hasPrefix:@"#"]) {
        hashtagName = [hashtagName stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
    }
    
    NSMutableArray <ACCTextStickerExtraModel *> *tmp = [NSMutableArray arrayWithArray:self.extraInfos?:@[]];
    ACCTextStickerExtraModel *extra = [ACCTextStickerExtraModel hashtagExtraWithHashtagName:hashtagName];
    extra.start = 0;
    extra.length = hashtagName.length + 1; //  underline style include first char "#"
    if (extra.isValid) {
        [tmp addObject:extra];
        self.extraInfos = [tmp copy];
        return extra;
    }
    return nil;
}

- (AWEStoryTextStyle)textModelTextStyle
{
    switch (self.textStyle) {
        case ACCTextStyleNone:
            return AWEStoryTextStyleNo;
        case ACCTextStyleStroke:
            return AWEStoryTextStyleStroke;
        case ACCTextStyleBackground:
            return AWEStoryTextStyleBackground;
        case ACCTextStyleAlphaBackground:
            return AWEStoryTextStyleAlphaBackground;
        default:
            return AWEStoryTextStyleNo;
    }
}

@end

@implementation ACCEditorHashtagStickerConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.editable = YES;
    }
    return self;
}

- (ACCSocialStickerModel *)socialStickerModel
{
    // 812897 is not a great solution, however effectIdentifier cases nothing, it's only use in feed page for tracking, while track hashtag's changeless identifer is meaningless
    ACCSocialStickerModel *socialStickerModel = [[ACCSocialStickerModel alloc] initWithStickerType:ACCSocialStickerTypeHashTag effectIdentifier:@"812897"];
    socialStickerModel.contentString = self.name;
    return socialStickerModel;
}

@end

@implementation ACCEditorMentionStickerConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.editable = YES;
    }
    return self;
}

- (ACCSocialStickerModel *)socialStickerModel
{
    // 812899 is not a great solution, however effectIdentifier cases nothing, it's only use in feed page for tracking, while track hashtag's changeless identifer is meaningless
    ACCSocialStickerModel *socialStickerModel = [[ACCSocialStickerModel alloc] initWithStickerType:ACCSocialStickerTypeMention effectIdentifier:@"812899"];
    ACCSocialStickeMentionBindingModel *mentionModel =  [ACCSocialStickeMentionBindingModel modelWithSecUserId:self.user.secUserID userId:self.user.userID userName:self.user.nickname followStatus:self.user.followStatus];
    socialStickerModel.mentionBindingModel = mentionModel;
    socialStickerModel.contentString = self.user.nickname;
    return socialStickerModel;
}

@end

@implementation ACCEditorCustomStickerConfig

@end

@implementation ACCEditorPOIStickerConfig

- (ACCPOIStickerModel *)POIModel
{
    ACCPOIStickerModel *POIModel = [[ACCPOIStickerModel alloc] init];
    POIModel.effectIdentifier =  ACCConfigBool(kConfigBool_sticker_support_poi_mention_hashtag_UI_uniform) ? @"1231591" : @"173154";
    POIModel.poiID = self.POIID;
    POIModel.poiName = self.POIName;
    POIModel.styleEffectIds = self.styleEffectIds;
    
    return POIModel;
}

@end

@implementation ACCEditorLyricsStickerConfig

@end

@interface ACCEditorStickerConfigAssembler ()

// Different sticker hierarchys are classified in different arrays
@property (nonatomic, strong) NSMutableArray<__kindof ACCEditorStickerConfig *> *infoStickerList;
@property (nonatomic, strong) ACCEditorPOIStickerConfig *modernPOISticker;
@property (nonatomic, strong) NSMutableArray<__kindof ACCEditorStickerConfig *> *textStickerList;
@property (nonatomic, strong) ACCEditorLyricsStickerConfig *lyricsStickerConfig;

@end

@implementation ACCEditorStickerConfigAssembler

- (instancetype)init
{
    self = [super init];
    if (self) {
        _infoStickerList = [NSMutableArray array];
        _textStickerList = [NSMutableArray array];
    }
    return self;
}

- (void)addInfoSticker:(void (^)(ACCEditorInfoStickerConfig * _Nonnull))constructor
{
    [self.infoStickerList addObject:({
        ACCEditorInfoStickerConfig *config = [[ACCEditorInfoStickerConfig alloc] init];
        constructor(config);
        config;
    })];
}

- (void)addCustomSticker:(void (^)(ACCEditorCustomStickerConfig * _Nonnull))constructor
{
    [self.infoStickerList addObject:({
        ACCEditorCustomStickerConfig *config = [[ACCEditorCustomStickerConfig alloc] init];
        constructor(config);
        config;
    })];
}

- (void)addTextSticker:(void (^)(ACCEditorTextStickerConfig * _Nonnull))constructor
{
    [self.textStickerList addObject:({
        ACCEditorTextStickerConfig *config = [[ACCEditorTextStickerConfig alloc] init];
        constructor(config);
        config;
    })];
}

- (void)addMentionSticker:(void (^)(ACCEditorMentionStickerConfig * _Nonnull))constructor
{
    [self.textStickerList addObject:({
        ACCEditorMentionStickerConfig *config = [[ACCEditorMentionStickerConfig alloc] init];
        constructor(config);
        config;
    })];
}

- (void)addHashtagSticker:(void (^)(ACCEditorHashtagStickerConfig * _Nonnull))constructor
{
    [self.textStickerList addObject:({
        ACCEditorHashtagStickerConfig *config = [[ACCEditorHashtagStickerConfig alloc] init];
        constructor(config);
        config;
    })];
}

- (BOOL)addPOISticker:(void (^)(ACCEditorPOIStickerConfig * _Nonnull))constructor
{
    if (self.modernPOISticker != nil) {
        return NO;
    }
    self.modernPOISticker = ({
        ACCEditorPOIStickerConfig *config = [[ACCEditorPOIStickerConfig alloc] init];
        constructor(config);
        config;
    });
    return YES;
}

- (void)setupLyricsSticker:(void (^)(ACCEditorLyricsStickerConfig * _Nonnull))constructor
{
    self.lyricsStickerConfig = [[ACCEditorLyricsStickerConfig alloc] init];
    if (constructor) {
        constructor(self.lyricsStickerConfig);
    }
}

- (void)prepareOnCompletion:(void (^)(NSError * _Nullable))completionHandler
{
    NSMutableSet<NSString *> *effectIDsToDownload = [NSMutableSet set];
    [self.infoStickerList enumerateObjectsUsingBlock:^(__kindof ACCEditorStickerConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[ACCEditorInfoStickerConfig class]]) {
            ACCEditorInfoStickerConfig *infoStickerConfig = (ACCEditorInfoStickerConfig *)obj;
            if (infoStickerConfig.effectModel == nil) {
                [effectIDsToDownload addObject:infoStickerConfig.effectIdentifer];
            }
            
            if (!ACC_isEmptyString(infoStickerConfig.associatedAnimationEffectIdentifer) && !infoStickerConfig.associatedAnimationEffectModel) {
                
                [effectIDsToDownload addObject:infoStickerConfig.associatedAnimationEffectIdentifer];
            }
        }
    }];
    if (self.modernPOISticker != nil) {
       [effectIDsToDownload addObjectsFromArray:self.modernPOISticker.styleEffectIds];
    }
    
    if (!ACC_isEmptyString(self.lyricsStickerConfig.effectIdentifer)) {
        [effectIDsToDownload addObject:self.lyricsStickerConfig.effectIdentifer];
    }
    
    NSArray *effectIDSListToDownload = [effectIDsToDownload allObjects];
    [effectIDSListToDownload acc_filter:^BOOL(NSString * _Nonnull item) {
        IESEffectModel *effectModel = [[EffectPlatform sharedInstance] cachedEffectOfEffectId:item];
        return !effectModel.downloaded;
    }];
    if (self.textStickerConfigList.count > 0) {
        [ACCCustomFont() prefetchFontEffects];
    };
    if (!ACC_isEmptyArray(effectIDSListToDownload)) {
        [EffectPlatform downloadEffectListWithEffectIDS:effectIDSListToDownload completion:^(NSError * _Nullable error, NSArray<IESEffectModel *> * _Nullable effects) {
            if (!error && !ACC_isEmptyArray(effects)) {
                [self dispatchEffectModel:effects];
                dispatch_group_t group = dispatch_group_create();
                __block NSError *downloadEffectError = nil;
                for (IESEffectModel *effect in effects) {
                    dispatch_group_enter(group);
                    [EffectPlatform downloadEffect:effect progress:nil completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
                        if (error) {
                            downloadEffectError = error;
                            AWELogToolError2(@"EditTransfer", AWELogToolTagEdit, @"Draft effect: %@ resource download error: %@", effect.effectIdentifier, error);
                        }
                        dispatch_group_leave(group);
                    }];
                }
                dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                    if (completionHandler) {
                        completionHandler(downloadEffectError);
                    }
                });
            } else {
                AWELogToolError2(@"EditTransfer", AWELogToolTagEdit, @"EditTransfer effects: %@ resource recover error: %@", effectIDsToDownload, error);
                if (completionHandler) {
                    completionHandler(error);
                }
            }
        }];
    } else {
        if (completionHandler) {
            completionHandler(nil);
        }
    }
}

- (void)dispatchEffectModel:(NSArray<IESEffectModel *> * _Nullable)effects
{
    if (effects.count == 0) {
        return;
    }
    NSMutableDictionary<NSString *, IESEffectModel *> *effectDictionary = [NSMutableDictionary dictionaryWithCapacity:effects.count];
    for (IESEffectModel *effectModel in effects) {
        if (effectModel.effectIdentifier != nil) {
            effectDictionary[effectModel.effectIdentifier] = effectModel;
        }
    }
    for (ACCEditorStickerConfig *config in self.infoStickerList) {
        if ([config isKindOfClass:[ACCEditorInfoStickerConfig class]]) {
            ACCEditorInfoStickerConfig *infoStickerConfig = (ACCEditorInfoStickerConfig *)config;
            infoStickerConfig.effectModel = effectDictionary[infoStickerConfig.effectIdentifer];
            if (!ACC_isEmptyString(infoStickerConfig.associatedAnimationEffectIdentifer)) {
                infoStickerConfig.associatedAnimationEffectModel = effectDictionary[infoStickerConfig.associatedAnimationEffectIdentifer];
            }
        }
    }
    if (self.lyricsStickerConfig.effectIdentifer) {
        self.lyricsStickerConfig.downloadedEffect = effectDictionary[self.lyricsStickerConfig.effectIdentifer];
    }
}

#pragma mark -

- (NSArray<ACCEditorStickerConfig *> *)infoStickerConfigList
{
    return [self.infoStickerList copy];
}

- (NSArray<ACCEditorStickerConfig *> *)textStickerConfigList
{
    return [self.textStickerList copy];
}

- (ACCEditorPOIStickerConfig *)modernPOIStickerConfig
{
    return self.modernPOISticker;
}

- (ACCEditorLyricsStickerConfig *)lyricsStickerConfig
{
    return _lyricsStickerConfig;
}

@end
