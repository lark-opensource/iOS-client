//
//  BDWebViewMonitorFileProvider.m
//  IESWebViewMonitor
//
//  Created by 蔡腾远 on 2019/12/23.
//

#import "BDWebViewMonitorFileProvider.h"
#import "IESLiveWebViewMonitor+Private.h"
#import <objc/runtime.h>
#import "BDHybridMonitorDefines.h"

static NSString const *kBDWMAccessKey = @"5194cf52a842a932b45e2da53553c014";

static NSString const *kBDWMMonitorVersion = @"2.2.1";

@implementation BDWebViewMonitorFileProvider

+ (IMP)getIMPFrom:(Class)cls sel:(SEL)sel {
    Method method = class_getClassMethod(cls, sel);
    IMP imp = method_getImplementation(method);
    return imp;
}

+ (void)setUpGurdEnvWithAppId:(NSString *)appId appVersion:(NSString *)appVersion cacheRootDirectory:(NSString *)directory deviceId:(NSString *)deviceId {
    if (appId.length <= 0
        || appVersion.length <= 0
        || directory.length <= 0
        || deviceId.length <= 0) {
        return;
    }
    
    NSString *className = [NSString stringWithFormat:@"%@%@%@", @"IES", @"Gu", @"rdKit"];
    Class cls = NSClassFromString(className);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    SEL setupSel = @selector(setupWithAppId:appVersion:cacheRootDirectory:);
    IMP setupImp = [self getIMPFrom:cls sel:setupSel];
    SEL setDeviceIDSel = @selector(setDeviceID:);
    IMP setDeviceIDImp = [self getIMPFrom:cls sel:setDeviceIDSel];
#pragma clang diagnostic pop
    
    if (setupImp) {
        ((void(*)(Class, SEL, id, id, id))setupImp)(cls, setupSel, appId, appVersion, nil);
    }
    if (setDeviceIDImp) {
        ((void(*)(Class, SEL, id))setDeviceIDImp)(cls, setDeviceIDSel, deviceId);
    }
}

+ (void)syncGurdService {
    NSString *className = [NSString stringWithFormat:@"%@%@%@", @"IES", @"Gu", @"rdKit"];
        Class cls = NSClassFromString(className);
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    // registerAccessKey:channels:
    SEL registerSel = @selector(registerAccessKey:channels:);
    IMP registerImp = [self getIMPFrom:cls sel:registerSel];
    
    // syncResourcesWithAccessKey:channels:completion:
    SEL syncResourcesSel = @selector(syncResourcesWithAccessKey:channels:resourceVersion:completion:);
    IMP syncResourcesImp = [self getIMPFrom:cls sel:syncResourcesSel];
#pragma clang diagnostic pop
    
    if (registerImp && syncResourcesImp) {
        NSString *jssdk = [NSString stringWithFormat:@"%@%@%@", @"slar", @"dar", @"_js"];
        NSString *jssdkBridge = [NSString stringWithFormat:@"%@%@%@", @"slar", @"dar_bri", @"dge_js"];
        NSArray *channels = @[jssdk, jssdkBridge];
        ((void(*)(Class, SEL, id, id))registerImp)(cls, registerSel, kBDWMAccessKey, channels);
        ((void(*)(Class, SEL, id, id, id, id))syncResourcesImp)(cls, syncResourcesSel, kBDWMAccessKey, channels, kBDWMMonitorVersion, nil);
    }
}

+ (BOOL)startMonitorWithClasses:(NSSet *)classes
                        setting:(NSDictionary *)setting {
    if ([self shouldStopUpdateJS]) {
        return NO;
    }
    [self syncGurdService];
    return YES;
}

+ (NSString *)scriptForTimingForWebView:(id)webView domMonitor:(BOOL)domMonitor {
    
    static NSString *bridgeScript = nil;
    static NSString *jssdkScript = nil;
    static NSString *domMonitorScript = @"";
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *className = [NSString stringWithFormat:@"%@%@%@", @"IES", @"Gu", @"rdKit"];
        Class cls = NSClassFromString(className);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        // setupWithAppId:appVersion:cacheRootDirectory:
        SEL getDataSel = @selector(dataForPath:accessKey:channel:);
        Method getDataMethod = class_getClassMethod(cls, getDataSel);
        IMP getDataImp = method_getImplementation(getDataMethod);
#pragma clang diagnostic pop
        NSData *jssdkData = nil;
        NSData *bridgeData = nil;
        if ([cls respondsToSelector:getDataSel]) {
            NSString *jssdk = [NSString stringWithFormat:@"%@%@%@", @"slar", @"dar", @"_js"];
            NSString *jssdkBridge = [NSString stringWithFormat:@"%@%@%@", @"slar", @"dar_bri", @"dge_js"];
            jssdkData = ((NSData*(*)(Class, SEL, id, id, id))getDataImp)(cls, getDataSel, [NSString stringWithFormat:@"%@%@%@", @"slar", @"dar.j", @"s"], kBDWMAccessKey, jssdk);
            bridgeData = ((NSData*(*)(Class, SEL, id, id, id))getDataImp)(cls, getDataSel, [NSString stringWithFormat:@"%@%@%@", @"slar", @"dar_bri", @"dge.js"], kBDWMAccessKey, jssdkBridge);
        }
        
        if (jssdkData && bridgeData) {
            jssdkScript = [[NSString alloc] initWithData:jssdkData encoding:NSUTF8StringEncoding] ?: @"";
            bridgeScript = [[NSString alloc] initWithData:bridgeData encoding:NSUTF8StringEncoding] ?: @"";
        } else { // 如果没有下发, 走默认
            NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:@"IESWebViewMonitor.bundle"]];
            NSString *filePath = [bundle pathForResource:@"jssdk" ofType:@"js"];
            NSString *bridgePath = [bundle pathForResource:@"jssdk_bridge" ofType:@"js"];
            NSString *domMonitorPath = [bundle pathForResource:@"dom_monitor" ofType:@"js"];
            bridgeScript = bridgePath.length ? [NSString stringWithContentsOfFile:bridgePath
                                                                                encoding:NSUTF8StringEncoding
                                                                                   error:nil] : @"";
            jssdkScript = filePath.length ? [NSString stringWithContentsOfFile:filePath
                                                                        encoding:NSUTF8StringEncoding
                                                                           error:nil] : @"";
            domMonitorScript = domMonitorPath.length ? [NSString stringWithContentsOfFile:domMonitorPath
            encoding:NSUTF8StringEncoding
               error:nil] : @"";
        }
    });
    if (domMonitor) {
        return domMonitorScript;
    }
    return [NSString stringWithFormat:@"%@ \n%@ \n", jssdkScript, bridgeScript];
}

+ (BOOL)shouldStopUpdateJS {
//    return NO; // 暂时开启
//    return YES; // 暂时关闭gecko下发
   // 审核中, 不初始化gecko和下发js文件
   if ([[NSUserDefaults standardUserDefaults] boolForKey:kBDWMShouldStopUpdateJS]) {
       return YES;
   }
   return NO;
}

@end
