//
//  CJPaySkipPwdConfirmModel.h
//  Pods
//
//  Created by youerwei on 2021/7/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const CJPaySkipPwdConfirmForbidKey;
extern NSString * const CJPaySkipPwdConfirmTempForbidKey;
extern NSString * const CJPaySkipPwdCheckBoxNotFirstUpload;

@class CJPayBDCreateOrderResponse;
@class CJPayBaseVerifyManager;
@class CJPaySecondaryConfirmInfoModel;
@interface CJPaySkipPwdConfirmModel : NSObject

@property (nonatomic, strong) CJPayBDCreateOrderResponse *createOrderResponse;
@property (nonatomic, copy) void(^confirmBlock)(void);
@property (nonatomic, copy) void(^closeCompletionBlock)(void);
@property (nonatomic, copy) void(^backCompletionBlock)(void);
@property (nonatomic, copy) void(^dismissSelfWithCompletionBlock)(void);
@property (nonatomic, copy) void(^checkboxClickBlock)(BOOL);
@property (nonatomic, copy) void(^otherVerifyCompletionBlock)(void);
@property (nonatomic, strong) CJPaySecondaryConfirmInfoModel *confirmInfo;

@property (nonatomic, weak) CJPayBaseVerifyManager *verifyManager;

@end

NS_ASSUME_NONNULL_END
