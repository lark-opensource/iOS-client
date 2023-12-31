//
//  ACCImageAlbumAudioPlayer.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2020/12/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCMusicModelProtocol;

@interface ACCImageAlbumAudioPlayer : NSObject

- (void)replay;

- (void)continuePlay;

- (void)pause;

- (void)replaceMusic:(id<ACCMusicModelProtocol>)music;

@end

NS_ASSUME_NONNULL_END
