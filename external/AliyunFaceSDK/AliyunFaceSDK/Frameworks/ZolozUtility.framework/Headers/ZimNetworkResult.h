//
//  ZimNetworkResult.h
//  AliyunIdentityManager
//
//  Created by sanyuan.he on 2020/2/4.
//  Copyright © 2020 Alipay. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ZimAliCloudInitResponse.h"
NS_ASSUME_NONNULL_BEGIN

@interface ZimNetworkResult : NSObject
@property (nonatomic,strong)ZimAliCloudInitResponse* ResultObject;
@property (nonatomic,strong)NSString* RequestId;
@property (nonatomic,strong)NSString* Code;
@property (nonatomic,strong)NSString* Success;
@property (nonatomic,strong)NSString* Message;

@end

NS_ASSUME_NONNULL_END
