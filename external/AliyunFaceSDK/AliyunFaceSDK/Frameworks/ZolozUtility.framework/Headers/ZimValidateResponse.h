//
//  ZimValidateResponse.h
//  ZolozIdentityManager
//
//  Created by richard on 27/08/2017.
//  Copyright © 2017 Alipay. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZimValidateResponse;
@class PBMapStringString;

typedef enum : NSUInteger {
    ZIMValidationSuccess = 1000,
    ZIMValidationInternalError = 1001,
    ZIMValidationFail = 2006,
    ZIMValidationContinue = 3002,// continue launch next product
    ZIMValidationRetry = 3001,//liveness fail or match fail, retry current product
    ZIMValidation2FA = 3003, // continue with 2fa, now only sms
    ZIMValidationOSSUploadFail = 3008,
} ZimValidationRetCode;

#ifndef SUPPORT_PB
@interface ZimValidateResponse:NSObject
@property (nonatomic) SInt32 validationRetCode ;
@property (nonatomic) SInt32 productRetCode ;
@property (nonatomic) BOOL pb_hasNext ;
@property (nonatomic,strong) NSString* nextProtocol ;
@property (nonatomic,strong) NSDictionary* extParams ;
@property (nonatomic,strong) NSString* retCodeSub ;
@property (nonatomic,strong) NSString* retMessageSub ;
+ (Class)extParamsElementClass;
@end

#else
#import <APProtocolBuffers/ProtocolBuffers.h>

@interface ZimValidateResponse : APDPBGeneratedMessage

@property (readonly) BOOL hasValidationRetCode;
@property (readonly) BOOL hasProductRetCode;
@property (readonly) BOOL hasPb_hasNext;
@property (readonly) BOOL hasNextProtocol;
@property (readonly) BOOL hasExtParams;

@property (nonatomic) SInt32 validationRetCode ;
@property (nonatomic) SInt32 productRetCode ;
@property (nonatomic) BOOL pb_hasNext ;
@property (nonatomic,strong) NSString* nextProtocol ;
@property (nonatomic,strong) PBMapStringString* extParams ;
@property (nonatomic,strong) NSString* retCodeSub ;
@property (nonatomic,strong) NSString* retMessageSub;
@end
#endif


