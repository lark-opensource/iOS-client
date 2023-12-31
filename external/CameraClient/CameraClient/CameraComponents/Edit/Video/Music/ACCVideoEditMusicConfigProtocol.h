//
//  ACCVideoEditMusicConfigProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Zhihao Zhang on 2021/1/24.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCVideoEditMusicConfigProtocol <NSObject>

/// 是否使用宿主提供的音乐数据
- (BOOL)enableUseMusicFromHost;


@optional
/// 如果 enableUseMusicFromHost 设为 YES，则需要实现此方法
- (nullable NSArray<id<ACCMusicModelProtocol>> *)getVideoEditMusicModelArray;

@end




NS_ASSUME_NONNULL_END
