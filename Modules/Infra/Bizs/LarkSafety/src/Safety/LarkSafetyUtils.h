//
//  LarkSafetyUtils.h
//  LarkApp
//
//  Created by KT on 2019/7/18.
//

#import <UIKit/UIKit.h>

// 防止exit函数被hook, 逆向阻止App退出
void Lark_ExitApp(void);

NS_ASSUME_NONNULL_BEGIN

@interface LarkSafetyUtils : NSObject
/**
 模糊Image (比UIBlurEffect有更多控制)

 @param image 传入需要被模糊的图片
 @param radius 模糊半径
 @param iterations 迭代次数
 @param tintColor Color
 @return 模糊后Image
 */
+ (UIImage *)blurredImage:(UIImage *)image
               withRadius:(CGFloat)radius
               iterations:(NSUInteger)iterations
                tintColor:(UIColor *)tintColor;
@end

NS_ASSUME_NONNULL_END
