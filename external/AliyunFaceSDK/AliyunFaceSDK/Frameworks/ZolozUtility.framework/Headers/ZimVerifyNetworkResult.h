//
//  ZimVerifyNetworkResult.h
//  AliyunIdentityManager
//
//  Created by sanyuan.he on 2020/2/4.
//  Copyright © 2020 Alipay. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ZimAliCloudValidateResponse.h"
NS_ASSUME_NONNULL_BEGIN

@interface ZimVerifyNetworkResult : NSObject
@property(nonatomic,strong)ZimAliCloudValidateResponse *ResultObject;
@property(nonatomic,strong)NSString * RequestId;
@property(nonatomic,strong)NSString * Code;

@end

NS_ASSUME_NONNULL_END
