//
//  CJPayTfccEngimaImpl.m
//  CJPay
//
//  Created by 王新华 on 2022/7/6.
//

#import "CJPayTfccEngimaImpl.h"
#import "CJPayUIMacro.h"
#import <tfccsmsdk/tfccsdk.h>

@interface CJPayTfccEngimaImpl()

@property (nonatomic, strong) TfccSM *tfccSM;
@property (nonatomic, copy) NSString *customCert;

@end

@implementation CJPayTfccEngimaImpl

- (TfccSM *)tfccSM {
    if (!_tfccSM) {
        _tfccSM = [TfccSM new];
    }
    return _tfccSM;
}

- (NSString *)defaultToken {
    return @"04daf1593b5101574ed2013b41a0d3a44b40662ad20bafe9bbe3acbaac20e081cc0fedc69abfa962404041324521d9034319cd1077c2a8fbcf5f396343cdbcddf9";
}

- (NSString *)cj_currentPayToken {
    if (Check_ValidString(self.customCert)) {
        return self.customCert;
    }
    return [self defaultToken];
}

- (NSString *)encryptWithData:(NSData *)data errorCode:(int *)errorCode {
    NSString *result = [self.tfccSM encryptSMWith:[self cj_currentPayToken]
                                             data:[data base64EncodedStringWithOptions:0]
                                        errorCode:errorCode];
    return [CJPayCommonUtil replaceNoEncoding:result];
}

- (NSString *)decryptWith:(NSString *)data errorCode:(int *)errorCode {
    NSString *result = [self.tfccSM decryptSMWith:[self cj_currentPayToken] data:[CJPayCommonUtil replcaeAutoEncoding:data] errorCode:errorCode];
    return [CJPayCommonUtil cj_decodeBase64:result];
}

- (NSString *)encryptWith:(NSString *)data errorCode:(int *)errorCode {
    NSString *result = [self.tfccSM encryptSMWith:[self cj_currentPayToken] data:[CJPayCommonUtil cj_base64:data] errorCode:errorCode];
    return [CJPayCommonUtil replaceNoEncoding:result];
}

+ (id<CJPayEngimaProtocol>)getEngimaProtocolBy:(NSString *)identify {
    return [self getEngimaProtocolBy:identify useCert:@""];
}

+ (id<CJPayEngimaProtocol>)getEngimaProtocolBy:(NSString *)identify useCert:(NSString *)cert {
    CJPayTfccEngimaImpl *engimaImpl = [CJPayTfccEngimaImpl new];
    engimaImpl.customCert = cert;
    return engimaImpl;
}

@end


