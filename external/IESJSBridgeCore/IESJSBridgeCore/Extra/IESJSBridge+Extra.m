//
//  IESJSBridge+Extra.m
//  IESJSBridgeCore
//
//  Created by Lizhen Hu on 2021/2/5.
//

#import "IESJSBridge+Extra.h"

@implementation IESPiper (Extra)

// Reserve the 'config' bridge method to make those old business work as ever.
- (void)registerConfigMethod
{
    __weak typeof(self) weakSelf = self;
    [self registerHandlerBlock:^NSDictionary *(NSString *callbackId, NSDictionary *result, NSString *JSSDKVersion, BOOL *executeCallback) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (executeCallback) {
            *executeCallback = NO;
        }
        
        NSString *clientID = [result objectForKey:@"client_id"];
        [strongSelf getAuthConfigWithClientKey:clientID
                                        domain:strongSelf.webView.ies_url.host
                                     secretKey:nil
                                   finishBlock:^(NSDictionary *result) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf invokeJSWithCallbackID:callbackId parameters:@{@"code": result ? @(IESPiperStatusCodeSucceed) : @(IESPiperStatusCodeFail)}];
        }];
        
        return nil;
    } forJSMethod:@"config" authType:IESPiperAuthPublic];
}

- (void)getAuthConfigWithClientKey:(NSString*)clientKey
                            domain:(NSString*)domain
                         secretKey:(NSString*)secretKey
                       finishBlock:(void(^)(NSDictionary *result))finishBlock
{
    if(domain.length == 0) {
        finishBlock?: finishBlock(nil);
    } else {
        NSString *jsAuthConfigURLString = @"https://i.snssdk.com/client_auth/js_sdk/config/v1/";
        NSString *urlString = [NSString stringWithFormat:@"%@?client_id=%@&partner_domain=%@", jsAuthConfigURLString, clientKey, domain];
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionTask *task = [session dataTaskWithURL:[NSURL URLWithString:urlString] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error || data == nil) {
                if (finishBlock) {
                    finishBlock(nil);
                }
                return;
            }
            
            NSError *jsonError = nil;
            id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
            if (jsonError || ![jsonObject isKindOfClass:NSDictionary.class] || ![jsonObject objectForKey:@"data"]) {
                if (finishBlock) {
                    finishBlock(nil);
                }
                return;
            }
            
            NSDictionary *resultData = [jsonObject objectForKey:@"data"];
            if (![resultData isKindOfClass:NSDictionary.class]) {
                !finishBlock ?: finishBlock(nil);
                return;
            }
            
            if (finishBlock) {
                finishBlock(resultData);
            }
        }];
        
        [task resume];
    }
}

@end
