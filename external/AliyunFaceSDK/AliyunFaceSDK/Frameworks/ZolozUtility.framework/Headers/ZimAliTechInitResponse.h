//
//  ZimInitResponse.h
//  ZolozIdentityManager
//
//  Created by richard on 27/08/2017.
//  Copyright © 2017 Alipay. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZimAliTechInitResponse;


@interface ZimAliTechInitResponse:NSObject
@property (nonatomic) SInt32 ret_code ;
@property (nonatomic,strong) NSString* message ;
@property (nonatomic,strong) NSString* zim_id ;
@property (nonatomic,strong) NSString* protocol ;
@property (nonatomic,strong) NSDictionary* ext_params ;
@property (nonatomic,strong) NSString* ret_code_sub ;
@property (nonatomic,strong) NSString* ret_msg ;
@property (nonatomic,strong) NSString* req_msg_id ;
@property (nonatomic,strong) NSString* result_code ;
@property (nonatomic,strong) NSString* result_msg ;
+ (Class)ext_paramsElementClass;
@end

