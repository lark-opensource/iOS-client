//
//  EMANetworkRequestManager.m
//  EEMicroAppSDK
//
//  Created by houjihu on 2019/9/5.
//

#import "EMANetworkRequestManager.h"
#import <ECOInfra/EMANetworkManager.h>
#import <ECOInfra/BDPNetworkRequestExtraConfiguration.h>
#import <TTNetworkManager/TTHTTPRequestSerializerProtocol.h>

@implementation NSURLSessionTask(BDPNetwork)
@end

@implementation NSURLResponse (BDPNetwork)
@end

@implementation EMANetworkRequestManager

#pragma mark BDPNetworkRequestProtocol

- (id<BDPNetworkTaskProtocol>)taskWithRequestUrl:(NSString *)URLString
                                      parameters:(id)parameters
                                     extraConfig:(id)extraConfigDic
                                      completion:(void (^)(NSError * _Nonnull, id _Nonnull, id<BDPNetworkResponseProtocol> _Nonnull))completion
{
    BDPNetworkRequestExtraConfiguration* config = (BDPNetworkRequestExtraConfiguration*)extraConfigDic;
    BDPRequestMethod requestMethod = config.method;
    NSString* requestMethodStr = @"GET";
    if (requestMethod == BDPRequestMethodGET) {
        requestMethodStr = @"GET";
    }else if (requestMethod == BDPRequestMethodPOST)
    {
        requestMethodStr = @"POST";
    }
    BDPRequestExtraConfigFlags configFlags = config.flags;
    Class requestSerializerClass = config.bdpRequestSerializerClass;
    BDPRequestType requestType = config.type;
    NSDictionary *headerField = config.bdpRequestHeaderField;
    BOOL autoResume = configFlags & BDPRequestAutoResume;

    switch (requestType) {
        case BDPRequestTypeRequestForJson: {
            //默认请求超时为60秒
            NSTimeInterval timeout = (config.timeout > 0) ?: 60;
            return [[EMANetworkManager shared] requestUrl:URLString method:requestMethodStr params:parameters header:headerField completionWithJsonData:^(NSDictionary * _Nullable json, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if (completion) {
                    completion(error, json, response);
                }
            } eventName:@"requestForJson" autoResume:autoResume timeout:timeout requestTracing:nil];
            break;
        }
        case BDPRequestTypeRequestForBinary: {
            //TTNetworkManager降级
            NSMutableURLRequest *urlRequest = [[self class] requestForURLString:URLString method:requestMethodStr parameters:parameters headerFields:headerField requestSerializerClass:requestSerializerClass];
            return [[EMANetworkManager shared] dataTaskWithMutableRequest:urlRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if (completion) {
                    completion(error, data, response);
                }
            } eventName:@"requestForBinary" autoResume:autoResume requestTracing:nil];
            break;
        }
        case BDPRequestTypeUpload:
        {
            id constructingBodyBlock = config.constructingBodyBlock;
            void *progress = config.progress;
            //默认上传超时为30秒
            NSTimeInterval timeout = config.timeout>0?:30;
            return (id<BDPNetworkTaskProtocol>)[[TTNetworkManager shareInstance] uploadWithResponse:URLString parameters:parameters headerField:headerField constructingBodyWithBlock:constructingBodyBlock progress:(NSProgress * __autoreleasing *)progress needcommonParams:[@(configFlags&BDPRequestNeedCommonParams) boolValue] requestSerializer:requestSerializerClass responseSerializer:nil autoResume:[@(configFlags&BDPRequestAutoResume) boolValue] callback:^(NSError *error, id obj, TTHttpResponse *response){
                completion(error,obj,(id<BDPNetworkResponseProtocol>)response);
            } timeout:timeout];
        }
            break;
        default:
            return nil;
            break;
    }
}

#pragma mark - private

+ (NSMutableURLRequest *)requestForURLString:(NSString *)URLString method:(NSString *)method parameters:(NSDictionary *)parameters headerFields:(NSDictionary *)headerFields requestSerializerClass:(Class)requestSerializerClass {
    id<TTHTTPRequestSerializerProtocol> requestSerializerProtocol = requestSerializerClass;
    TTHttpRequest *request = [[requestSerializerProtocol serializer]
     URLRequestWithURL:URLString
     headerField:headerFields
     params:parameters
     method:method
     constructingBodyBlock:nil
     commonParams:nil];
    NSMutableURLRequest *targetRequest = nil;
    targetRequest = [[NSMutableURLRequest alloc] initWithURL:request.URL];
    targetRequest.HTTPMethod = request.HTTPMethod;
    targetRequest.HTTPBody = request.HTTPBody;
    targetRequest.timeoutInterval = request.timeoutInterval;
    // copy headers
    targetRequest.allHTTPHeaderFields = request.allHTTPHeaderFields;
    return targetRequest;
}

@end
