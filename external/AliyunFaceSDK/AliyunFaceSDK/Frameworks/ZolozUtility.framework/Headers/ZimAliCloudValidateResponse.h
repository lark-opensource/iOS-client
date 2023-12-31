//
//  ZimValidateResponse.h
//  ZolozIdentityManager
//
//  Created by richard on 27/08/2017.
//  Copyright © 2017 Alipay. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZimAliCloudValidateResponse;
@class PBMapStringString;

#ifndef SUPPORT_PB
@interface ZimAliCloudValidateResponse:NSObject
@property (nonatomic,strong) NSString* ValidationRetCode;//validationRetCode ;
@property (nonatomic,strong) NSString* ProductRetCode;//SInt32 productRetCode ;
@property (nonatomic,strong) NSString* HasNext;//BOOL pb_hasNext ;
@property (nonatomic,strong) NSString* nextProtocol ;
@property (nonatomic,strong) NSString* ExtParams;//extParams ;
@property (nonatomic,strong) NSString* RetCodeSub;//retCodeSub ;
@property (nonatomic,strong) NSString* RetMessageSub;//retMessageSub ;
//+ (Class)ExtParamsElementClass;
@end

#else
#endif


