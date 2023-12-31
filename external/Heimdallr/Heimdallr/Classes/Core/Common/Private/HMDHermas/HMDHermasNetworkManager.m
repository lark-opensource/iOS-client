//
//  HMDHermasNetworkManager.m
//  Heimdallr-8bda3036
//
//  Created by 崔晓兵 on 7/7/2022.
//

#import "HMDHermasNetworkManager.h"
#import "HMDNetworkManager.h"
#import "HMDNetworkProtocol.h"
#import "HMDURLSessionManager.h"
#import "HMDNetworkReqModel.h"
#import "HMDDynamicCall.h"
#import "NSDictionary+HMDJSON.h"
#import "NSDictionary+HMDHTTPQuery.h"
#import "HMDALogProtocol.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

#import "NSData+HMDGzip.h"

@implementation HMDHermasNetworkManager

- (void)requestWithModel:(HMRequestModel *)model callback:(JSONFinishBlock)callback {
    @autoreleasepool {
        
    }
    HMDNetworkReqModel *reqModel = [self reqModelWith:model];
    [[HMDNetworkManager sharedInstance] asyncRequestWithModel:reqModel callback:^(NSError *error, id jsonObj) {
        if (callback) {
            callback(error, jsonObj);
        }
    }];
}

- (HMDNetworkReqModel *)reqModelWith:(HMRequestModel *)model {
    HMDNetworkReqModel *reqModel = [[HMDNetworkReqModel alloc] init];
    reqModel.requestURL = model.requestURL;
    NSMutableDictionary *fixedHeaderField = [NSMutableDictionary dictionaryWithDictionary:model.headerField];
    if (model.needEcrypt) {
        [fixedHeaderField setValue:@"application/octet-stream;tt-data=a" forKey:@"Content-Type"];
    }
    reqModel.headerField = fixedHeaderField;
    reqModel.method = model.method;
    reqModel.postData = model.postData;
    reqModel.isManualTriggered = NO;
    reqModel.isFromHermas = YES;
    reqModel.needEcrypt = model.needEcrypt;
    return reqModel;
}

@end

