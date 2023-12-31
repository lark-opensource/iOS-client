//
//  NLEStyCanvas+iOS.h
//  Pods
//
//  Created by bytedance on 2020/12/8.
//

#ifndef NLEStyCanvas_iOS_h
#define NLEStyCanvas_iOS_h
#import <Foundation/Foundation.h>
#import "NLENode+iOS.h"
#import "NLENativeDefine.h"
#import "NLEResourceNode+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLEStyCanvas_OC : NLENode_OC

@property (nonatomic, assign) uint32_t      borderColor;
@property (nonatomic, assign) uint32_t      borderWidth;

/// 画布类型 默认颜色
@property (nonatomic, assign) NLECanvasType canvasType;

/// 画布颜色 type=COLOR 时，此字段才会生效，ARGB格式 默认黑色
@property (nonatomic, assign) uint32_t      color;

/// 画布背景模糊半径 type=VIDEO_FRAME 时，此字段才生效；模糊程度 1-14档，0为不模糊；默认 0
@property (nonatomic, assign) float blurRadius;

/// 画布渐变起始颜色 type=GRADIENT_COLOR 时，此字段才会生效
@property (nonatomic, assign) uint32_t startColor;

/// 画布渐变结束颜色 type=GRADIENT_COLOR 时，此字段才会生效
@property (nonatomic, assign) uint32_t endColor;

/// 抗锯齿 - 有性能损耗，默认 false
@property (nonatomic, assign) bool antialiasing;

/// 画布背景图 type=IMAGE 时，此字段才会生效
@property (nonatomic, strong) NLEResourceNode_OC *imageSource;

@end

NS_ASSUME_NONNULL_END

#endif /* NLEStyCanvas_iOS_h */
