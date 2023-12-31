//
//  BDWebViewFalconMonitor.m
//  IESWebViewMonitor
//
//  Created by Paklun Cheng on 2020/9/18.
//

#import "BDWebViewFalconMonitor.h"
#import "IESLiveWebViewMonitor+Private.h"
#import <BDWebKit/IESFalconManager.h>
#import "IESLiveWebViewPerformanceDictionary.h"
#import "BDWebView+BDWebViewMonitor.h"
#import "IESLiveWebViewMonitorSettingModel.h"
#import "BDMonitorThreadManager.h"
#import "BDHybridMonitorDefines.h"

@interface BDWebViewFalconMonitorInternel : NSObject <IESFalconMonitorInterceptor, IESWebViewMonitorDelegate>
@property (nonatomic, strong) NSMutableDictionary *falconDict;
@property (nonatomic, assign) NSInteger maxCount;
@end

@implementation BDWebViewFalconMonitorInternel

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    static BDWebViewFalconMonitorInternel *instance;
    dispatch_once(&onceToken, ^{
        instance = [[BDWebViewFalconMonitorInternel alloc] init];
    });
    return instance;
}

#pragma mark -falconMonitorInterceptor
- (void)didGetMetaData:(id<IESFalconMetaData>)metaData forRequest:(NSURLRequest *)request isGetMethod:(BOOL)isGetMethod isCustomInterceptor:(BOOL)isCustomInterceptor {
    NSString *urlString = request.URL.absoluteString;
    NSString *pathExtension = request.URL.pathExtension;
    [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
        [self getFalconInfo:metaData forURLString:urlString pathExtension:pathExtension isGetmethod:isGetMethod isCustomInterceptor:isCustomInterceptor];
    }];
}

- (void)webView:(WKWebView *)webView loadRequest:(NSURLRequest *)request metaData:(id<IESFalconMetaData> _Nullable)metaData isCustomInterceptor:(BOOL)isCustomInterceptor {
    if ([self isTurnOnFalconMonitor:webView]) {
        NSString *urlString = request.URL.absoluteString;
        NSString *pathExtension = request.URL.pathExtension;
        [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
            [self getFalconInfo:metaData forURLString:urlString pathExtension:pathExtension isGetmethod:YES isCustomInterceptor:isCustomInterceptor];
        }];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if ([self isTurnOnFalconMonitor:webView]) {
        NSString *urlString = webView.URL.absoluteString;
        [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
            [self reportFalconDataWithWebView:webView urlString:urlString];
        }];
    }
}


- (void)reportDataBeforeLeave:(WKWebView *)webView {
    if ([self isTurnOnFalconMonitor:webView]) {
        NSString *urlString = webView.URL.absoluteString;
        [BDMonitorThreadManager dispatchAsyncHandlerForceOnMonitorThread:^{
            [self reportFalconDataWithWebView:webView urlString:urlString];
        }];
    }   
}


- (void)reportFalconDataWithWebView:(WKWebView *)webView urlString:(NSString *)urlString {
    NSString *urlStr = urlString;
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    NSString *key = @"";
    if(urlStr.length > 0) {
        NSArray *allKeys = [self.falconDict allKeys];
        for(int i = 0; i < allKeys.count; i++) {
            if([urlStr isEqualToString:[self getInformationFromKey:allKeys[i] index:1]]) {
                key = allKeys[i];
                break;
            }
        }
        NSArray *record = [self.falconDict objectForKey:key];
        if(record) {
            [result setObject:@"falconPerf" forKey:@"event_type"];
            [result setObject:record forKey:@"resource_list"];
        } else {
            return;
        }
    }

    if (result.allKeys.count > 0) {
        [webView.performanceDic reportDirectlyWrapNativeInfoWithDic:result];
        if([self.falconDict objectForKey:key]) {
            [self.falconDict removeObjectForKey:key];
        }
    }
}

- (NSString *)getInformationFromKey:(NSString *)key index:(NSInteger)index {
    NSArray *stringArr = [key componentsSeparatedByString:@" "];
    if(index < 0 || index >= stringArr.count) {
        return nil;
    }
    return stringArr[index];
}

- (BOOL)isDupricate:(NSMutableArray *)resourceList requestUrlString:(NSString *)requestUrlString {
    for(int i = 0; i < resourceList.count; i++) {
        if([[resourceList[i] objectForKey:@"resource_url"] isEqualToString:requestUrlString]) {
            return YES;
        }
    }
    return NO;
}

- (void)getFalconInfo:(id<IESFalconMetaData>)metaData forURLString:(NSString *)urlString pathExtension:(NSString *)pathExtension isGetmethod:(BOOL)isGetMethod isCustomInterceptor:(BOOL)isCustomInterceptor{

    NSString *key = @"";
    NSString *mainDocument = [pathExtension containsString:@"htm"] ? urlString : @"";
    NSNumber *packageVersionNumber = [NSNumber numberWithUnsignedLongLong:metaData.statModel.packageVersion];
    NSString *packageVersion = [packageVersionNumber stringValue];
        
    key = [NSString stringWithFormat:@"%@ %@", packageVersion ,mainDocument];

    //如果字典中不存在对应key的元素，则添加，key是packageVersion_htmlURL
    //htmlURL是为了方便聚合整个页面的资源进行上报
    if(![self.falconDict objectForKey:key] && [pathExtension containsString:@"htm"]) {
        [self.falconDict setObject:[[NSMutableArray alloc] init] forKey:key];
        if (self.falconDict.count > self.maxCount) {
            NSInteger trimIndex = self.falconDict.count / 2;
            NSArray *allKeys = [self.falconDict allKeys];
            for (NSInteger i = 0; i < trimIndex; ++i) {
                [self.falconDict removeObjectForKey:allKeys[i]];
            }
        }
    }
    
    //当加载静态资源时，没有主文档URL，因此用packageVersion判断应该是哪个key
    NSMutableArray *resourceList;
    NSArray *allKeys = [self.falconDict allKeys];
    for(int i = 0; i < allKeys.count; i++) {
        if([packageVersion isEqualToString:[self getInformationFromKey:allKeys[i] index:0]]) {
            key = allKeys[i];
            break;
        }
    }
    
    resourceList = [self.falconDict objectForKey:key];
    //可能会调用两到三次falconMetaDataForURLRequest，因此要去重
    if([self isDupricate:resourceList requestUrlString:urlString]) {
        return;
    }
    
    NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
    [info setObject:@(isCustomInterceptor) forKey:@"is_custom_interceptor"];
    if(isGetMethod) {
        if(metaData.falconData.length > 0) {
            [info setObject:@(1) forKey:@"is_get_method"];
            [info setObject:metaData.statModel.resourceURLString?:@"" forKey:@"resource_url"];
            [info setObject:metaData.statModel.offlineRule?:@"" forKey:@"offline_rule"];
            [info setObject:@(metaData.statModel.offlineStatus) forKey:@"offline_status"];
            [info setObject:@(metaData.statModel.offlineDuration) forKey:@"offline_duration"];
            [info setObject:metaData.statModel.channel?:@"" forKey:@"channel"];
            [info setObject:metaData.statModel.mimeType?:@"" forKey:@"mime_type"];
            [info setObject:@(metaData.statModel.errorCode) forKey:@"error_code"];
            [info setObject:@(metaData.statModel.packageVersion) forKey:@"package_version"];
            [info setObject:@(metaData.statModel.falconDataLength) forKey:@"falcon_data_length"];
        } else {
            [info setObject:@(0) forKey:@"falcon_data_length"];
        }
    } else {
        [info setObject:@(0) forKey:@"is_get_method"];
    }
    [resourceList addObject:info];
}

#pragma mark -getter setter
- (NSMutableDictionary *)falconDict {
    if(!_falconDict) {
        _falconDict = [[NSMutableDictionary alloc] init];
    }
    return _falconDict;
}

- (NSInteger)maxCount {
    return 30;
}

- (BOOL)isClassTurnOnFalconMonitor:(Class)cls {
    NSDictionary *setting = [IESLiveWebViewMonitorSettingModel settingMapForWebView:cls];
    BOOL turnOnFalconMonitor = [setting[kBDWMFalconMonitor] boolValue];
    return turnOnFalconMonitor;
}

- (BOOL)isTurnOnFalconMonitor:(WKWebView *)webview {
    if ([webview isKindOfClass:WKWebView.class]) {
        return ![webview bdwm_disableMonitor] && [self isClassTurnOnFalconMonitor:[webview class]];
    }
    return NO;
}

@end

@implementation BDWebViewFalconMonitor

+(BOOL)startMonitorWithClasses:(NSSet *)classes setting:(NSDictionary *)setting {
    BOOL turnOnMonitor = [setting[kBDWMFalconMonitor] boolValue];
    if (!turnOnMonitor) {
        return NO;
    }
    [IESFalconManager addInterceptor:[BDWebViewFalconMonitorInternel shareInstance]];
    [WKWebView addDelegate:[BDWebViewFalconMonitorInternel shareInstance]];
    return YES;
}

@end
