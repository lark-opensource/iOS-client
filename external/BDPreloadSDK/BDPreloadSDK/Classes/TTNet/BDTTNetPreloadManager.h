//
//  BDTTNetPreloadManager.h
//  BDPreloadSDK
//
//  Created by wealong on 2019/8/16.
//

#import <Foundation/Foundation.h>
#import <TTNetworkManager/TTNetworkManager.h>

@interface BDTTNetPreloadOperation : NSOperation

@property (nonatomic, copy) NSString *urlString;
@property (nonatomic, strong) id params;
@property (nonatomic, strong) NSString *method;
@property (nonatomic, copy) NSDictionary *headerField;
@property (nonatomic, assign) BOOL needCommonParams;
@property (nonatomic, copy) TTNetworkJSONFinishBlockWithResponse completion;
@property (nonatomic, strong) Class<TTHTTPRequestSerializerProtocol> requestSerializer;
@property (nonatomic, strong) id responseSerializer;
@property (nonatomic, assign) BOOL isBinary;
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, assign) NSUInteger retryCount;

@property (assign, nonatomic, getter = isExecuting, readonly) BOOL executing;
@property (assign, nonatomic, getter = isFinished, readonly) BOOL finished;
@property (nonatomic, strong, readonly) TTHttpTask *task;

@end

@interface BDTTNetPreloadManager : NSObject

+ (void)requestForBinaryWithResponse:(NSString *)URL
                          callback:(TTNetworkObjectFinishBlockWithResponse)callback;

+ (void)requestForBinaryWithResponse:(NSString *)URL
                              params:(id)params
                              method:(NSString *)method
                    needCommonParams:(BOOL)commonParams
                         headerField:(NSDictionary *)headerField
                   requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                  responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                            callback:(TTNetworkObjectFinishBlockWithResponse)callback;

+ (void)requestForBinaryWithResponse:(NSString *)URL
                            params:(id)params
                            method:(NSString *)method
                  needCommonParams:(BOOL)commonParams
                       headerField:(NSDictionary *)headerField
                 requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                responseSerializer:(Class<TTBinaryResponseSerializerProtocol>)responseSerializer
                   timeoutInterval:(NSTimeInterval)timeoutInterval
                        retryCount:(NSUInteger)retryCount
                          callback:(TTNetworkObjectFinishBlockWithResponse)callback;

+ (void)requestForJSONWithResponse:(NSString *)URL
                          callback:(TTNetworkJSONFinishBlockWithResponse)callback;

+ (void)requestForJSONWithResponse:(NSString *)URL
                            params:(id)params
                            method:(NSString *)method
                  needCommonParams:(BOOL)commonParams
                       headerField:(NSDictionary *)headerField
                 requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                responseSerializer:(Class<TTJSONResponseSerializerProtocol>)responseSerializer
                          callback:(TTNetworkJSONFinishBlockWithResponse)callback;

+ (void)requestForJSONWithResponse:(NSString *)URL
                            params:(id)params
                            method:(NSString *)method
                  needCommonParams:(BOOL)commonParams
                       headerField:(NSDictionary *)headerField
                 requestSerializer:(Class<TTHTTPRequestSerializerProtocol>)requestSerializer
                responseSerializer:(Class<TTJSONResponseSerializerProtocol>)responseSerializer
                   timeoutInterval:(NSTimeInterval)timeoutInterval
                        retryCount:(NSUInteger)retryCount
                          onlyWiFi:(BOOL)onlyWiFi
                          callback:(TTNetworkJSONFinishBlockWithResponse)callback;


@end
