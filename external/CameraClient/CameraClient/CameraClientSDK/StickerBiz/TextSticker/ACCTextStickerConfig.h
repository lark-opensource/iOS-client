//
//  ACCTextStickerConfig.h
//  CameraClient
//
//  Created by Yangguocheng on 2020/7/20.
//

#import "ACCCommonStickerConfig.h"

typedef NS_ENUM(NSInteger, ACCTextStickerConfigType) {
    ACCTextStickerConfigType_Common,
    ACCTextStickerConfigType_AlbumImage,
};

NS_ASSUME_NONNULL_BEGIN

@interface ACCTextStickerConfig : ACCCommonStickerConfig

@property (nonatomic, assign) ACCStickerBubbleAction textReadAction;

@property (nonatomic, assign) ACCTextStickerConfigType type;

@property (nonatomic, copy) void (^readText)(void);
@property (nonatomic, copy) void (^editText)(void);
@property (nonatomic, copy) void (^selectTime)(void);

@property (nonatomic, assign) BOOL needBubble;

@end

NS_ASSUME_NONNULL_END
