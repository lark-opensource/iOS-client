//
//  BDUGShareLoadingView.h
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/6/6.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, BDUGShareLoadingViewStatus) {
    BDUGShareLoadingViewStatusStop,
    BDUGShareLoadingViewStatusAnimating,
    BDUGShareLoadingViewStatusPaused,
};

@interface BDUGShareLoadingView : UIView

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) BOOL cancelable;
@property (nonatomic, assign, readonly) BDUGShareLoadingViewStatus status;
@property (nonatomic, copy) dispatch_block_t cancelBlock;

- (instancetype)initWithTitle:(NSString *)title;
- (void)showOnView:(UIView *)view animated:(BOOL)animated;
- (void)showAnimated:(BOOL)animated;
- (void)showAnimated:(BOOL)animated afterDelay:(NSTimeInterval)delay;
- (void)dismissAnimated:(BOOL)animated;
- (void)allowUserInteraction:(BOOL)allow;

@end
