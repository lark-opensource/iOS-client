//
//  BDTuringPostRequestSerializer.m
//  BDTuring
//
//  Created by bob on 2020/5/13.
//

#import "BDTuringPostRequestSerializer.h"
#import "BDTNetworkManager.h"
#import "NSObject+BDTuring.h"
#import <BDDataDecorator/NSData+DataDecorator.h>



@implementation BDTuringPostRequestSerializer

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
        NSData *decoratedData = [sendingData bd_dataByDecorated];
        if (decoratedData != nil) {
            [request setHTTPBody:decoratedData];
            [request setValue:BDTuringHeaderContentTypeData forHTTPHeaderField:kBDTuringHeaderContentType];
        } else {
            [request setHTTPBody:sendingData];
            [request setValue:BDTuringHeaderContentTypeJSON forHTTPHeaderField:kBDTuringHeaderContentType];
        }
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
        NSData *decoratedData = [sendingData bd_dataByDecorated];
        if (decoratedData != nil) {
            [request setHTTPBody:decoratedData];
            [request setValue:BDTuringHeaderContentTypeData forHTTPHeaderField:kBDTuringHeaderContentType];
        } else {
            [request setHTTPBody:sendingData];
            [request setValue:BDTuringHeaderContentTypeJSON forHTTPHeaderField:kBDTuringHeaderContentType];
        }
    }
    
    
    return request;
}


@end
