//
//  ACCLoadingViewProtocol.h
//  CameraClient
//
//  Created by lxp on 2019/11/19.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ACCProgressLoadingViewType) {
    ACCProgressLoadingViewTypeNormal = 0,
    ACCProgressLoadingViewTypeProgress, // There is progress
    ACCProgressLoadingViewTypeHorizon,
};

@protocol ACCLoadingViewProtocol <NSObject>

- (void)startAnimating;
- (void)stopAnimating;

- (void)dismiss;
- (void)dismissWithAnimated:(BOOL)animated;

@end

@protocol ACCTextLoadingViewProtcol <ACCLoadingViewProtocol>

- (void)showCloseBtn:(BOOL)visible closeBlock:(dispatch_block_t)closeBlock;

- (void)allowUserInteraction:(BOOL)allow;

- (UIView *)hudView;

- (void)acc_updateTitle:(nullable NSString *)title;

@end

@protocol ACCProcessViewProtcol <ACCLoadingViewProtocol>

@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) BOOL cancelable;
@property (nonatomic, copy) dispatch_block_t cancelBlock;

- (void)showAnimated:(BOOL)animated;
- (void)showAnimated:(BOOL)animated afterDelay:(NSTimeInterval)delay;
- (void)showOnView:(UIView *)view animated:(BOOL)animated;
- (void)dismissAnimated:(BOOL)animated;
- (void)allowUserInteraction:(BOOL)allow;

@end

@protocol ACCLoadingProtocol <NSObject>

#pragma mark - Simple Loading
+ (UIView<ACCLoadingViewProtocol> *)loadingView;

+ (UIView<ACCTextLoadingViewProtcol> *)textLoadingView;

+ (UIView<ACCLoadingViewProtocol> *)loadingViewUnbackground;

+ (UIView<ACCLoadingViewProtocol> *)showLoadingOnWindow;

+ (UIView<ACCLoadingViewProtocol> *)showLoadingOnView:(UIView *)view;

+ (UIView<ACCLoadingViewProtocol> *)showLoadingAndDisableUserInteractionOnView:(UIView *)view;

#pragma mark - Text Loading
+ (UIView<ACCTextLoadingViewProtcol> *)showTextLoadingOnView:(UIView *)view title:(nullable NSString *)title animated:(BOOL)animated;

+ (UIView<ACCTextLoadingViewProtcol> *)showWindowLoadingWithTitle:(NSString *)title animated:(BOOL)animated;

+ (void)dismissWindowLoadingWithAnimated:(BOOL)animated;

+ (void)dismissWindowLoading;

#pragma mark - Process
+ (UIView<ACCProcessViewProtcol> *)showProgressOnView:(UIView *)view title:(NSString *)title animated:(BOOL)animated type:(ACCProgressLoadingViewType)type;

+ (UIView<ACCProcessViewProtcol> *)showProcessOnView:(UIView *)view title:(NSString *)title animated:(BOOL)animated;

+ (UIView<ACCProcessViewProtcol> *)progressWithTitle:(NSString *)title;

+ (UIView<ACCProcessViewProtcol> *)showNormalProcessOnView:(UIView *)view title:(NSString *)title animated:(BOOL)animated;

@optional

+ (UIView<ACCTextLoadingViewProtcol> *)showWindowLoadingWithTitle:(NSString *)title animated:(BOOL)animated afterDelay:(NSTimeInterval)delay;

@end

FOUNDATION_STATIC_INLINE Class<ACCLoadingProtocol> ACCLoading() {
    return [[ACCBaseServiceProvider() resolveObject:@protocol(ACCLoadingProtocol)] class];
}

NS_ASSUME_NONNULL_END
