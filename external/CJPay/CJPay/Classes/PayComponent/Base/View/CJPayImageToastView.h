//
//  CJPayImageToastView.h
//  CJPaySandBox-1
//
//  Created by youerwei on 2023/2/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayImageToastView : UIView

+ (void)toastImage:(NSString *)imageName title:(NSString *)title duration:(NSTimeInterval)duration inWindow:(nullable UIWindow *)window;

@end

NS_ASSUME_NONNULL_END
