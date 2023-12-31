//
//  CJPayHalfScreenSMSVerificationH5Presenter.h
//  CJPay
//
//  Created by liyu on 2020/7/12.
//

#import "CJPayHalfScreenSMSVerificationViewController.h"

@class CJPaySMSVerificationRequestModel;

@interface CJPayHalfScreenSMSVerificationH5Presenter : NSObject <CJPayHalfScreenSMSVerificationViewInterface>

- (instancetype)initWithVC:(CJPayHalfScreenSMSVerificationViewController *)vc
                     model:(CJPaySMSVerificationRequestModel *)model
              sendingBlock:(void(^)(NSInteger code, NSString *type, NSString *data))sendingBlock;

- (void)onReceiveH5Message:(NSDictionary *)message;

@end
