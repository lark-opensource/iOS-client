//
//  HMDHTTPUtil.h
//  Heimdallr
//
//  Created by fengyadong on 2018/1/25.
//

#import <Foundation/Foundation.h>

@interface HMDHTTPUtil : NSObject

+ (uint64_t)getRequestLengthForRequest:(NSURLRequest *)request streamLength:(NSInteger)streamLength;
+ (uint64_t)getHeadersLength:(NSDictionary *)headers;
+ (NSDictionary<NSString *, NSString *> *)getCookiesForRequest:(NSURLRequest *)request;
+ (uint64_t)getResponseLengthForResponse:(NSURLResponse *)response bodyLength:(uint64_t)bodyLength;

@end
