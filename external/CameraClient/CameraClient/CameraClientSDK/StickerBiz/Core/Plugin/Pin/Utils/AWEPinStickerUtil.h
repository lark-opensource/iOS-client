//
//  AWEPinStickerUtil.h
//  CameraClient
//
//  Created by resober on 2019/12/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEPinStickerUtil : NSObject

/// @see https://bytedance.feishu.cn/docs/doccn4pfHxLsXQ4VtTmu7XbovNb
/// 根据boundingBox以及rotation计算出贴纸实际的区域，判断touchPoint是否在此区域内
/// @param touchPoint 需要判断的点击点
/// @param boundingBox 贴纸等旋转过后4个顶点组成的矩形
/// @param innerRectSize 内部顶点在boundingBox上的矩形的大小
/// @param rotation bbox相对水平线旋转的角度，逆时针旋转为正，单位 **【角度】**
/// @param completion contain touchPoint是否在贴纸area中 trueSize 计算得出的实际贴纸的大小
+ (void)isTouchPointInStickerAreaWithPoint:(CGPoint)touchPoint
                               boundingBox:(CGRect)boundingBox
                             innerRectSize:(CGSize)innerRectSize
                                  rotation:(CGFloat)rotation
                                completion:(void(^)(BOOL contain, CGSize trueSize))completion;

+ (BOOL)isValidRect:(CGRect)rect;

@end

NS_ASSUME_NONNULL_END
