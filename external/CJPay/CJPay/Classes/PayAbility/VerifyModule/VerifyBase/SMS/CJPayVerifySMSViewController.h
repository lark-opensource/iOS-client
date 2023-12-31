//
//  CJPayVerifySMSViewController.h
//  CJPay
//
//  Created by liyu on 2020/3/24.
//

#import "CJPayFullPageBaseViewController.h"
#import "CJPayVerifySMSVCProtocol.h"
#import "CJPayUIMacro.h"

@class CJPayDefaultChannelShowConfig;

NS_ASSUME_NONNULL_BEGIN
@class CJPayVerifySMSInputModule;
@class CJPayStyleErrorLabel;
@interface CJPayVerifySMSViewController : CJPayFullPageBaseViewController <CJPayVerifySMSVCProtocol,CJPayBaseLoadingProtocol>

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) CJPayVerifySMSInputModule *inputModule;
@property (nonatomic, strong) CJPayStyleErrorLabel *errorLabel;
@property (nonatomic, assign) BOOL sendSMSLock;
@property (nonatomic, assign) NSUInteger trackerInputTimes;

- (void)sendSMSWithCompletion:(void (^)(void))completion;
- (void)inputModule:(CJPayVerifySMSInputModule *)inputModule completeInputWithText:(NSString *)text;
- (void)trackWithEventName:(NSString *)eventName params:(NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END
