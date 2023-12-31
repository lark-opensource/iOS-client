//
//  CJPaySafeUtil.m
//  CJPay
//
//  Created by wangxinhua on 2018/10/25.
//

#import "CJPaySafeUtil.h"
#import "CJPayCommonUtil.h"
#import "CJPaySDKMacro.h"

@implementation CJPaySafeUtil

+ (NSString *)encryptPWD:(NSString *)pwd{
    if (pwd == nil || pwd.length < 1) {
        return @"";
    }
    int *errorCode = malloc(sizeof(int));
    NSString *processResStr = [CJPayCommonUtil createMD5With:[CJPayCommonUtil createMD5With:pwd]];
    NSString *safePwd = [CJPaySafeManager cj_encryptWith:processResStr errorCode:errorCode];
    free(errorCode);
    if (safePwd == nil || safePwd.length < 1) {
        return @"";
    }
    return safePwd;
}

+ (NSString *)objEncryptPWD:(NSString *)pwd engimaEngine:(id<CJPayEngimaProtocol>)engimaImpl {
    if (pwd == nil || pwd.length < 1) {
        return @"";
    }
    int *errorCode = malloc(sizeof(int));
    NSString *processResStr = [CJPayCommonUtil createMD5With:[CJPayCommonUtil createMD5With:pwd]];
    NSString *safePwd = [CJPaySafeManager cj_objEncryptWith:processResStr errorCode:errorCode engimaEngine:engimaImpl];
    free(errorCode);
    if (safePwd == nil || safePwd.length < 1) {
        return @"";
    }
    return safePwd;
}

+ (NSString *)encryptPWD:(NSString *)pwd serialNumber:(NSString *) serialnum{
    if (pwd == nil || pwd.length < 1) {
        return @"";
    }
    int *errorCode = malloc(sizeof(int));
    NSString *processResStr = [NSString stringWithFormat:@"%@%@", [CJPayCommonUtil createMD5With:[CJPayCommonUtil createMD5With:pwd]], serialnum];
    NSString *safePwd = [CJPaySafeManager cj_encryptWith:processResStr errorCode:errorCode];
    CJPayLogInfo(@"密文结果: %d", safePwd.length);
    free(errorCode);
    if (safePwd == nil || safePwd.length < 1) {
        return @"";
    }
    return safePwd;
}

+ (NSString *)encryptField:(NSString *)field {
    
    if (field == nil || field.length < 1) {
        return @"";
    }
    int *errorCode = malloc(sizeof(int));
    NSString *safeField = [CJPaySafeManager cj_encryptWith:field errorCode:errorCode];
    free(errorCode);
    if (safeField == nil || safeField.length < 1) {
        return @"";
    }
    return safeField;
}

+ (NSString *)objEncryptField:(NSString *)field engimaEngine:(id<CJPayEngimaProtocol>)engimaImpl {
    if (field == nil || field.length < 1) {
        return @"";
    }
    int *errorCode = malloc(sizeof(int));
    NSString *safeField = [CJPaySafeManager cj_objEncryptWith:field errorCode:errorCode engimaEngine:engimaImpl];
    free(errorCode);
    if (safeField == nil || safeField.length < 1) {
        return @"";
    }
    return safeField;
}

+ (NSString *)encryptContentFromH5:(NSString *)data{
    int *errorCode = malloc(sizeof(int));
    NSString *unsafe = [CJPaySafeManager cj_encryptWith:data errorCode:errorCode];
    free(errorCode);
    return unsafe;
}

+ (NSString *)encryptContentFromH5:(NSString *)data token:(NSString *)publicKey {
    int *errorCode = malloc(sizeof(int));
    NSString *unsafe = [CJPaySafeManager cj_encryptWith:data token:publicKey errorCode:errorCode];
    free(errorCode);
    return unsafe;
}

+ (NSString *)decryptContentFromH5:(NSString *)data{
    int *errorCode = malloc(sizeof(int));
    NSString *res = [CJPaySafeManager cj_decryptWith:data errorCode:errorCode];
    free(errorCode);
    return res;
};

+ (NSString *)objDecryptContentFromH5:(NSString *)data engimaEngine:(id<CJPayEngimaProtocol>)engimaImpl{
    if (!data) {
        return @"";
    }
    int *errorCode = malloc(sizeof(int));
    NSString *res = [CJPaySafeManager cj_objDecryptWith:data engimaEngine:engimaImpl errorCode:errorCode];
    free(errorCode);
    return res;
};

@end
