//
//  BytedCertNFCReader.m
//  byted_cert
//
//  Created by liuminghui.2022 on 2023/4/10.
//

#import "BytedCertNFCReader.h"
#import "BytedCertError.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>

NSString *const JLReaderAppid = @"01SJ2305101719506267";
NSString *const JLReaderIp = @"es.eidlink.com";


@interface BytedCertNFCReader ()

@end


@implementation BytedCertNFCReader

- (instancetype)init {
    self = [super init];
    if (self) {
        [[JLReader sharedInstance] setReaderConfigWithAppid:JLReaderAppid withMod:0 withIp:JLReaderIp withPort:9989 withCardType:0 withEnvCode:52302 withIsImg:YES withModel:nil withConfigState:JLReaderConfigCard];
    }
    return self;
}

- (void)startNFCWithParams:(NSDictionary *)params connectBlock:(void (^_Nullable)(JLConnectTagState))connectBlock completion:(void (^)(NSDictionary *_Nonnull))completion {
    if (!params || params[@"type"] == nil) {
        completion(@{@"status_code" : @(BytedCertErrorArgs)});
        return;
    }
    NSString *type = [params btd_stringValueForKey:@"type"];
    [JLReader sharedInstance].reTryTimes = [params btd_integerValueForKey:@"retryTimes"];
    [JLReader sharedInstance].timeouts = [params btd_integerValueForKey:@"timeout"];
    [JLReader sharedInstance].connectBlock = connectBlock;
    if ([type isEqualToString:@"id_card"]) {
        [[JLReader sharedInstance] startReadIDCardWithResult:^(NSInteger errCode, NSString *_Nullable reqID, NSString *_Nullable errMsg, NSString *_Nullable infoData, NSString *_Nullable biz_id) {
            btd_dispatch_async_on_main_queue(^{
                NSMutableDictionary *nfcResult = [[NSMutableDictionary alloc] init];
                nfcResult[@"status_code"] = @(errCode);
                nfcResult[@"result"] = errCode == 0 ? @"success" : @"fail";
                nfcResult[@"message"] = errMsg;
                NSMutableDictionary *nfcData = [[NSMutableDictionary alloc] init];
                nfcData[@"reqId"] = reqID;
                nfcData[@"error_msg"] = errMsg;
                if (infoData) {
                    NSDictionary *cardInfo = [infoData btd_jsonDictionary];
                    if (cardInfo) {
                        [nfcData addEntriesFromDictionary:cardInfo];
                    }
                    nfcData[@"identity_name"] = [cardInfo btd_stringValueForKey:@"name"];
                    nfcData[@"identity_code"] = [cardInfo btd_stringValueForKey:@"idnum"];
                    [nfcData removeObjectForKey:@"picture"];
                }
                nfcResult[@"data"] = nfcData.copy;
                if (errCode == -93009) {
                    completion(@{@"status_code" : @(BytedCertNFCErrorNFCUnOpen)});
                } else {
                    completion(nfcResult.copy);
                }
            });
        }];
    }
}

@end
