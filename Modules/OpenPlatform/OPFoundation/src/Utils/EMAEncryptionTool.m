//
//  EMAEncryptionTool.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2020/2/19.
//

#import "EMAEncryptionTool.h"
#import <CommonCrypto/CommonDigest.h>
#import "NSString+EMA.h"
#import "BDPUtils.h"

@implementation EMAEncryptionTool

+ (NSString *)encyptID:(NSString *)ID {
    if (!ID) {
        return nil;
    }

    NSString *md5WithSalt = [NSString stringWithFormat:@"%@42b91e", ID].ema_md5;
    if (!md5WithSalt) {
        return nil;
    }

    return [NSString stringWithFormat:@"08a441%@", md5WithSalt].ema_sha1;
}

@end
