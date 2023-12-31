//
//  ACCCutSameVideoCompressConfigProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/4/20.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ACCCutSameVideoCompressResolution) {
    ACCCutSameVideoCompressResolution_r720p  = 720,
    ACCCutSameVideoCompressResolution_r1080p = 1080,
    ACCCutSameVideoCompressResolution_r4K    = 2160,
};

NS_ASSUME_NONNULL_BEGIN

@protocol ACCCutSameVideoCompressConfigProtocol <NSObject>

/**
 最大的FPS
 */
@property (nonatomic, assign) NSInteger maxFps;

/**
 最大的分辨率
 */
@property (nonatomic, assign) ACCCutSameVideoCompressResolution maxResolution;

/**
 为YES时，不压缩直接返回。
 为NO时，判断FPS和分辨率。
 */
@property (nonatomic, assign, getter=isIgnore) BOOL ignore;

/**
 FPS 30   分辨率1080p  不忽略压缩
 */
+ (instancetype)defaultConfig;

/**
 初始化
 @param fps 最大的FPS
 @param resolution 最大的分辨率
 */
+ (instancetype)alloc;
 
- (instancetype)initWithFps:(NSInteger)fps resolution:(ACCCutSameVideoCompressResolution)resolution;

+ (BOOL)isWorseThanIPhone6s;

@end

@protocol ACCMVCutSameStyleVideoCompressConfigProtocol <ACCCutSameVideoCompressConfigProtocol>

@end

NS_ASSUME_NONNULL_END
