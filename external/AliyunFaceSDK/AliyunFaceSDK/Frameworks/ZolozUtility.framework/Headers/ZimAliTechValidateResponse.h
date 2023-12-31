//
//  ZimValidateResponse.h
//  ZolozIdentityManager
//
//  Created by richard on 27/08/2017.
//  Copyright © 2017 Alipay. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZimAliTechValidateResponse;

#ifndef SUPPORT_PB
@interface ZimAliTechValidateResponse:NSObject
@property (nonatomic) SInt32 validation_ret_code ;
@property (nonatomic) SInt32 product_ret_code ;
@property (nonatomic) BOOL has_next ;
@property (nonatomic,strong) NSString* next_protocol ;
@property (nonatomic,strong) NSDictionary* ext_params ;
@property (nonatomic,strong) NSString* ret_code_sub ;
@property (nonatomic,strong) NSString* ret_message_sub ;
+ (Class)ext_paramsElementClass;
@end

#else
#endif


