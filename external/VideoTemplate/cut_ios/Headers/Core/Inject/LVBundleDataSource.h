//
//  LVBundleDataSource.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/12.
//

#import <Foundation/Foundation.h>
#import "LVModelType.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LVBundleDataSource <NSObject>

/**
 音效资源路径
*/
+ (NSString *)voiceEffectPath;

/**
 调节小项资源路径
*/
+ (NSString *)videoAjustPathForType:(LVPayloadRealType)type withResourceVersion:(NSString*)version;

/**
 系统字体资源路径
*/
+ (NSString *)systemFontFolder;

/**
 片尾视频资源路径
*/
+ (NSString *)taileaderReourcePath;

/**
 片尾动画资源路径
*/
+ (NSString *)taileaderAnimationPath;

/*
 色度抠图资源路径
 */
+ (NSString *)chromaPath;

/**
 调节资源路径
*/
@optional
+ (NSString *)videoAjustPath;

@end

NS_ASSUME_NONNULL_END
