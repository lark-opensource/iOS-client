//
//  RequestRetryResult.m
//  TTNetworkManager
//
//  Created by taoyiyuan on 2022/10/21.
//
#import "RequestRetryResult.h"

#import <Foundation/Foundation.h>

@implementation RequestRetryResult

- (id)initWithRetryResult:(BOOL)requestRetryEnabled addRequestHeaders:(NSDictionary*)addRequestHeaders {
    self = [super init];
    if (self) {
        _requestRetryEnabled = requestRetryEnabled;
        _addRequestHeaders = addRequestHeaders;
    }

    return self;
}

@end
