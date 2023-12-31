//
//  BDUGDownloadProgressView.h
//  NewsLite
//
//  Created by 杨阳 on 2019/4/28.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, BDUGProgressLoadingViewType) {
    BDUGProgressLoadingViewTypeNormal = 0,
    BDUGProgressLoadingViewTypeProgress, //有进度
    BDUGProgressLoadingViewTypeHorizon,
};

typedef NS_ENUM(NSInteger, BDUGProgressLoadingViewStatus) {
    BDUGProgressLoadingViewStatusStop,
    BDUGProgressLoadingViewStatusAnimating,
    BDUGProgressLoadingViewStatusPaused,
};

@interface BDUGDownloadProgressView : UIView

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign, readonly) BDUGProgressLoadingViewStatus status;
@property (nonatomic, assign) BOOL cancelable;
@property (nonatomic, copy) dispatch_block_t cancelBlock;

- (instancetype)initWithType:(BDUGProgressLoadingViewType)type title:(NSString *)title;
- (void)showOnView:(UIView *)view animated:(BOOL)animated;
- (void)showAnimated:(BOOL)animated;
- (void)showAnimated:(BOOL)animated afterDelay:(NSTimeInterval)delay;
- (void)dismissAnimated:(BOOL)animated;
- (void)allowUserInteraction:(BOOL)allow;

@end
