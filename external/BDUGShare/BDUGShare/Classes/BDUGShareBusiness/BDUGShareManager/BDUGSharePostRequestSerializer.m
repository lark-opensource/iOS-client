//
//  BDUGSharePostRequestSerializer.m
//  News
//
//  Created by 冯靖君 on 2018/3/16.
//

#import "BDUGSharePostRequestSerializer.h"

@implementation BDUGSharePostRequestSerializer

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                              params:(id)params
                              method:(NSString *)method
               constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam
{
    TTHttpRequest *request = [super URLRequestWithURL:URL
                                               params:params
                                               method:method
                                constructingBodyBlock:bodyBlock
                                         commonParams:commonParam];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    if (params) {
        NSData *postDate = [NSJSONSerialization dataWithJSONObject:params
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:nil];
        [request setHTTPBody:postDate];
    }
    
    return request;
}

@end
