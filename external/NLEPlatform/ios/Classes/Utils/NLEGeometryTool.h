//
//  NLEGeometryTool.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/3/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NLEGeometryTool : NSObject

/// 居中填充在rect中
///
/// - Parameter rect: 包含的rect
/// - Returns: 自己在rect中的位置
+ (CGRect)nle_scaleAspectFit:(CGSize)sourceSize toRect:(CGRect)toRect;


/// 尺寸短边对齐size，如果小于size则放大到size
///
/// - Parameter size: 限制size
/// - Returns: 适配后的size
+ (CGSize)nle_scaleAspectFitToMinSize:(CGSize)sourceSize toMinSize:(CGSize)toMinSize;

+ (CGSize)nle_limitMinSize:(CGSize)size maxSize:(CGSize)minSize;

+ (CGSize)nle_limitMaxSize:(CGSize)size maxSize:(CGSize)maxSize;

@end

NS_ASSUME_NONNULL_END
