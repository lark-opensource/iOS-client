//
//  WKWebView+Piper.m
//  BDTuring
//
//  Created by bob on 2019/8/25.
//

#import "WKWebView+Piper.h"
#import <objc/runtime.h>
#import "BDTuringPiper.h"
#import "BDTuringPiperConstant.h"
#import "BDTuringCoreConstant.h"
#import "NSDictionary+BDTuring.h"
#import "NSData+BDTuring.h"
#import "BDTNetworkManager.h"
#import "BDTuringMacro.h"

@implementation WKWebView (BDTuringPiper)

- (void)setTuring_piper:(BDTuringPiper *)turing_piper {
    objc_setAssociatedObject(self, @selector(turing_piper), turing_piper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BDTuringPiper *)turing_piper {
    return objc_getAssociatedObject(self, @selector(turing_piper));
}

- (void)turing_installPiper {
    if (self.turing_piper) {
        return;
    }
    
    self.turing_piper = [[BDTuringPiper alloc] initWithWebView:self];
}

- (void)onNetworkPiperName:(NSString *)name {
    BDTuringWeakSelf;
    [self.turing_piper on:name callback:^(NSDictionary *params, BDTuringPiperOnCallback callback) {
        BDTuringStrongSelf;
        [self handlePiperNetwork:params callback:callback];
    }];
}

- (void)handlePiperNetwork:(NSDictionary *)params
                     callback:(BDTuringPiperOnCallback)callback {
    if (callback == nil) {
        return;
    }
    NSString *requestURL = [params turing_stringValueForKey:kBDTuringNetworkURL];
    NSString *method = [params turing_stringValueForKey:kBDTuringNetworkMethod];
    if (requestURL.length < 0 || method.length < 0) {
        callback(BDTuringPiperMsgParamError, nil);
    }
    
    NSDictionary *query = [params turing_dictionaryValueForKey:kBDTuringNetworkQuery];
    NSDictionary *data = [params turing_dictionaryValueForKey:kBDTuringNetworkData];
    BDTuringNetworkFinishBlock netCallback = ^(NSData *response) {
        NSDictionary *resp = [response turing_objectFromJSONData];
        callback(BDTuringPiperMsgSuccess, resp);
    };
    [BDTNetworkManager asyncRequestForURL:requestURL
                                   method:method
                          queryParameters:query
                           postParameters:data
                                 callback:netCallback
                            callbackQueue:dispatch_get_main_queue()
                                  encrypt:NO
                                  tagType:BDTNetworkTagTypeManual];
}

@end
