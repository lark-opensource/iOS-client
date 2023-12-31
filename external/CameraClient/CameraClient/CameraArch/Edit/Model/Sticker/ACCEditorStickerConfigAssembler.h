//
//  ACCEditorStickerConfigAssembler.h
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/3/15.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCUserModelProtocol.h>
#import <EffectPlatformSDK/IESEffectModel.h>
#import <CameraClient/AWEInteractionStickerModel+DAddition.h>
#import <CreationKitArch/AWEStoryTextImageModel.h>
#import <CreativeKitSticker/ACCStickerDefines.h>
#import "ACCSocialStickerModel.h"
#import "ACCPOIStickerModel.h"

NS_ASSUME_NONNULL_BEGIN

//
@interface ACCEditorStickerNormalizedLocation : NSObject

@property (nonatomic, assign) CGFloat x;      // default is 0.5
@property (nonatomic, assign) CGFloat y;      // default is 0.5
@property (nonatomic, assign) CGFloat scale;  // default is 1
@property (nonatomic, assign) CGFloat rotation;

// will support info sticker soon
@property (nonatomic, strong) NSValue *alignPoint;
@property (nonatomic, strong) NSValue *alignPosition;
@property (nonatomic, assign) BOOL persistentAlign; // default is NO, only support NO currently, will support YES soon

@end

@interface ACCEditorStickerConfig : NSObject

@property (nonatomic, strong) ACCEditorStickerNormalizedLocation *location;
@property (nonatomic, assign) ACCStickerGestureType supportedGestureType;
@property (nonatomic, assign) BOOL deleteable; // default is YES
@property (nonatomic, assign) BOOL editable;   // default is NO
@property (nonatomic, strong) NSNumber *groupId;
@property (nonatomic, assign) CGFloat minimumScale;
@property (nonatomic, assign) NSInteger layerIndex;

- (AWEInteractionStickerLocationModel *)locationModel;

@end

@interface ACCEditorInfoStickerConfig : ACCEditorStickerConfig

@property (nonatomic, copy) NSString *effectIdentifer;
@property (nonatomic, strong) IESEffectModel *effectModel;

/// 关联的信息化贴纸动画资源
@property (nonatomic, copy) NSString *associatedAnimationEffectIdentifer;
@property (nonatomic, strong) IESEffectModel *associatedAnimationEffectModel;
@property (nonatomic, assign) CGFloat associatedAnimationDuration;

@property (nonatomic, strong) NSNumber *maxEdgeNumber; // nonNormalized

/// @see addInfoSticker:path withEffectInfo:params userInfo:userInfo
@property (nonatomic, copy) NSArray *effectInfos;

@end

typedef NS_ENUM(NSInteger, ACCTextStyle) {
    ACCTextStyleNone = 0,
    ACCTextStyleStroke = 1,
    ACCTextStyleBackground = 2,
    ACCTextStyleAlphaBackground = 3,
};

@interface ACCEditorTextStickerConfig : ACCEditorStickerConfig

@property (nonatomic, strong) NSString *text;
@property (nonatomic, assign) ACCTextStyle textStyle;
@property (nonatomic, assign) NSUInteger colorIndex;
@property (nonatomic, strong) AWEStoryColor *color;
@property (nonatomic, strong) NSString *fontName;
@property (nonatomic, strong) NSNumber *fontSize;
@property (nonatomic, copy, nullable) NSArray<ACCTextStickerExtraModel *> *extraInfos;
@property (nonatomic, assign) BOOL isTaskSticker;
@property (nonatomic, assign) BOOL isAutoAdded;
// add hashtag extra to extraInfos, default location is [0, text.length + 1], include first char "#"
- (ACCTextStickerExtraModel *_Nullable)addHashtagExtraWithHashtagName:(NSString *)hashtagName;

- (ACCStickerTextModel *)textModel;

@end

@interface ACCEditorHashtagStickerConfig : ACCEditorStickerConfig

@property (nonatomic, strong) NSString *name;

- (ACCSocialStickerModel *)socialStickerModel;

@end

@interface ACCEditorMentionStickerConfig : ACCEditorStickerConfig

@property (nonatomic, strong) id<ACCUserModelProtocol> user;

- (ACCSocialStickerModel *)socialStickerModel;

@end

@interface ACCEditorCustomStickerConfig : ACCEditorStickerConfig

@property (nonatomic, strong) NSString *dataUIT; // example kUTTypePNG

@property (nonatomic, strong) __kindof UIImage *image; // will use image first, mutually exclusive with imageData
@property (nonatomic, strong) NSData *imageData;

@property (nonatomic, strong) NSNumber *maxEdgeNumber; // nonNormalized

@end

@interface ACCEditorPOIStickerConfig : ACCEditorStickerConfig

@property (nonatomic, strong) NSString *POIID;
@property (nonatomic, strong) NSString *POIName;
@property (nonatomic, strong) NSArray<NSString *> *styleEffectIds;

- (ACCPOIStickerModel *)POIModel;

@end

@interface ACCEditorLyricsStickerConfig : ACCEditorStickerConfig

@property (nonatomic, copy) NSString *effectIdentifer;
@property (nonatomic, strong) IESEffectModel *downloadedEffect;

@end

@interface ACCEditorStickerConfigAssembler : NSObject

- (void)prepareOnCompletion:(void (^)(NSError * _Nullable))completionHandler;

- (void)addInfoSticker:(void (^)(ACCEditorInfoStickerConfig * _Nonnull config))infoStickerConstructor;

- (void)addCustomSticker:(void (^)(ACCEditorCustomStickerConfig * _Nonnull config))constructor;

- (void)addTextSticker:(void (^)(ACCEditorTextStickerConfig * _Nonnull config))constructor;

- (void)addMentionSticker:(void (^)(ACCEditorMentionStickerConfig * _Nonnull config))constructor;

- (void)addHashtagSticker:(void (^)(ACCEditorHashtagStickerConfig * _Nonnull config))constructor;

- (BOOL)addPOISticker:(void (^)(ACCEditorPOIStickerConfig * _Nonnull config))constructor;

- (void)setupLyricsSticker:(void (^)(ACCEditorLyricsStickerConfig * _Nonnull))constructor;

- (NSArray<ACCEditorStickerConfig *> *)infoStickerConfigList; // all info sticker and custom info stickers
- (NSArray<ACCEditorStickerConfig *> *)textStickerConfigList; // all text stickers, mention stickers and hashtag stickers
- (ACCEditorPOIStickerConfig *)modernPOIStickerConfig;
- (ACCEditorLyricsStickerConfig *)lyricsStickerConfig;

@end

NS_ASSUME_NONNULL_END
