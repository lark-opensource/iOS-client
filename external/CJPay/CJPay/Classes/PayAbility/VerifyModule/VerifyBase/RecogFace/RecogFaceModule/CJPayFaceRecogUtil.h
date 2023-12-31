//
//  CJPayFaceRecogUtil.h
//  Pods
//
//  Created by 尚怀军 on 2022/10/25.
//

#import <Foundation/Foundation.h>
#import "CJPayFaceRecogConfigModel.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const CJPayFaceRecogAlertPopUpViewKey;

@class CJPayOrderConfirmResponse;
@class CJPayBDCreateOrderResponse;
@class CJPayGetTicketResponse;
@class CJPayFaceRecogConfigModel;
@class CJPayFaceRecognitionModel;
@interface CJPayFaceRecogUtil : NSObject

+ (void)asyncUploadFaceVideoWithAppId:(NSString *)appId
                           merchantId:(NSString *)merchantId
                            videoPath:(NSString *)videoPath;

+ (void)getTicketWithResponse:(CJPayOrderConfirmResponse *)orderConfirmResponse
          createOrderResponse:(CJPayBDCreateOrderResponse *)createOrderResponse
                       source:(NSString *)source
                       fromVC:(UIViewController *)fromVC
                   completion:(void(^)(CJPayFaceRecogSignResult signResult, CJPayGetTicketResponse * _Nonnull getTicketResponse))completionBlock;

+ (void)getTicketWithConfigModel:(CJPayFaceRecogConfigModel *)faceRecogConfigModel
                      completion:(void(^)(CJPayFaceRecogSignResult signResult, CJPayGetTicketResponse * _Nonnull getTicketResponse))completionBlock;

+ (CJPayFaceRecognitionModel *)createFullScreenSignPageModelWithResponse:(CJPayGetTicketResponse *)getTicketResponse
                                                    faceRecogConfigModel:(CJPayFaceRecogConfigModel *)faceRecogConfigModel;

+ (CJPayFaceRecognitionModel *)createFaceRecogAlertModelWithResponse:(CJPayGetTicketResponse *)getTicketResponse
                                                faceRecogConfigModel:(CJPayFaceRecogConfigModel *)faceRecogConfigModel;

+ (void)tryPoptoTopHalfVC:(UIViewController *)referVC;

@end

NS_ASSUME_NONNULL_END
