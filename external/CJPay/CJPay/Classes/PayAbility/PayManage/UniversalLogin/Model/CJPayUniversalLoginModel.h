//
//  UniversalLoginModel.h
//  CJPay
//
//  Created by 徐波 on 2020/4/13.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "CJPayUserInfo.h"
#import "CJPayUserInfoPassModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayUniversalLoginModel : JSONModel

//用户信息
@property (nonatomic, strong) CJPayUserInfo *userInfo;
//统一登录参数
@property (nonatomic, strong) CJPayUserInfoPassModel *passModel;
@property (nonatomic, copy) NSString *code;
@property (nonatomic, strong) NSError *error;


@end

NS_ASSUME_NONNULL_END
