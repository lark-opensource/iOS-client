//
//  CJPayForgetPwdOptController.h
//  Aweme
//
//  Created by 尚怀军 on 2022/12/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class CJPayBDCreateOrderResponse;
@interface CJPayForgetPwdOptController : NSObject

@property (nonatomic, strong) CJPayBDCreateOrderResponse *response;
@property (nonatomic, copy) void(^faceRecogPayBlock)(NSString *);
@property (nonatomic, copy, nullable) void(^trackerBlock)(NSString *event, NSDictionary *params);

- (void)forgetPwdWithSourceVC:(UIViewController *)sourceVC;
- (void)pwdLockRecommendFaceVerify:(UIViewController *)sourceVC
                             title:(NSString *)title;
- (void)pwdLockRecommendFacePay:(UIViewController *)sourceVC
                          title:(NSString *)title;

- (BOOL)isNeedFacePay;
- (BOOL)isNeedFaceVerify;

@end

NS_ASSUME_NONNULL_END
