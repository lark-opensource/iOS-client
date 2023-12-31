//
//  AWEStoryTextImageModel.h
//  AWEStudio
//
//  Created by li xingdong on 2019/1/16.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>
#import "ACCStickerMigrationProtocol.h"
#import "ACCPublishRepository.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    AWEStoryTextStyleNo = 0,// There is no bottom, change the color is to change the text color
    AWEStoryTextStyleStroke = 1,
    AWEStoryTextStyleBackground = 2,// If there is a bottom, changing the color is to change the background color, and the text color is white. If white is selected, (if the background is full, the text color becomes black; if the background is translucent, the text color becomes white)
    AWEStoryTextStyleAlphaBackground = 3,
    AWEStoryTextStyleCount,
} AWEStoryTextStyle;

typedef NS_ENUM(NSInteger, AWEStoryTextAlignmentStyle) {
    AWEStoryTextAlignmentCenter = 0,    // Center
    AWEStoryTextAlignmentLeft = 1,      // On the left
    AWEStoryTextAlignmentRight = 2,     // On the right
    AWEStoryTextAlignmentCount
};

typedef NS_ENUM(NSInteger, AWEStoryTextFontDownloadState) {
    AWEStoryTextFontUndownloaded = 0,
    AWEStoryTextFontDownloading = 1,
    AWEStoryTextFontDownloaded = 2,
};

@class ACCTextStickerExtraModel;

static inline ACCCrossPlatformAlignment crossPlatformAlignmentFromTextAlignment(AWEStoryTextAlignmentStyle textAlignment)
{
    ACCCrossPlatformAlignment crossPlatformAlignment = ACCCrossPlatformAlignmentLeft;
    switch (textAlignment) {
        case AWEStoryTextAlignmentCenter:
            crossPlatformAlignment = ACCCrossPlatformAlignmentCenter;
            break;
        case AWEStoryTextAlignmentLeft:
            crossPlatformAlignment = ACCCrossPlatformAlignmentLeft;
            break;
        case AWEStoryTextAlignmentRight:
            crossPlatformAlignment = ACCCrossPlatformAlignmentRight;
            break;
        default:
            crossPlatformAlignment = ACCCrossPlatformAlignmentLeft;
            break;
    }
    return crossPlatformAlignment;
}

static inline AWEStoryTextAlignmentStyle textAlignmentFromCrossPlatformAlignment(ACCCrossPlatformAlignment alignment)
{
    AWEStoryTextAlignmentStyle alignmentStyle = AWEStoryTextAlignmentCenter;
    switch (alignment) {
        case ACCCrossPlatformAlignmentCenter:
            alignmentStyle = AWEStoryTextAlignmentCenter;
            break;
        case ACCCrossPlatformAlignmentLeft:
            alignmentStyle = AWEStoryTextAlignmentLeft;
            break;
        case ACCCrossPlatformAlignmentRight:
            alignmentStyle = AWEStoryTextAlignmentRight;
            break;
        default:
            alignmentStyle = AWEStoryTextAlignmentCenter;
            break;
    }
    return alignmentStyle;
}

@interface AWEStoryColor : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) NSString *colorString;

@property (nonatomic, strong, nullable) UIColor *borderColor;
@property (nonatomic, strong, nullable) NSString *borderColorString;

+ (instancetype)colorWithHexString:(NSString *)hexString;
+ (instancetype)colorWithHexString:(NSString *)hexString alpha:(float)opacity;
+ (instancetype)colorWithTextColorHexString:(NSString *)textHexString borderColorHexString:(nullable NSString *)borderHexString;

@end

@class IESEffectModel;

@interface AWEStoryFontModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, copy) NSString *title;            // Title for display
@property (nonatomic, copy) NSString *fontName;         // Font file name
@property (nonatomic, copy) NSString *fontFileName;     // Corresponding to the font in the status resource package_ file_ Name for mapping
@property (nonatomic, copy, nullable) NSString *localUrl;         // It's a bit complicated to get the local special effects file according to the special effects ID. here, it's saved directly through a field. The field name should be consistent with the previous one sent by setting
@property (nonatomic, assign) BOOL hasBgColor;          // Support background color
@property (nonatomic, assign) BOOL hasShadeColor;       // Do you support neon effect

@property (nonatomic, assign) NSInteger defaultFontSize;// Default font size
@property (nonatomic, copy) NSString *effectId;       // Font use special effects platform to download, a font corresponding to a special effect

@property (nonatomic, strong) NSValue *titleSize;
@property (nonatomic, strong) NSValue *collectionCellSize;

@property (nonatomic, assign, readonly) BOOL download;
@property (nonatomic, assign, readonly) BOOL supportStroke;

@property (nonatomic, assign) AWEStoryTextFontDownloadState downloadState; // 0 not downloaded, 1 downloading, 2 downloaded

- (instancetype)initWithEffectModel:(IESEffectModel *)effectModel;

+ (BOOL)isValidEffectModel:(IESEffectModel *)effectModel;

@end

@class AVAsset, IESMMVideoDataClipRange;

@interface AWETextStickerReadModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) BOOL useTextRead;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *stickerKey;// Bind readModel and asset
@property (nonatomic, copy, nullable) NSString *audioPath;
@property (nonatomic, copy, nullable) NSString *soundEffect; // TTS sound effect, retrieved from server, e.g. xiaomei

@end

@interface AWETextStickerStylePreferenceModel : NSObject<NSCopying>

@property (nonatomic, assign) BOOL enableUsingUserPreference;
@property (nonatomic, strong) AWEStoryFontModel *preferenceTextFont;
@property (nonatomic, strong) AWEStoryColor *preferenceTextColor;

@end

@interface AWEStoryTextImageModel : MTLModel<MTLJSONSerializing>
@property (nonatomic, assign) BOOL isCaptionSticker;
@property (nonatomic, assign) BOOL isPOISticker;
@property (nonatomic, assign) BOOL isTaskSticker;
@property (nonatomic, assign) BOOL isNotEditableSticker;
@property (nonatomic, assign) BOOL isNotDeletableSticker;
@property (nonatomic, assign) BOOL isAutoAdded;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSIndexPath *colorIndex;
@property (nonatomic, strong) AWEStoryColor *fontColor;
@property (nonatomic, strong) NSIndexPath *fontIndex;
@property (nonatomic, strong) AWEStoryFontModel *fontModel;
@property (nonatomic, assign) AWEStoryTextStyle textStyle;
@property (nonatomic, assign) AWEStoryTextAlignmentStyle alignmentType;
@property (nonatomic, assign) CGFloat keyboardHeight;
@property (nonatomic, assign) CGFloat realStartTime;
@property (nonatomic, assign) CGFloat realDuration;
@property (nonatomic, assign) CGFloat fontSize;
@property (nonatomic, assign) BOOL isAddedInEditView;
@property (nonatomic, copy) NSDictionary *extra;
@property (nonatomic, strong, nullable) AWETextStickerReadModel *readModel;// Only enable in new container
@property (nonatomic, copy, nullable) NSArray<ACCTextStickerExtraModel *> *extraInfos;
- (NSDictionary *)trackInfo;

@end

@compatibility_alias ACCStickerTextModel AWEStoryTextImageModel;

NS_ASSUME_NONNULL_END
