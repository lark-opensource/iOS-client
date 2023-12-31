//
//  ACCSmartMovieABConfig.h
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/7/29.
//

#import <Foundation/Foundation.h>

@interface ACCSmartMovieABConfig : NSObject

+ (BOOL)isOn;

///// 对照组V1（线上）
//+ (BOOL)isControlV1;

/// 实验组V1（支持智能效果+普通效果，默认展示智能）
+ (BOOL)defaultSmartMovie;

/// 实验组V3（不支持普通效果，直接替换）
//+ (BOOL)isExperimentV3;

/// 实验组V2（支持智能效果+普通效果，默认展示普通）
+ (BOOL)defaultMV;

///// 是否是优先选项
//+ (BOOL)isPreferredOption;

@end
