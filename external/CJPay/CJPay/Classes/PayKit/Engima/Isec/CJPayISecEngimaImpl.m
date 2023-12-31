//
//  CJPayISecEngimaImpl.m
//  CJPay
//
//  Created by 王新华 on 2022/7/8.
//

#import "CJPayISecEngimaImpl.h"
#import "CJPaySDKMacro.h"
#import <isecgm/IsecGM.h>
#import "CJPaySettingsManager.h"
#import "CJPayEngimaProtocol.h"

@interface CJPayISecEngimaImpl()

@property (nonatomic, strong) IsecGM *engimaEngine;
@property (nonatomic, copy) NSString *customCert;

@end

@implementation CJPayISecEngimaImpl

+ (id<CJPayEngimaProtocol>)getEngimaProtocolBy:(NSString *)identify {
    return [self getEngimaProtocolBy:identify useCert:@""];
}

+ (id<CJPayEngimaProtocol>)getEngimaProtocolBy:(NSString *)identify useCert:(NSString *)cert {
    CJPayISecEngimaImpl *gm = [CJPayISecEngimaImpl new];
    gm.customCert = cert;
    return gm;
}

+ (NSString *)oneKeyAssemble {
    static NSString *oneKeyAssemble;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        oneKeyAssemble = [CJPaySettingsManager shared].currentSettings.oneKeyAssemble;
    });
    return oneKeyAssemble;
}

+ (BOOL)shouldOneKeyAssemble {
    return [[self oneKeyAssemble] isEqualToString:@"1"];
}

+ (NSData *)globalSM4KeyData {
    static NSData *globalSM4KeyData;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        IsecGM *gm = [[IsecGM alloc] init];
        NSInteger errCode = 0;
        globalSM4KeyData = [gm sm4GenerateKeyWithError:&errCode];
    });
    return globalSM4KeyData;
}

- (IsecGM *)engimaEngine {
    if (!_engimaEngine) {
        _engimaEngine = [IsecGM new];
    }
    return _engimaEngine;
}

- (NSString *)p_currentPayToken {
    if (Check_ValidString(self.customCert)) {
        return self.customCert;
    }
    return [self defaultToken];
}

- (NSString *)defaultToken {
    return @"BLGfAX+1hJstOC2J1wOzio2GIU3WliZKr1K1ssAju2bIKzx7QExY37EzG/LmEbDu2KSdwP7XgZBM1VkzVsYVWYk=";
}

- (NSString *)encryptWithData:(NSData *)data errorCode:(int *)errorCode {
    NSString *encryptResultStr = [self p_customEncryptWith:[data base64EncodedStringWithOptions:0] errorCode:errorCode];
    return encryptResultStr;
}

- (NSString *)encryptWith:(NSString *)data
                errorCode:(int *)errorCode {
    NSString *encryptResultStr = @"";
    if ([CJPayISecEngimaImpl shouldOneKeyAssemble]) {
        NSData *certKey = [[NSData alloc] initWithBase64EncodedString:[self p_currentPayToken] options:0];
        NSData *encryptData = [self.engimaEngine encryptMessage:[data dataUsingEncoding:NSUTF8StringEncoding] withPublicKey:certKey withError:(NSInteger *)errorCode];
        NSString *result = [[NSString alloc] initWithData:[encryptData base64EncodedDataWithOptions:0] encoding:NSUTF8StringEncoding];
        encryptResultStr = [CJPayCommonUtil replaceNoEncoding:result];
    } else {
        encryptResultStr = [self p_customEncryptWith:data errorCode:errorCode];
    }
    NSString *resultStr = Check_ValidString(encryptResultStr) ? @"1" : @"0";
    [CJMonitor trackService:@"wallet_rd_new_encrypt_result"
                   category:@{@"result": resultStr}
                      extra:@{}];
    return encryptResultStr;
}

// 加密过程1. 生成对称秘钥  2. 拿对称秘钥对数据加密，3. 拿公钥加密对称秘钥。
- (NSString *)decryptWith:(NSString *)data errorCode:(int *)errorCode {
    if (!Check_ValidString(data)) {
        CJPayLogAssert(data, @"传入的解密数据为空");
        return @"";
    }
    NSString *decryptResultStr = @"";
    if ([CJPayISecEngimaImpl shouldOneKeyAssemble]) {
        NSData *decryptData = [self.engimaEngine decryptMessage:[[NSData alloc] initWithBase64EncodedString:data options:0] withError:(NSInteger *)errorCode];
        NSString *decodedString = [[NSString alloc] initWithData:[decryptData base64EncodedDataWithOptions:0] encoding:NSUTF8StringEncoding];
        decryptResultStr = [CJPayCommonUtil cj_decodeBase64:decodedString];
    } else {
        decryptResultStr = [CJPayCommonUtil cj_decodeBase64:[self p_customDecryptWith:data errorCode:errorCode]];
    }
    NSString *resultStr = Check_ValidString(decryptResultStr) ? @"1" : @"0";
    [CJMonitor trackService:@"wallet_rd_new_decrypt_result"
                   category:@{@"result": resultStr}
                      extra:@{}];
    return decryptResultStr;
}

// 该方法是自行组装加密报文的格式。
- (NSString *)p_customEncryptWith:(NSString *)data errorCode:(int *)errorCode {
    return [self p_customEncryptWithData:[data dataUsingEncoding:NSUTF8StringEncoding] errorCode:errorCode];
}

// 该方法是自行组装加密报文的格式。
- (NSString *)p_customEncryptWithData:(NSData *)originData errorCode:(int *)errorCode {
    IsecGM *gm = self.engimaEngine;
    int offset = 0;
    NSUInteger len = 0;
    NSInteger errCode = 0;
    NSData *certKey = [[NSData alloc] initWithBase64EncodedString:[self p_currentPayToken] options:0];

    NSData *sm4key = [CJPayISecEngimaImpl globalSM4KeyData];
    if (sm4key == nil) {
        CJPayLogError(@"生成秘钥失败，0x%08zX", errCode);
        return @"";
    }
    NSData *dataHmac = [gm sm3HMACMessage:originData
                                  withKey:sm4key
                                withError:&errCode];
    if (dataHmac == nil) {
        CJPayLogError(@"hmac失败，0x%08zX", errCode);
        return @"";
    }

    NSData *cliper = [gm sm4EncryptMessage:originData
                                   withKey:sm4key
                                    withIV:nil
                                  withMode:CIPHER_ALG_MODE_ECB
                               withPadding:CIPHER_PADDING_MODE_PKCS7
                                 withError:&errCode];
    if (cliper == nil) {
        CJPayLogError(@"加密原文失败，0x%08zX", errCode);
        return @"";
    }

    NSData *sm4KeyCliper = [gm sm2EncryptMessage:sm4key
                                   withPublicKey:certKey
                                   withDerEncode:NO
                                       withError:&errCode];

    len = 4 + 4 + dataHmac.length + 4 + sm4KeyCliper.length + 4 + cliper.length;
    unsigned char *buf = NULL;
    buf = (unsigned char *)calloc(len, sizeof(unsigned char));
    //    请求报文：4字节总长度+4字节HMAC长度+HMAC值+4字节SM4密钥密文长度+SM4密钥密文+4字节原文密文长度+原文密文值 （总长度byte=4+Hmac长度+4+对称密钥长度+4+sm4密文长度）

    len -= 4;
    buf[0] = (len >> 24) & 0xFF;
    buf[1] = (len >> 16) & 0xFF;
    buf[2] = (len >> 8) & 0xFF;
    buf[3] = len & 0xFF;
    
    int hmacL = (int)dataHmac.length;
    buf[4] = (hmacL >> 24) & 0xFF;
    buf[5] = (hmacL >> 16) & 0xFF;
    buf[6] = (hmacL >> 8) & 0xFF;
    buf[7] = hmacL & 0xFF;
    
    offset = 8;
    memcpy(buf + offset, dataHmac.bytes, dataHmac.length);
    offset += (int)dataHmac.length;
    
    int sm4CliperL = (int)sm4KeyCliper.length;
    buf[offset]     = (sm4CliperL >> 24) & 0xFF;
    buf[offset + 1] = (sm4CliperL >> 16) & 0xFF;
    buf[offset + 2] = (sm4CliperL >> 8) & 0xFF;
    buf[offset + 3] = sm4CliperL & 0xFF;
    offset += 4;
    
    memcpy(buf + offset, sm4KeyCliper.bytes, sm4KeyCliper.length);
    offset += (int)sm4KeyCliper.length;
    
    int cliperL = (int)cliper.length;
    buf[offset]     = (cliperL >> 24) & 0xFF;
    buf[offset + 1] = (cliperL >> 16) & 0xFF;
    buf[offset + 2] = (cliperL >> 8) & 0xFF;
    buf[offset + 3] = cliperL & 0xFF;
    
    offset += 4;
    memcpy(buf + offset, cliper.bytes, cliper.length);
    
    NSString *result = [[NSString alloc] initWithData:[[[NSData alloc] initWithBytes:buf length:len + 4] base64EncodedDataWithOptions:0] encoding:NSUTF8StringEncoding];
    free(buf);
    return [CJPayCommonUtil replaceNoEncoding:result];
}

- (NSString *)p_customDecryptWith:(NSString *)data
                        errorCode:(int *)errorCode {
    if (!data) {
        CJPayLogAssert(data, @"传入的加密数据为空");
        return @"";
    }
    NSInteger errCode = 0;
    NSData *originalData = [[NSData alloc] initWithBase64EncodedString:data options:0];
    NSData *decryptData = [self.engimaEngine sm4DecryptMessage:originalData
                                                       withKey:[CJPayISecEngimaImpl globalSM4KeyData]
                                                        withIV:nil
                                                      withMode:CIPHER_ALG_MODE_ECB
                                                   withPadding:CIPHER_PADDING_MODE_PKCS7
                                                     withError:&errCode];
    NSString *decryptString = [[NSString alloc] initWithData:[decryptData base64EncodedDataWithOptions:0]
                                                    encoding:NSUTF8StringEncoding];
    return decryptString;
}

- (NSString *)sm4Encrypt:(NSString *)data  key:(NSString *)key
                        errorCode:(int *)errorCode {
    if (!data) {
        CJPayLogAssert(data, @"传入的加密数据为空");
        return @"";
    }
    NSInteger errCode = 0;
    NSData *originalData = [[NSData alloc] initWithBase64EncodedString:[data btd_base64EncodedString] options:0];
    NSData *encryptData = [self.engimaEngine sm4EncryptMessage:originalData
                                                       withKey:[key base64DecodeData]
                                                        withIV:nil
                                                      withMode:CIPHER_ALG_MODE_ECB
                                                   withPadding:CIPHER_PADDING_MODE_PKCS7
                                                     withError:&errCode];
    NSString *encryptString = [[NSString alloc] initWithData:[encryptData base64EncodedDataWithOptions:0]
                                                    encoding:NSUTF8StringEncoding];
    return encryptString;
}

- (NSString *)sm4Decrypt:(NSString *)data key:(NSString *)key
                        errorCode:(int *)errorCode {
    if (!data) {
        CJPayLogAssert(data, @"传入的加密数据为空");
        return @"";
    }
    NSInteger errCode = 0;
    NSData *originalData = [[NSData alloc] initWithBase64EncodedString:data options:0];
    NSData *decryptData = [self.engimaEngine sm4DecryptMessage:originalData
                                                       withKey:[key base64DecodeData]
                                                        withIV:nil
                                                      withMode:CIPHER_ALG_MODE_ECB
                                                   withPadding:CIPHER_PADDING_MODE_PKCS7
                                                     withError:&errCode];
    NSString *decryptString = [[NSString alloc] initWithData:[decryptData base64EncodedDataWithOptions:0]
                                                    encoding:NSUTF8StringEncoding];
    return [decryptString btd_base64DecodedString];
}

@end
