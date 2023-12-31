//
//  UIView+DYOpen.h
//  DouyinOpenPlatformSDK
//
//  Created by arvitwu on 2022/9/14.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (DYOpen)

#pragma mark - Auto Layout
- (void)dyopen_removeAllConstraints;

#pragma mark - Responder
- (nullable UIView *)dyopen_findFirstResponder;
- (nullable UIViewController *)dyopen_viewController;

#pragma mark - Subview
- (void)dyopen_removeAllSubviews;
- (CGRect)dyopen_calcMiniFitFrame;
- (CGRect)dyopen_calcMiniFitFrameIgnoreHiden:(BOOL)ignoreHiden;
- (void)dyopen_resizeToFitSubviews;

@end

NS_ASSUME_NONNULL_END
