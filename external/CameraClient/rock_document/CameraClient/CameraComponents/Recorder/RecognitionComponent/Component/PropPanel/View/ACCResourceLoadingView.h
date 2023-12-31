//
//  ACCResourceLoadingView.h
//  AWEStudioService-Pods-Aweme
//
//  Created by liujinze on 2021/3/29.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCResourceLoadingView : UIView

@property (nonatomic, assign, readonly) BOOL isShowing;

- (void)startLoadingWithTitle:(NSString *)title onView:(UIView *)view closeBlock:(dispatch_block_t)closeBlock;

- (void)stopLoading;

- (void)updateProgressTitle:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
