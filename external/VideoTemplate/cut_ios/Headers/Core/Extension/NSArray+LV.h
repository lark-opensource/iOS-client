//
//  NSArray+LV.h
//  LVTemplate
//
//  Created by iRo on 2019/9/3.
//

#import <Foundation/Foundation.h>
#import "LVModelType.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (LV)

/// 默认裁剪接口
/// @param size                   用户选择的视频
/// @param originalSize 原草稿视频片段尺寸。在feed里或者草稿初始化的值
/// @param alignMode       对齐的方式
+ (NSArray<NSValue *> *)defaultCropWithSize:(CGSize)size originalSize:(CGSize)originalSize alignMode:(LVMutableConfigAlignMode)alignMode;

@end

NS_ASSUME_NONNULL_END
