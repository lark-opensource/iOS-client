//
//  ACCVideoEditVolumeChangeContext.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/1/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCVideoEditVolumeChangeType) {
    ACCVideoEditVolumeChangeTypeVoice = 0,
    ACCVideoEditVolumeChangeTypeMusic = 1,
};

@class HTSVideoSoundEffectPanelView;
@interface ACCVideoEditVolumeChangeContext : NSObject

@property (nonatomic, assign) ACCVideoEditVolumeChangeType changeType;
@property (nonatomic, strong) HTSVideoSoundEffectPanelView *panelView;

+ (instancetype)createWithPanelView:(HTSVideoSoundEffectPanelView *)panelView changeType:(ACCVideoEditVolumeChangeType)changeType;

@end

NS_ASSUME_NONNULL_END
