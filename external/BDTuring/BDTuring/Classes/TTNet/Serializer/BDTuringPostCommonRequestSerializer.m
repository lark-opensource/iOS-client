//
//  BDTuringPostCommonRequestSerializer.m
//  BDTuring
//
//  Created by bob on 2020/5/28.
//

#import "BDTuringPostCommonRequestSerializer.h"
#import "BDTNetworkManager.h"
#import "NSObject+BDTuring.h"

@implementation BDTuringPostCommonRequestSerializer


- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                              params:(NSDictionary *)parameters
                              method:(NSString *)method
               constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam {
    TTHttpRequest * request = [super URLRequestWithURL:URL params:parameters method:method constructingBodyBlock:bodyBlock commonParams:commonParam];
    
    [request setValue:BDTuringHeaderAccept forHTTPHeaderField:kBDTuringHeaderAccept];
    [request setValue:BDTuringHeaderConnection forHTTPHeaderField:kBDTuringHeaderConnection];
    
    if ([parameters isKindOfClass:[NSDictionary class]] && parameters.count > 0) {
        NSData *sendingData = [parameters turing_JSONRepresentationData];
        [request setHTTPBody:sendingData];
        [request setValue:BDTuringHeaderContentTypeJSON forHTTPHeaderField:kBDTuringHeaderContentType];
    }
    
    
    return request;
}

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                               headerField:(NSDictionary *)headField
                                    params:(NSDictionary *)parameters
                                    method:(NSString *)method
                     constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam {
    TTHttpRequest * request = [super URLRequestWithURL:URL params:parameters method:method constructingBodyBlock:bodyBlock commonParams:commonParam];
    
    [request setValue:BDTuringHeaderAccept forHTTPHeaderField:kBDTuringHeaderAccept];
    [request setValue:BDTuringHeaderConnection forHTTPHeaderField:kBDTuringHeaderConnection];
    [headField enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSString class]] && [key isKindOfClass:[NSString class]]) {
            [request setValue:obj forHTTPHeaderField:key];
        }
    }];

    if ([parameters isKindOfClass:[NSDictionary class]] && parameters.count > 0) {
        NSData *sendingData = [parameters turing_JSONRepresentationData];
        [request setHTTPBody:sendingData];
        [request setValue:BDTuringHeaderContentTypeJSON forHTTPHeaderField:kBDTuringHeaderContentType];
    }
    
    
    return request;
}


@end
