//
//  ACCToastProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/8/1.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCToastProtocol <NSObject>

@optional

- (void)show:(NSString *)message;

- (void)showSuccess:(NSString *)message;

- (void)showError:(NSString *)message;

- (void)show:(NSString *)message onView:(UIView *)view;

- (void)showError:(NSString *)message onView:(UIView *)view;

- (void)showSuccess:(NSString *)message onView:(UIView *)view;

- (void)showMultiLine:(NSString *)message onView:(UIView *)view;

#pragma mark -

- (void)showToast:(NSString *)message;

- (void)dismissToast;

#pragma mark - common toast

- (void)showNetWeak;

#pragma mark - Business
- (void)showDraftPublishAndForceUseLocal:(BOOL)forceUseLocal;

#pragma mark - globalTips
- (void)showAtTooMore;

@end

FOUNDATION_STATIC_INLINE id<ACCToastProtocol> ACCToast() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCToastProtocol)];
}

NS_ASSUME_NONNULL_END
