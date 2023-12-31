//
//  TTRequestModel.m
//  Pods
//
//  Created by ZhangLeonardo on 15/9/6.
//
//

#import "TTRequestModel.h"
#import "TTNetworkUtil.h"

@implementation TTRequestModel

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (NSString *)_requestURIStr
{
    NSString * result = self._uri;
    return result;
}

- (NSURL *)_requestURL
{
    if (self._fullNewURL) {
        return [NSURL URLWithString:self._fullNewURL];
    }
    
    NSURL * url = [TTNetworkUtil URLWithURLString:[self _requestURIStr]
                                          baseURL:[NSURL URLWithString:self._host]];
    return url;
}

- (NSDictionary *)_requestParams
{
    return self._params;
}

- (NSString *)_requestMethod
{
    return self._method;
}

@end
