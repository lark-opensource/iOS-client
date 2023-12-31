//
//  ACCInfoStickerConfig.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/9/18.
//

#import "ACCCommonStickerConfig.h"

typedef NS_ENUM(NSInteger, ACCInfoStickerType) {
    ACCInfoStickerTypeCommon = 0,
    ACCInfoStickerTypeDaily = 1,    // daily sticker For Story case
};

NS_ASSUME_NONNULL_BEGIN

@interface ACCInfoStickerConfig : ACCCommonStickerConfig

@property (nonatomic, copy) NSString *effectIdentifier;
@property (nonatomic, assign) ACCInfoStickerType type;

@property (nonatomic, assign) BOOL isImageAlbum;

@property (nonatomic, strong) void(^selectTime)(void);

@property (nonatomic, strong) void(^pinAction)(void);

@property (nonatomic, assign, getter=isPinable) BOOL pinable;

@end

NS_ASSUME_NONNULL_END
