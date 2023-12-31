//
//  SAMKeyChain+CJPay.m
//  CJPay
//
//  Created by 王新华 on 2019/4/8.
//

#import "SAMKeychain+CJPay.h"

@implementation SAMKeychain(CJPay)

+ (BOOL)cj_save:(NSString *)content forKey:(NSString *)key {
    BOOL cacheSuccess = [SAMKeychain setPassword:content forService:key account:@"CJPay"];
    return cacheSuccess;
}

+ (nullable NSString *)cj_stringForKey:(NSString *)key {
    return [SAMKeychain passwordForService:key account:@"CJPay"];
}

+ (BOOL)cj_deleteForKey:(NSString *)key {
    BOOL deleteSuccess = [SAMKeychain deletePasswordForService:key account:@"CJPay"];
    return deleteSuccess;
}


@end
