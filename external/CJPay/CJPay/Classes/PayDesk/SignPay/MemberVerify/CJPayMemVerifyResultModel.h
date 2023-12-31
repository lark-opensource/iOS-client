//
//  CJPayMemVerifyResultModel.h
//  CJPay-1ab6fc20
//
//  Created by wangxiaohong on 2022/9/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CJPayMemVerifyResultType) {
    CJPayMemVerifyResultTypeCancel,  // 取消验证
    CJPayMemVerifyResultTypeFinish,  // 完成验证
};

@interface CJPayMemVerifyResultModel : NSObject

@property (nonatomic, assign) CJPayMemVerifyResultType resultType;
@property (nonatomic, weak) UIViewController *verifyVC; //进行验证的vc，为nil代表此验证方式无页面
@property (nonatomic, copy) NSDictionary *paramsDict;//各验证方式验证完成携带的参数，用于验证完成后续操作（比如验密等）
@property (nonatomic, copy) NSDictionary *extraData; //预留字段，用来传递其他参数

@end

NS_ASSUME_NONNULL_END
