//
//  CJPayVerifyItemRecogFaceRetry.h
//  CJPay
//
//  Created by 尚怀军 on 2020/8/23.
//

#import "CJPayVerifyItem.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayBDCreateOrderResponse;
@class CJPayOrderConfirmResponse;
@class CJPayGetTicketResponse;
@interface CJPayVerifyItemRecogFaceRetry : CJPayVerifyItem

@property (nonatomic, strong) CJPayGetTicketResponse *getTicketResponse;
@property (nonatomic, weak) UIViewController *referVC;

- (void)failRetryRecogFace;

- (void)pushWithVC:(UIViewController *)vc;

- (void)showLoading:(BOOL)isLoading;

- (void)alertNeedRetryFaceRecogWith:(CJPayOrderConfirmResponse *)response;

- (CJPayBDCreateOrderResponse *)getCreateOrderResponse;

- (void)submitFaceDataWithResponse:(CJPayOrderConfirmResponse *)response
                 getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse
                           sdkData:(NSString *)sdkData;

- (NSString *)getSourceStr;

@end

NS_ASSUME_NONNULL_END
