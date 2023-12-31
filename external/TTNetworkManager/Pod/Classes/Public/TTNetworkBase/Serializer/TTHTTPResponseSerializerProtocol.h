//
//  TTHTTPResponseSerializerProtocol.h
//  Pods
//
//  Created by ZhangLeonardo on 15/9/7.
//
//  The serialized object of the network request return value

#import <Foundation/Foundation.h>
#import "TTResponseModelProtocol.h"
#import "TTRequestModel.h"

#import "TTHttpRequest.h"
#import "TTHttpResponse.h"

#pragma mark -- JSON response

/**
 *  The serialized object used to parse JSON response
 */
@protocol TTJSONResponseSerializerProtocol <NSObject>

@required

/**
 The acceptable MIME types for responses. When non-`nil`, responses with a `Content-Type` with MIME types that do not intersect with the set will result in an error during validation.
 */
@property (nonatomic, copy) NSSet *acceptableContentTypes;

/**
 *  Generate the serialized object
 *
 *  @return serialized object
 */
+ (NSObject<TTJSONResponseSerializerProtocol> *)serializer;

/**
 *  parse return value
 *
 *  @param response      NSURLResponse object
 *  @param jsonObj       parsed JSON object（if can be parse）
 *  @param responseError error returned
 *  @param resultError   error pass to bussiness layer
 *
 *  @return parsed result
 */
- (id)responseObjectForResponse:(TTHttpResponse *)response
                        jsonObj:(id)jsonObj
                  responseError:(NSError *)responseError
                    resultError:(NSError *__autoreleasing *)resultError;

@end

#pragma mark -- responseModel response

/**
 *  The serialized object used to parse Modle response
 */
@protocol TTResponseModelResponseSerializerProtocol <NSObject>

/**
 *  Generate the serialized object
 *
 *  @return serialized object
 */
+ (NSObject<TTResponseModelResponseSerializerProtocol> *)serializer;

- (NSObject<TTResponseModelProtocol> *)responseObjectForResponse:(TTHttpResponse *)response
                                                         jsonObj:(id)jsonObj
                                                    requestModel:(TTRequestModel *)requestModel
                                                   responseError:(NSError *)responseError
                                                     resultError:(NSError *__autoreleasing *)resultError;
@end

#pragma mark -- binary response

/**
 *  The serialized object used to parse Binary response
 */
@protocol TTBinaryResponseSerializerProtocol <NSObject>

/**
 *  Generate the serialized object
 *
 *  @return serialized object
 */
+ (NSObject<TTBinaryResponseSerializerProtocol> *)serializer;

/**
 *  parse return value
 *
 *  @param response      NSURLResponse object
 *  @param data          data returned
 *  @param responseError error returned
 *  @param resultError   error pass to bussiness layer
 *
 *  @return parsed result
 */
- (id)responseObjectForResponse:(TTHttpResponse *)response
                           data:(NSData *)data
                  responseError:(NSError *)responseError
                    resultError:(NSError *__autoreleasing *)resultError;

@end

/**
 *  Used to do some pre-processing work before returning the Response, such as https failure retransmission, etc.
 */

@protocol TTResponsePreProcessorProtocol <NSObject>

+ (NSObject<TTResponsePreProcessorProtocol> *)processor;
- (void)preprocessWithResponse:(TTHttpResponse *)response
                responseObject:(id *)responseObject
                         error:(NSError **)error
                    ForRequest:(TTHttpRequest *)request;
- (void)finishPreprocess;

@property (nonatomic, assign, readonly) BOOL ttNeedsRetry; // Rename variable to avoid name conflict with Apple Non-public API
@property (nonatomic, assign, readonly) BOOL alertHijack;
@property (nonatomic, strong, readonly) TTHttpRequest *retryRequest;
@property (nonatomic, assign, readonly) NSUInteger retryTimes;


@end

