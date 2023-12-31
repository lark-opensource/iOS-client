//
//  BDNativeWebBridgeManager.m
//  AFgzipRequestSerializer
//
//  Created by liuyunxuan on 2019/7/8.
//

#import "BDNativeWebBridgeManager.h"
#import "NSString+BDNativeWebHelper.h"
#import "NSDictionary+BDNativeWebHelper.h"

@interface BDNativeBridgeObj : NSObject

@property (nonatomic, strong) NSString *functionName;
@property (nonatomic, strong) NSString *callbackId;
@property (nonatomic, strong) NSDictionary *params;
@property (nonatomic, strong) NSString *iFrameID;

@end

@implementation BDNativeBridgeObj

@end

@interface BDNativeWebBridgeManager()

@property (nonatomic, strong) NSMutableDictionary *invokeDic;

@end


@implementation BDNativeWebBridgeManager

- (void)registerHandler:(dispatch_block_t)handler forName:(NSString *)name
{
    if (name == nil || handler == nil)
    {
        return;
    }
    
    [self.invokeDic setValue:handler forKey:name];
}

- (void)handleInvokeMessage:(NSDictionary *)dict {
    BDNativeBridgeHandler handler = [self.invokeDic objectForKey:@"invoke"];
    if (!handler) {
        return;
    }
    
    NSString *callbackId = [dict bdNative_stringValueForKey:@"callbackId"];
    
    __weak typeof(self) weakSelf = self;
    BDNativeBridgeCallback callback = ^(BDNativeBridgeMsg msg, NSDictionary *params,void(^resultBlock)(NSString *result)){
        if (weakSelf == nil) {
            return;
        }
        
        NSMutableDictionary *responseDataDic = [NSMutableDictionary dictionary];
        [responseDataDic setValue:@(msg) forKey:@"status"];
        [responseDataDic setValue:params forKey:@"data"];
        
        NSString *script = [NSString stringWithFormat:@"window.byted_mixrender_web.callback(%d, '%@')", [callbackId intValue], [responseDataDic bdNative_JSONRepresentation]? :@"{}"];
        [weakSelf.delegate bdNativeBridge_nativeMangerEvaluateJavaScript:script completionHandler:^(id result, NSError * error) {
            if ([result isKindOfClass:[NSString class]]) {
                resultBlock(result);
            }
        }];
    };
    
    handler(dict,callback);
}

- (void)handleCallBackMessage:(NSDictionary *)dict {
    
}

- (void)handleMixRenderMessage:(NSString *)message
{
    NSDictionary *dict = [message bdNativeJSONDictionary];
    if(dict)
    {
        NSString *msgName = [dict bdNative_stringValueForKey:@"msg"];
        if ([msgName isEqualToString:@"invoke"]) {
            [self handleInvokeMessage:dict];
        } else if ([msgName isEqualToString:@"callback"]) {
            [self handleCallBackMessage:dict];
        }
    }
}

- (void)registerHandler:(BDNativeBridgeHandler)handler bridgeName:(NSString *)bridgeName
{
    if (bridgeName.length > 0 && handler != nil) {
        [self.invokeDic setObject:handler forKey:bridgeName];
    }
}
#pragma mark - initlize getter
- (NSMutableDictionary *)invokeDic
{
    if (!_invokeDic)
    {
        _invokeDic = [[NSMutableDictionary alloc] init];
    }
    return _invokeDic;
}

#pragma mark - private method
- (NSString *)messageJSONStringByDic:(NSDictionary *)message
{
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:message options:0 error:nil] encoding:NSUTF8StringEncoding];
}
@end
