//
//  CJPayVerifyItemRecogFace.h
//  CJPay
//
//  Created by 尚怀军 on 2020/8/23.
//

#import "CJPayVerifyItem.h"
#import "CJPayOrderConfirmResponse.h"
#import "CJPayHalfPageBaseViewController+Biz.h"
#import "CJPayFaceRecogConfigModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayGetTicketResponse;
@class CJPayFaceRecognitionModel;
@interface CJPayVerifyItemRecogFace : CJPayVerifyItem

@property (nonatomic, strong) CJPayGetTicketResponse *getTicketResponse;
@property (nonatomic, copy) NSString *enterFrom;
@property (nonatomic, weak) UIViewController *referVC;
@property (nonatomic, copy) void(^getTicketLoadingBlock)(BOOL isLoading); //getTicket接口Loading样式支持定制

- (void)failRecogFace;

- (void)tryFaceRecogWithResponse:(CJPayOrderConfirmResponse *)orderConfirmResponse;

- (void)pushWithVC:(UIViewController *)vc;

- (void)showLoading:(BOOL)isLoading;

- (CJPayFaceRecognitionModel *)createFaceRecognitionModelOfFullPage:(CJPayOrderConfirmResponse *)response
                                              withGetTicketResponse:(CJPayGetTicketResponse *)getTicketResponse;

- (CJPayFaceRecognitionModel *)createFaceRecognitionModelOfAlert:(CJPayOrderConfirmResponse *)response
                                              withGetTicketResponse:(CJPayGetTicketResponse *)getTicketResponse;

- (CJPayBDCreateOrderResponse *)getCreateOrderResponse;

- (NSString *)getSourceStr;

- (NSDictionary *)confirmRequestParasmWithResponse:(CJPayOrderConfirmResponse *)response
                                 getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse
                                           sdkData:(NSString *)sdkData;

- (void)submitFaceDataWithResponse:(CJPayOrderConfirmResponse *)response
                 getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse
                           sdkData:(NSString *)sdkData;

+ (void)getTicketWithResponse:(CJPayOrderConfirmResponse *)orderConfirmResponse
          createOrderResponse:(CJPayBDCreateOrderResponse *)createOrderResponse
                       source:(NSString *)source
                       fromVC:(UIViewController *)fromVC
                   completion:(void(^)(CJPayFaceRecogSignResult signResult, CJPayGetTicketResponse * _Nonnull getTicketResponse))completionBlock;

- (void)alertNeedFaceRecogWith:(CJPayOrderConfirmResponse *)response
             getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse;

- (void)startFaceRecogWith:(CJPayOrderConfirmResponse *)response
         getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse;

- (void)startSignFaceRecogProtocolWith:(CJPayOrderConfirmResponse *)response
                     getTicketResponse:(CJPayGetTicketResponse *)getTicketResponse;


@end

NS_ASSUME_NONNULL_END
