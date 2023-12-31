//
//  ACCAudioMusicServiceProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Zhihao Zhang on 2021/2/28.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>

NS_ASSUME_NONNULL_BEGIN

/// 使用方式：实现 AWESingleMusicView 的分类
/// 实现 AWEMusicServiceDelegate 中感兴趣的方法
/// 使用方式有些奇怪，后续重构要重新考虑实现
@protocol ACCAudioMusicServiceProtocol <NSObject>

- (void)addObserver:(id)observer;
- (void)removeObserver:(id)observer;

@end

NS_ASSUME_NONNULL_END

FOUNDATION_STATIC_INLINE id<ACCAudioMusicServiceProtocol> ACCAudioMusicService() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCAudioMusicServiceProtocol)];
}
