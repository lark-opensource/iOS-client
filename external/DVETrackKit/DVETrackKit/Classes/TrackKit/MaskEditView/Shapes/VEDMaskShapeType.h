//
//  VEDMaskShapeType.h
//  NLEEditor
//
//  Created by bytedance on 2021/4/11.
//

#import <Foundation/Foundation.h>

/// 蒙版类型
// line 线性
// mirror 镜像
// circle 圆形
// rectangle 矩形
// geometric_shape 支持通用图形（心形、五角星）

typedef NS_ENUM(NSInteger, VEDMaskShapeType) {
    VEDMaskShapeTypeNone = 0,
    VEDMaskShapeTypeLine,
    VEDMaskShapeTypeMirror,
    VEDMaskShapeTypeCircle,
    VEDMaskShapeTypeRectangle,
    VEDMaskShapeTypeGeometric
   
};

