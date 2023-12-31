//
//  ZimInitResponse.h
//  ZolozIdentityManager
//
//  Created by richard on 27/08/2017.
//  Copyright © 2017 Alipay. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZimAliCloudInitResponse;
@class PBMapStringString;

#ifndef SUPPORT_PB

@interface ZimAliCloudInitResponse: NSObject
@property (nonatomic,strong) NSString* AccessKeyId;//retMessageSub ;
@property (nonatomic,strong) NSString* RetMessageSub;//retMessageSub ;
@property (nonatomic,strong) NSString* BucketName;//retMessageSub ;
@property (nonatomic,strong) NSString* FileNamePrefix;//retMessageSub ;
@property (nonatomic,strong) NSString* OssEndPoint;//retMessageSub ;
@property (nonatomic,strong) NSString* ExtParams;//extParams ;
@property (nonatomic,strong) NSString* RetCodeSub;//retMessageSub ;
@property (nonatomic,strong) NSString* Message;//retMessageSub ;
@property (nonatomic,strong) NSString* RetCode;//retMessageSub ;
@property (nonatomic,strong) NSString* CertifyId;//retMessageSub ;
@property (nonatomic,strong) NSString* SecurityToken;//retMessageSub ;
@property (nonatomic,strong) NSString* Protocol;//retMessageSub ;
@property (nonatomic,strong) NSString* AccessKeySecret;//retMessageSub ;

//+ (Class)ExtParamsElementClass;
@end

#else
#import <APProtocolBuffers/ProtocolBuffers.h>

@interface ZimAliCloudInitResponse : APDPBGeneratedMessage

@property (readonly) BOOL hasRetCode;
@property (readonly) BOOL hasMessage;
@property (readonly) BOOL hasZimId;
@property (readonly) BOOL hasProtocol;
@property (readonly) BOOL hasExtParams;

@property (nonatomic) SInt32 retCode ;
@property (nonatomic,strong) NSString* message ;
@property (nonatomic,strong) NSString* zimId ;
@property (nonatomic,strong) NSString* protocol ;
@property (nonatomic,strong) PBMapStringString* extParams ;
@property (nonatomic,strong) NSString* retCodeSub ;
@property (nonatomic,strong) NSString* retMessageSub ;
@end
#endif
