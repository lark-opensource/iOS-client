//
//  BDXGurdNetDelegateImpl.m
//  BDXResourceLoader-Pods-Aweme
//
//  Created by bill on 2021/3/4.
//

#import "BDXGurdNetDelegateImpl.h"

#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <IESGeckoKit/IESGeckoKit.h>
#import <TTNetworkManager/TTHTTPRequestSerializerBase.h>
#import <TTNetworkManager/TTHTTPResponseSerializerBase.h>
#import <TTNetworkManager/TTNetworkManager.h>

@implementation BDXGurdNetDelegateImpl

- (void)downloadPackageWithURLString:(NSString *)packageURLString completion:(IESGurdNetworkDelegateDownloadCompletion)completion
{
    NSString *destination = [[IESGurdKit cacheRootDir] stringByAppendingPathComponent:packageURLString.lastPathComponent];
    [[TTNetworkManager shareInstance] downloadTaskWithRequest:packageURLString parameters:nil headerField:nil needCommonParams:YES requestSerializer:[TTHTTPRequestSerializerBase class] progress:nil destination:[NSURL fileURLWithPath:destination] autoResume:YES completionHandler:^(TTHttpResponse *response, NSURL *location, NSError *error) {
        if (error) {
            location = nil;
        }
        !completion ?: completion(location, error);
    }];
}

- (void)requestWithMethod:(NSString *)method URLString:(NSString *)URLString params:(NSDictionary *)params completion:(void (^)(IESGurdNetworkResponse *))completion
{
    BOOL useJSON = [method.uppercaseString isEqualToString:@"POST"];

    TTNetworkJSONFinishBlockWithResponse callback = ^(NSError *error, id obj, TTHttpResponse *response) {
        IESGurdNetworkResponse *networkResponse = [[IESGurdNetworkResponse alloc] init];
        networkResponse.statusCode = response.statusCode;
        networkResponse.responseObject = obj;
        networkResponse.error = error;
        networkResponse.allHeaderFields = response.allHeaderFields;

        !completion ?: completion(networkResponse);
    };
    NSDictionary *headerField = useJSON ? @{@"Content-Type": @"application/json"} : nil;
    // use default
    Class<TTHTTPRequestSerializerProtocol> requestSerializer = [TTHTTPRequestSerializerBase class];
    [[TTNetworkManager shareInstance] requestForJSONWithResponse:URLString params:params method:method needCommonParams:YES headerField:headerField requestSerializer:requestSerializer responseSerializer:[TTHTTPJSONResponseSerializerBase class] autoResume:YES callback:callback];
}

- (void)downloadPackageWithIdentity:(nonnull NSString *)identity URLString:(nonnull NSString *)packageURLString completion:(nonnull IESGurdNetworkDelegateDownloadCompletion)completion
{
    [self downloadPackageWithURLString:packageURLString completion:completion];
}

@end
