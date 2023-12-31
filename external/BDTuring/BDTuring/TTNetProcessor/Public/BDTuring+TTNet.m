//
//  BDTuring+TTNet.m
//  BDTuring
//
//  Created by bob on 2021/8/2.
//

#import "BDTuring+TTNet.h"
#import "BDTuring+Private.h"
#import "BDTuringParameter.h"
#import "BDTuringMacro.h"
#import "BDTNetworkManager.h"
#import "NSString+BDTuring.h"
#import "BDTuringVerifyModel+Creator.h"
#import "BDTuringVerifyResult.h"
#import "BDTuringUtility.h"

#import <BDAssert/BDAssert.h>
#import <BDAlogProtocol/BDAlogProtocol.h>
#import <TTNetworkManager/TTHttpResponse.h>
#import <TTNetworkManager/TTNetworkManager.h>

typedef BOOL (^TTNetworkResponseHeadersCallback)(TTHttpResponse *response);

@interface TTNetworkManager(BDTuring)
@property(atomic, copy) TTNetworkResponseHeadersCallback addResponseHeadersCallback;
@end

@implementation BDTuring (TTNet)

@dynamic skipPathList;

- (void)setupProcessorForTTNetworkManager {
    [BDTuringParameter sharedInstance].appID = self.appID;
    BDAssert([TTNetworkManager shareInstance].addResponseHeadersCallback == nil, @"addResponseHeadersCallback should set by BDTuring!!!");
    [TTNetworkManager shareInstance].addResponseHeadersCallback =  ^BOOL (TTHttpResponse *response){
        
        NSString *path = response.URL.path;
        NSArray *skipPathList = self.skipPathList;
        if (BDTuring_isValidArray(skipPathList)
            && BDTuring_isValidString(path)
            && [skipPathList containsObject:path]) {
            return NO;
        }
        
        NSDictionary *parameters = [self parametersFromResponse:response];
        if (parameters == nil || self.isShowVerifyView) {
            return NO;
        }
        if (![self.callbackLock tryLock]) {
            return NO;
        }
        __block BOOL shouldRetry = NO;
        BDTuringVerifyModel *model = [BDTuringVerifyModel parameterModelWithParameter:parameters];
        model.callback = ^(BDTuringVerifyResult *result) {
            shouldRetry = result.status == BDTuringVerifyStatusOK;
            [self.callbackLock unlock];
        };
        [self popVerifyViewWithModel:model];
        /// this is to wait callback finish
        [self.callbackLock lock];
        [self.callbackLock unlock];
        return  shouldRetry;
    };
}

- (NSDictionary *)parametersFromResponse:(TTHttpResponse *)response {
    NSString *parameters = [[response allHeaderFields] objectForKey:kBDTuringHeaderSDKParameters];
    if (![parameters isKindOfClass:[NSString class]] || parameters.length < 1) {
        return nil;
    }
    BDALOG_PROTOCOL_INFO_TAG(@"BDTuring", @"bdturing-verify header string (%@)", parameters);
    NSDictionary *turingParameters = [parameters turing_dictionaryFromJSONString];
    
    return turingParameters;
}


@end
