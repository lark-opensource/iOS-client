//
//  ACCUIAlertProcotol.h
//  Aweme
//
//  Created by haoyipeng on 2021/11/11.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>

typedef void(^ACCTextEditAlertViewCompletionBlock)(NSString *content);

@protocol ACCTextInputAlertViewProtocol <NSObject>

@property (nonatomic, strong, nullable) UILabel *titleLabel;
@property (nonatomic, strong, nullable) UITextField *textField;
@property (nonatomic, copy, nullable) NSString *defaultValue;
@property (nonatomic, copy, nullable) NSString *emptyToast;

@property (nonatomic, assign) NSInteger textMaxLength;

@property (nonatomic, copy) ACCTextEditAlertViewCompletionBlock confirmBlock;
@property (nonatomic, copy) ACCTextEditAlertViewCompletionBlock cancelBlock;

- (void)showOnView:(UIView *)view;
- (void)dismiss;

- (void)setConfirmButtonTitle:(NSString *)title;
- (void)setConfirmButtonEnabled:(BOOL)enabled;

@end

@protocol ACCTextInputAlertProcotol <NSObject>

- (id<ACCTextInputAlertViewProtocol>)inputTextAlertView;

@end

FOUNDATION_STATIC_INLINE id<ACCTextInputAlertProcotol> ACCTextInputAlert() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCTextInputAlertProcotol)];
}
