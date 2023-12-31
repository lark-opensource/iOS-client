//
//  EMANetworkCipher.m
//  EEMicroAppSDK
//
//  Created by houjihu on 2019/9/11.
//

#import "EMANetworkCipher.h"
#import "TMACustomHelper.h"
#import "BDPSDKConfig.h"
#import "TMASecurity.h"
#import <ECOInfra/JSONValue+BDPExtension.h>
#import "NSData+BDPExtension.h"
#import <ECOInfra/BDPLog.h>

@implementation EMANetworkCipher

- (instancetype)init {
    if (self = [super init]) {
        NSString *key = [TMACustomHelper randomString];
        NSString *iv = [TMACustomHelper randomString];
        self.key = key;
        self.iv = iv;
        NSError *error;
        NSString *encryptKey = [[NSData encryptData:[[NSString stringWithFormat:@"%@#%@", key, iv] dataUsingEncoding:NSUTF8StringEncoding] publicKey:[BDPSDKConfig sharedConfig].appMetaPubKey error:&error] ss_base64EncodedString];
        if (error) {
            BDPLogError(@"encrypt error %@", error.localizedDescription);
        }
        self.encryptKey = encryptKey;
    }
    return self;
}

+ (EMANetworkCipher *)cipher {
    return [[EMANetworkCipher alloc] init];
}

+ (instancetype)getCipher {
    return [[EMANetworkCipher alloc] init];
}

+ (id)decryptDictForEncryptedContent:(NSString *)encryptedContent cipher:(EMANetworkCipher *)cipher {
    NSString *key = cipher.key;
    NSString *iv = cipher.iv;
    NSData *decryptedData = [encryptedContent tma_aesDecrypt:key iv:iv];
    id data = [decryptedData JSONValue];
    return data;
}

@end
