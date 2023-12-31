//
//  ACCPropLoadedView.h
//  AWEStudioService-Pods-Aweme
//

#import <UIKit/UIKit.h>

@interface ACCPropLoadedView : UIView

@property (nonatomic, assign, readonly) BOOL isShowing;

- (void)startLoadingWithTitle:(nullable NSString *)title onView:(nullable UIView *)view closeBlock:(nullable dispatch_block_t)closeBlock;

- (void)stopLoading;

- (void)updateProgressTitle:(nullable NSString *)title;

@end

