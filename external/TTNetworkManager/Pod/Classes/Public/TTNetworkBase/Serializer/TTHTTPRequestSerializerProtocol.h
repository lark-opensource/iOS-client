//
//  TTHTTPRequestSerializerProtocol.h
//  Pods
//
//  Created by gaohaidong on 9/23/16.
//
//

/// Moved from TTHTTPRequestSerializerBase.h

#import "TTRequestModel.h"
#import "TTNetworkDefine.h"

//TTHttpRequest Encapsulate the request of the network library
#import "TTHttpRequest.h"

@protocol TTHTTPRequestSerializerProtocol <NSObject>

/**
 *  Instantiated object
 *
 *  @return Instantiated serializer object
 */
+ (NSObject<TTHTTPRequestSerializerProtocol> *)serializer;

/**
 *  Factory function to create TTHttpRequest via TTRequestModel
 *
 *  @param requestModel         RequestModel to generate URLRequest
 *  @param commonParam          common parameters
 *
 *  @return URLRequest generated
 */
- (TTHttpRequest *)URLRequestWithRequestModel:(TTRequestModel *)requestModel
                                       commonParams:(NSDictionary *)commonParam;

/**
 *  Factory function to create TTHttpRequest via URL and params
 *
 *  @param URL                request URL
 *  @param params             request parameters
 *  @param method             request method
 *  @param bodyBlock         need multipart form request body
 *  @param commonParam        common parameters
 *
 *  @return URLRequest generated
 */
- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                                    params:(id)params
                                    method:(NSString *)method
                     constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                              commonParams:(NSDictionary *)commonParam;
/**
 *  Factory function to create TTHttpRequest via URL and params
 *
 *  @param URL                request URL
 *  @param headField          HTTP head
 *  @param params             request parameters
 *  @param method             request method
 *  @param bodyBlock          need multipart form request body
 *  @param commonParam        common parameters
 *
 *  @return URLRequest generated
 */

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                               headerField:(NSDictionary *)headField
                                    params:(id)params
                                    method:(NSString *)method
                     constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                              commonParams:(NSDictionary *)commonParam;

/**
 *  set User-Agent
 *
 *  @return User-Agent
 */
- (NSString *)userAgentString;


@end
