//
//  LVGeometryTool.h
//  LVTemplate
//
//  Created by luochaojing on 2020/2/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LVGeometryTool : NSObject

/// 居中填充在rect中
///
/// - Parameter rect: 包含的rect
/// - Returns: 自己在rect中的位置
+ (CGRect)lv_scaleAspectFit:(CGSize)sourceSize toRect:(CGRect)toRect;


/// 尺寸短边对齐size，如果小于size则放大到size
///
/// - Parameter size: 限制size
/// - Returns: 适配后的size
+ (CGSize)lv_scaleAspectFitToMinSize:(CGSize)sourceSize toMinSize:(CGSize)toMinSize;

+ (CGSize)lv_limitMinSize:(CGSize)size maxSize:(CGSize)minSize;

+ (CGSize)lv_limitMaxSize:(CGSize)size maxSize:(CGSize)maxSize;

@end

NS_ASSUME_NONNULL_END
