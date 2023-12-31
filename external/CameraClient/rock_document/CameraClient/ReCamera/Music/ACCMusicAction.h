//
//  ACCMusicAction.h
//  CameraClient
//
//  Created by luochaojing on 2019/12/31.
//

#import <CameraClient/ACCAction.h>
#import "ACCMusicStruct.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(int, ACCMusicActionType) {
    ACCMusicActionTypeApply,
    ACCMusicActionTypeDelete,
    ACCMusicActionTypeEnableBGM,
    ACCMusicActionTypeStartBGM,
    ACCMusicActionTypePauseBGM,
};

typedef NS_OPTIONS(NSUInteger, ACCEffectBGMType) {
    ACCEffectTypeNone      = 0,
    ACCEffectBGMTypeMusic  = 1 << 0,
    ACCEffectTypeSLAM      = 1 << 1,
    ACCEffectTypeGame      = 1 << 2,
    ACCEffectTypeSticker   = 1 << 4, //暂停贴纸内部更新
    ACCEffectBGMTypeNormal = ACCEffectTypeSLAM | ACCEffectBGMTypeMusic,
    ACCEffectBTypeAll      = 0xFFFFFFFF,
};

@interface ACCMusicAction : ACCAction

@property (nonatomic, assign) BOOL isOpen;
@property (nonatomic, strong) id payload;

+ (instancetype)applyMusic:(id<ACCMusicStruct>)music;
+ (instancetype)deleteMusic;

+ (instancetype)enableBGM:(BOOL)enable;
+ (instancetype)startBGM:(ACCEffectBGMType)type;
+ (instancetype)pauseBGM:(ACCEffectBGMType)type;

@end

NS_ASSUME_NONNULL_END
