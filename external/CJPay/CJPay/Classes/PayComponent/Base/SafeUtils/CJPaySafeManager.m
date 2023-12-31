//
//  CJPaySafeManager.m
//  CJPay
//
//  Created by wangxinhua on 2018/10/24.
//

#import "CJPaySafeManager.h"
#import "CJPaySDKMacro.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPayEngimaProtocol.h"

#define CJ_MD5_DIGEST_LENGTH 32

@implementation CJPaySafeManager
+ (BOOL)isEngimaISec {
    return [self isecClass];
}

+ (id<CJPayEngimaProtocol>)isecClass {
    id<CJPayEngimaProtocol> engimaClass = (id<CJPayEngimaProtocol>)NSClassFromString(@"CJPayISecEngimaImpl");
    CJPayLogAssert(engimaClass, @"不包含加解密类，isec");
    return engimaClass;
}

+ (id<CJPayEngimaProtocol>)tfccClass {
    id<CJPayEngimaProtocol> engimaClass = (id<CJPayEngimaProtocol>)NSClassFromString(@"CJPayTfccEngimaImpl");
    CJPayLogAssert(engimaClass, @"不包含加解密类,tfcc");
    return engimaClass;
}

+ (NSNumber *)secureInfoVersion {
    if ([self isEngimaISec]) {
        return @(20);
    }
    return @(3);
}

+ (id<CJPayEngimaProtocol>)buildEngimaEngine:(NSString *)engimaID {
    return [self buildEngimaEngine:engimaID useCert:@""];
}

+ (id<CJPayEngimaProtocol>)buildEngimaEngine:(NSString *)engimaID useCert:(NSString *)cert {
    if ([self isEngimaISec]) {
        CJPayLogInfo(@"创建Isec的加密实例");
        return [[self isecClass] getEngimaProtocolBy:engimaID useCert:cert];
    }
    CJPayLogInfo(@"创建tfcc的加密实例");
    return [[self tfccClass] getEngimaProtocolBy:engimaID useCert:cert];
}

+ (NSString *)cj_encryptWith:(NSString *)data errorCode:(int *)errorCode{
    return [[self buildEngimaEngine:@""] encryptWith:data errorCode:errorCode];
}

+ (NSString *)cj_encryptWith:(NSString *)data token:(NSString *)publicKey errorCode:(int *)errorCode {
    return [[self buildEngimaEngine:@"" useCert:publicKey] encryptWith:data errorCode:errorCode];
}

+ (NSString *)cj_decryptWith:(NSString *)data errorCode:(int *)errorCode{
    return [[self buildEngimaEngine:@""] decryptWith:data errorCode:errorCode];
}

+ (NSString*) cj_objEncryptWith:(NSString *)data errorCode:(int *)errorCode engimaEngine:(id<CJPayEngimaProtocol>)engimaImpl{
    NSString* encryptedData = [engimaImpl encryptWith:data errorCode:errorCode];
    return encryptedData;
}

+ (NSString *)cj_objDecryptWith:(NSString *)data engimaEngine:(id<CJPayEngimaProtocol>)engimaImpl errorCode:(int *)errorCode{
    return [engimaImpl decryptWith:data errorCode:errorCode];
}

+ (NSDictionary *)secureInfo {
    NSMutableDictionary *dic = [NSMutableDictionary new];
    [dic cj_setObject:[self secureInfoVersion] forKey:@"version"];
    [dic cj_setObject:@(2) forKey:@"type1"];
    [dic cj_setObject:@(1) forKey:@"type2"];
    [dic cj_setObject:@"" forKey:@"key"];
    return dic;
}

+ (NSString *)encryptMediaData:(NSData *)mediaData tfccCert:(NSString *)tfccCert iSecCert:(NSString *)isecCert engimaVersion:(NSNumber *__autoreleasing *)engimaVersion {
    NSString *media = @"";
    if (Check_ValidString(isecCert) && [self isEngimaISec]) {
        int *errorCode = malloc(sizeof(int));
        id<CJPayEngimaProtocol> isecEngine = [[self isecClass] getEngimaProtocolBy:@"" useCert:isecCert];
        NSString *unsafe = [isecEngine encryptWithData:mediaData
                                             errorCode:errorCode];
        media = [CJPayCommonUtil replaceNoEncoding:unsafe];
        *engimaVersion = @(20);
    } else if (Check_ValidString(tfccCert)) {
        int *errorCode = malloc(sizeof(int));
        id<CJPayEngimaProtocol> tfccEngine = [[self tfccClass] getEngimaProtocolBy:@"" useCert:tfccCert];
        NSString *unsafe = [tfccEngine encryptWithData:mediaData
                                             errorCode:errorCode];
        media = [CJPayCommonUtil replaceNoEncoding:unsafe];
        *engimaVersion = @(0);
    }
    return media;
}

@end
