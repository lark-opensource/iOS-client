//
//  ACCMusicSimpleAlertView.h
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/7/12.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCMusicSimpleAlertView : UIView

- (instancetype)initWithFrame:(CGRect)frame
                    withTitle:(nullable NSString *)title
           confirmButtonTitle:(nullable NSString *)confirmTitle
            cancelButtonTitle:(nullable NSString *)cancelTitle
                 confirmBlock:(nullable dispatch_block_t)actionBlock
                  cancelBlock:(nullable dispatch_block_t)cancelBlock;

- (void)showOnView:(UIView *)view;

+ (void)showAlertOnView:(UIView *)view
              withTitle:(nullable NSString *)title
     confirmButtonTitle:(nullable NSString *)confirmTitle
      cancelButtonTitle:(nullable NSString *)cancelTitle
           confirmBlock:(nullable dispatch_block_t)actionBlock
            cancelBlock:(nullable dispatch_block_t)cancelBlock;

@end

NS_ASSUME_NONNULL_END
