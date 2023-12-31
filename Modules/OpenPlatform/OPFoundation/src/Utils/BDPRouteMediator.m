//
//  BDPRouteMediator.m
//  Timor
//
//  Created by yin on 2018/9/4.
//

#import "BDPRouteMediator.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>

@implementation BDPRouteMediator

+ (instancetype)sharedManager {
    static BDPRouteMediator *mediator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mediator = [[BDPRouteMediator alloc] init];
    });
    return mediator;
}

+ (BOOL)needUpdateAlertForUniqueID:(BDPUniqueID *)uniqueID {
    id delegate = [BDPRouteMediator sharedManager].delegate;
    if (delegate && [delegate respondsToSelector:@selector(needUpdateAlertForUniqueID:)]) {
        return [delegate needUpdateAlertForUniqueID:uniqueID];
    }
    return NO;
}

+ (void)onWebviewCreate:(BDPUniqueID *_Nullable)uniqueID webview:(BDPWebViewComponent *)webview {
    id delegate = [BDPRouteMediator sharedManager].delegate;
    if (delegate && [delegate respondsToSelector:@selector(onWebviewCreate:webview:)]) {
        [delegate onWebviewCreate:uniqueID webview:webview];
    }
}

+ (void)onWebviewDestroy:(BDPUniqueID *_Nullable)uniqueID webview:(BDPWebViewComponent *)webview {
    id delegate = [BDPRouteMediator sharedManager].delegate;
    if (delegate && [delegate respondsToSelector:@selector(onWebviewDestroy:webview:)]) {
        [delegate onWebviewDestroy:uniqueID webview:webview];
    }
}

+ (NSMutableURLRequest *)appMetaRequestWithURL:(NSString *)url params:(NSDictionary *)params uniqueID:(BDPUniqueID *)uniqueID {
    return [BDPRouteMediator.sharedManager.delegate appMetaRequestWithURL:url params:params uniqueID:uniqueID];
}

+ (NSDictionary *)validWifiSecureStrength {
    id delegate = [BDPRouteMediator sharedManager].delegate;
    if (delegate && [delegate respondsToSelector:@selector(validWifiSecureStrength)]) {
        return [[BDPRouteMediator sharedManager].delegate validWifiSecureStrength];
    }
    return nil;
}

-(NSString * _Nullable )leastVersionLaunchParams:(BDPUniqueID*) uniqueId{
    NSArray * configSchemeParameterAppList = nil;
    if (self.configSchemeParameterAppListFetch) {
        configSchemeParameterAppList = self.configSchemeParameterAppListFetch();
    }
    __block NSString * leastVersion = nil;
    [configSchemeParameterAppList enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull configApp, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([uniqueId.appID isEqual:configApp[@"appId"]] && uniqueId.appType == OPAppTypeGadget) {
            NSArray * configParamList = [configApp bdp_arrayValueForKey:@"configSchemaParameterList"];
            for (NSDictionary * schemeObj in configParamList)  {
                if ([@"least_version" isEqual:schemeObj[@"key"]]) {
                    leastVersion = schemeObj[@"value"];
                    *stop = YES;
                    break;
                }
            }
        }
    }];
    return leastVersion;
}
@end
