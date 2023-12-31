//
//  ACCMusicTextEditAlertView.h
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/7/12.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef BOOL(^ACCTextEditConfirmAction)(NSString *content);

@interface ACCMusicTextEditAlertView : UIView

@property (nonatomic, copy) ACCTextEditConfirmAction confirmAction;
@property (nonatomic, copy) dispatch_block_t cancelAction;

- (instancetype)initWithFrame:(CGRect)frame
                    withTitle:(nullable NSString *)title
           confirmButtonTitle:(nullable NSString *)confirmTitle
            cancelButtonTitle:(nullable NSString *)cancelTitle
                 confirmBlock:(ACCTextEditConfirmAction)actionBlock
                  cancelBlock:(nullable dispatch_block_t)cancelBlock;

- (void)showOnView:(UIView *)view;

+ (void)showAlertOnView:(UIView *)view
              withTitle:(nullable NSString *)title
     confirmButtonTitle:(nullable NSString *)confirmTitle
      cancelButtonTitle:(nullable NSString *)cancelTitle
           confirmBlock:(ACCTextEditConfirmAction)actionBlock
            cancelBlock:(nullable dispatch_block_t)cancelBlock;

@end

NS_ASSUME_NONNULL_END
