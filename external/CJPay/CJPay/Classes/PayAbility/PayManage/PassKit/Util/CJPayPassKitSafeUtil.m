//
//  CJPayPassKitSafeUtil.m
//  CJPay
//
//  Created by 张海阳 on 2019/6/25.
//

#import "CJPayPassKitSafeUtil.h"
#import "CJPaySDKMacro.h"

@implementation CJPayPassKitSafeUtil

+ (BOOL)checkStringSecureEnough:(NSString *)string {
    if (string.length == 0) {return NO;}
    if (string.length < 6) {return NO;}

    __block BOOL same = YES;
    __block BOOL near = YES;
    __block NSString *mark = @"";
    [string enumerateSubstringsInRange:NSMakeRange(0, string.length) options:NSStringEnumerationByComposedCharacterSequences
                            usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                if (mark.length == 0) {
                                    mark = [substring copy];
                                } else {
                                    NSInteger integer = [substring integerValue];
                                    NSInteger intMark = [mark integerValue];

                                    if (![mark isEqualToString:substring]) {
                                        same = NO;
                                    }
                                    if (![@[@(intMark + 1), @(intMark - 1)] containsObject:@(integer)]) {
                                        near = NO;
                                    }

                                    mark = [substring copy];
                                }
                            }];

    return !(same || near);
}

+ (NSDictionary *)pMemberSecureRequestParams:(NSDictionary *)contentDic {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic addEntriesFromDictionary:[CJPaySafeManager secureInfo]];
    NSMutableArray *fields = [NSMutableArray array];
    if ([contentDic valueForKeyPath:@"enc_params.name"]) {
        [fields addObject:@"enc_params.name"];
    }
    if ([contentDic valueForKeyPath:@"enc_params.mobile"]) {
        [fields addObject:@"enc_params.mobile"];
    }
    if ([contentDic valueForKeyPath:@"enc_params.card_no"]) {
        [fields addObject:@"enc_params.card_no"];
    }
    if ([contentDic valueForKeyPath:@"enc_params.identity_code"]) {
        [fields addObject:@"enc_params.identity_code"];
    }
    if ([contentDic valueForKeyPath:@"identity_verify_info.identity_code"]) {
        [fields addObject:@"identity_verify_info.identity_code"];
    }
    if ([contentDic valueForKeyPath:@"identity_verify_info.name"]) {
        [fields addObject:@"identity_verify_info.name"];
    }
    if ([contentDic valueForKeyPath:@"enc_params.password"]) {
        [fields addObject:@"enc_params.password"];
    }
    if ([contentDic valueForKeyPath:@"enc_params.password_confirm"]) {
        [fields addObject:@"enc_params.password_confirm"];
    }
    if ([contentDic valueForKeyPath:@"enc_params.old_password"]) {
        [fields addObject:@"enc_params.old_password"];
    }
    if ([contentDic valueForKeyPath:@"password"]) {
        [fields addObject:@"password"];
    }
    if ([contentDic valueForKeyPath:@"password_confirm"]) {
        [fields addObject:@"password_confirm"];
    }
    if ([contentDic valueForKeyPath:@"card_no"]) {
        [fields addObject:@"card_no"];
    }
    if ([contentDic valueForKeyPath:@"mobile_pwd"]) {
        [fields addObject:@"mobile_pwd"];
    }
    if ([contentDic valueForKeyPath:@"serial_num"]) {
        [fields addObject:@"serial_num"];
    }
    if ([contentDic valueForKey:@"ext"]) {
        [fields addObject:@"ext"];
    }

    [dic cj_setObject:fields forKey:@"fields"];
    return dic;
}

@end
