//
//  ACCBarItemToastView.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/5/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCBarItemToastView : UIView

+ (void)showOnAnchorBarItem:(UIView *)barItem withContent:(NSString *)content dismissBlock:(nullable dispatch_block_t)dismissBlock;

@end

NS_ASSUME_NONNULL_END
