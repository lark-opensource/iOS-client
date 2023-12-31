//
//  BDPNetworkTimeoutConfig.m
//  Timor
//
//  Created by 张朝杰 on 2019/5/30.
//

#import "BDPNetworkTimeoutConfig.h"

#define BDP_DEFAULT_NETWORK_TIMEOUT @(60000)

@implementation BDPNetworkTimeoutConfig

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err {
    self = [super initWithDictionary:dict error:err];
    if (self) {
        if (![self isValidTime:_requestTime]) {
            _requestTime = BDP_DEFAULT_NETWORK_TIMEOUT;
        }
        if (![self isValidTime:_uploadFileTime]) {
            _uploadFileTime = BDP_DEFAULT_NETWORK_TIMEOUT;
        }
        if (![self isValidTime:_downloadFileTime]) {
            _downloadFileTime = BDP_DEFAULT_NETWORK_TIMEOUT;
        }
        if (![self isValidTime:_connectSocketTime]) {
            _connectSocketTime = BDP_DEFAULT_NETWORK_TIMEOUT;
        }
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _requestTime = _uploadFileTime = _downloadFileTime = _connectSocketTime = BDP_DEFAULT_NETWORK_TIMEOUT;
    }
    return self;
}

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"requestTime": @"request",
                                                                  @"uploadFileTime": @"uploadFile",
                                                                  @"downloadFileTime": @"downloadFile",
                                                                  @"connectSocketTime": @"connectSocket",
                                                                  }];
}

- (BOOL)isValidTime:(NSNumber *)time {
    return [time isKindOfClass:[NSNumber class]] && time.longLongValue > 0 && time.longLongValue <= 60000;
}

@end
