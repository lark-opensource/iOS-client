//
//  ACCCutSameVideoCompressConfig.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/4/20.
//

#import <Foundation/Foundation.h>
#import "ACCCutSameVideoCompressConfigProtocol.h"
#import <VideoTemplate/LVVideoCompressor.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCCutSameVideoCompressConfig : NSObject<ACCCutSameVideoCompressConfigProtocol>

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
- (instancetype)initWithFps:(NSInteger)fps resolution:(ACCCutSameVideoCompressResolution)resolution;

@property (nonatomic, strong) LVVideoCompressConfig *originConfig;

@end

NS_ASSUME_NONNULL_END
