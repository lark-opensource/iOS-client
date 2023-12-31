//
//  CJPayPasswordView.h
//  Pods
//
//  Created by xutianxi on 2022/8/4.
//

#import <UIKit/UIKit.h>
#import "CJPayUIMacro.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CJPayPassCodeType) {
    CJPayPassCodeTypeSet,
    CJPayPassCodeTypeSetAgain,
    CJPayPassCodeTypeSetAgainAndPay,
    CJPayPassCodeTypePayVerify,
    CJPayPassCodeTypeIndependentBindCardVerify
};

@interface CJPayPassCodePageModel : NSObject

@property (nonatomic, assign) CJPayPassCodeType type;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subTitle;
@property (nonatomic, copy) NSString *btnTitle;

@end

@class CJPaySafeInputView;
@class CJPayStyleErrorLabel;
@class CJPayStyleButton;

@interface CJPayPasswordView : UIView <CJPayBaseLoadingProtocol>

@property (nonatomic, strong, readonly) CJPaySafeInputView *safeInputView;
@property (nonatomic, strong, readonly) CJPayStyleErrorLabel *errorLabel;
@property (nonatomic, strong, readonly) CJPayStyleButton *completeButton;
@property (nonatomic, copy) NSString *subTitle;

@property (nonatomic, copy) void(^forgetButtonTappedBlock)(void);
@property (nonatomic, copy) void(^completeButtonTappedBlock)(void);

- (instancetype)initWithFrame:(CGRect)frame;
- (void)updateWithPassCodeType:(CJPayPassCodeType)type;
- (void)updateWithPassCodeType:(CJPayPassCodeType)type
                         title:(NSString *)title
                      subTitle:(NSString *)subTitle;

@end

NS_ASSUME_NONNULL_END
