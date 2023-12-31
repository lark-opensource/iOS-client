//
//  CJPayFaceRecogManager.h
//  Pods
//
//  Created by 尚怀军 on 2022/10/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayFaceRecogConfigModel;
@class CJPayFaceRecogResultModel;
@interface CJPayFaceRecogManager : NSObject

+ (instancetype)sharedInstance;

- (void)startFaceRecogWithConfigModel:(CJPayFaceRecogConfigModel *)faceRecogConfigModel;

/// 调用人脸 + verify_live_detection_result 验证，返回 token 和 resultModel
- (void)startFaceRecogAndVerifyWithParams:(NSDictionary *)params
                                   fromVC:(UIViewController *)fromVC
                             trackerBlock:(void (^)(NSString * _Nonnull event, NSDictionary * _Nonnull params))trackerBlock
                            pagePushBlock:(void (^)(UIViewController * _Nonnull vc, BOOL animated))pagePushBlock
                    getTicketLoadingBlock:(void (^)(BOOL isLoading))getTicketLoadingBlock
                               completion:(void (^)(BOOL success, NSString *token, CJPayFaceRecogResultModel *resultModel))completion;

@end

NS_ASSUME_NONNULL_END
