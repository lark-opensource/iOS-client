//
//  BDPMetaTTCode.m
//  Timor
//
//  Created by houjihu on 2020/6/8.
//

#import "BDPMetaTTCode.h"
#import <OPFoundation/TMACustomHelper.h>
#import <OPFoundation/BDPSDKConfig.h>
#import <OPFoundation/NSData+BDPExtension.h>
#import <ECOInfra/NSString+BDPExtension.h>
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/BDPUtils.h>
#import <TTMicroApp/TTMicroApp-Swift.h>

static NSString * BDPMetaTTCodeAESKeyA;
static NSString * BDPMetaTTCodeAESKeyB;
@implementation BDPMetaTTCode

- (instancetype)init {
    if (self = [super init]) {
        self.aesKeyA = [TMACustomHelper randomString] ?: @"B4huRIrpmThGgYiY";
        self.aesKeyB = [TMACustomHelper randomString] ?: @"tfQ2Sw04GMEdwUy4";

        NSData *dataToEncrypt = [[NSString stringWithFormat:@"%@#%@", self.aesKeyA, self.aesKeyB] dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSData *rsaData = [NSData encryptData:dataToEncrypt publicKey:[BDPSDKConfig sharedConfig].appMetaPubKey error:&error];
        if (error) {
            NSString *errorMessage = [NSString stringWithFormat:@"BDPMetaTTCode init encrypt data failed: %@", error];
            NSAssert(NO, errorMessage);
            BDPLogTagError(BDPTag.metaManager, errorMessage);
        }
        NSString *tempTTCode = [[rsaData ss_base64EncodedString] URLEncodedString];
        if (BDPIsEmptyString(tempTTCode)) {
            //  ttcode 系统失败，做出兜底，和头条对齐，降级为预先加密好的数据。TODO 用正确的方法重写这里的逻辑，降低复杂度补充校验
            self.aesKeyA = @"B4huRIrpmThGgYiY";
            self.aesKeyB = @"tfQ2Sw04GMEdwUy4";
            self.ttcode = @"W7Ku%2FZlvrsbXxz0W1dSqvfdsEnjb7MD6wuWwv8aLQ%2B%2Fsr7fcjYDmPxUI9k5oFiZyhcAqddVtOH4XABuMot4mpWGAofU3vA6tYLB%2BUb%2B3uY9lLGMpq2T8NbNJ34h9bMCsEl1QzAgJY6RvcScAiPNLMsJLEHDNy2eUhbuYF6mApWU%3D";
        } else {
            self.ttcode = tempTTCode;
        }
    }
    return self;
}

- (instancetype)initWithDefaultSettings {
    if (self = [super init]) {
        self.aesKeyA = @"B4huRIrpmThGgYiY";
        self.aesKeyB = @"tfQ2Sw04GMEdwUy4";
        self.ttcode = @"tYpQQypn9ni1%2FPqZj4U6mRCh8IrwyGdvvYfgM8XlXu7WQu532IzmYCSF8KNx1TRs%2FwnsOjeh%2FH%2FstFoO8sJqRO2lPrbmxQIXgoB8uaqxwXvSa%2BzlsGlRAw79ys%2FkPmL%2FPL4eBHyb8MZova4ceUvdq17uD5JfwpyEJL56%2B%2BmlTXU%3D";
    }
    return self;
}
 
+(BDPMetaTTCode *)buildInAppCode
{
    BDPMetaTTCode * ttcode = [[BDPMetaTTCode alloc] initWithDefaultSettings];
    return ttcode;
}
@end
