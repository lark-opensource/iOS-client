//
//  BDWebRLMonitorHelper.m
//  BDAlogProtocol
//
//  Created by bytedance on 4/18/22.
//

#import <Foundation/Foundation.h>
#import "BDWebRLMonitorHelper.h"
#import "BDWebResourceMonitorEventType.h"

void bdwResourceLoaderMonitorDic (NSDictionary *dic, bdwRLMonitorBlock callback) {
    if (![dic isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    NSMutableDictionary *resLoaderInfo = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *resInfo = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *resLoadPerf = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *resLoadError = [[NSMutableDictionary alloc] init];
    
    resLoaderInfo[kBDWebviewResLoaderNameKey] = dic[kBDWebviewResLoaderNameKey];
    resLoaderInfo[kBDWebviewResLoaderVersionKey] = dic[kBDWebviewResLoaderVersionKey];
    
    resInfo[kBDWebviewResSrcKey] = dic[kBDWebviewResSrcKey];
    resInfo[kBDWebviewResVersionKey] = dic[kBDWebviewResVersionKey];
    resInfo[kBDWebviewResIDKey] = dic[kBDWebviewResIDKey];
    resInfo[kBDWebviewGeckoChannelKey] = dic[kBDWebviewGeckoChannelKey];
    resInfo[kBDWebviewGeckoBundleKey] = dic[kBDWebviewGeckoBundleKey];
    resInfo[kBDWebviewGeckoAccessKeyKey] = dic[kBDWebviewGeckoAccessKeyKey];
    resInfo[kBDWebviewGeckoSyncUpdateKey] = dic[kBDWebviewGeckoSyncUpdateKey];
    resInfo[kBDWebviewCDNCacheEnableKey] = dic[kBDWebviewCDNCacheEnableKey];
    resInfo[kBDWebviewResSceneKey] = dic[kBDWebviewResSceneKey];
    resInfo[kBDWebviewResTypeKey] = dic[kBDWebviewResTypeKey];
    resInfo[kBDWebviewResFromKey] = dic[kBDWebviewResFromKey];
    resInfo[kBDWebviewIsMemoryKey] = dic[kBDWebviewIsMemoryKey];
    resInfo[kBDWebviewResStateKey] = dic[kBDWebviewResStateKey];
    resInfo[kBDWebviewResTraceIDKey] = dic[kBDWebviewResTraceIDKey];
    resInfo[kBDWebviewResSizeKey] = dic[kBDWebviewResSizeKey];
    resInfo[kBDWebviewFetcherListKey] = dic[kBDWebviewFetcherListKey];
    resInfo[kBDWebviewGeckoConfigFromKey] = dic[kBDWebviewGeckoConfigFromKey];
    resInfo[kBDWebviewExtraKey] = dic[kBDWebviewExtraKey];
    resInfo[kBDWebviewIsPreloadKey] = dic[kBDWebviewIsPreloadKey];
    resInfo[kBDWebviewIsPreloadedKey] = dic[kBDWebviewIsPreloadedKey];
    resInfo[kBDWebviewIsRequestReusedKey] = dic[kBDWebviewIsRequestReusedKey];
    resInfo[kBDWebviewEnableRequestReuseKey] = dic[kBDWebviewEnableRequestReuseKey];

    resLoadPerf[kBDWebviewResLoadStartKey] = dic[kBDWebviewResLoadStartKey];
    resLoadPerf[kBDWebviewResLoadFinishKey] = dic[kBDWebviewResLoadFinishKey];
    resLoadPerf[kBDWebviewInitStartKey] = dic[kBDWebviewInitStartKey];
    resLoadPerf[kBDWebviewInitFinishKey] = dic[kBDWebviewInitFinishKey];
    resLoadPerf[kBDWebviewMemoryStartKey] = dic[kBDWebviewMemoryStartKey];
    resLoadPerf[kBDWebviewMemoryFinishKey] = dic[kBDWebviewMemoryFinishKey];
    resLoadPerf[kBDWebviewGeckoTotalStartKey] = dic[kBDWebviewGeckoTotalStartKey];
    resLoadPerf[kBDWebviewGeckoTotalFinishKey] = dic[kBDWebviewGeckoTotalFinishKey];
    resLoadPerf[kBDWebviewGeckoStartKey] = dic[kBDWebviewGeckoStartKey];
    resLoadPerf[kBDWebviewGeckoFinishKey] = dic[kBDWebviewGeckoFinishKey];
    resLoadPerf[kBDWebviewGeckoUpdateStartKey] = dic[kBDWebviewGeckoUpdateStartKey];
    resLoadPerf[kBDWebviewGeckoUpdateFinishKey] = dic[kBDWebviewGeckoUpdateFinishKey];
    resLoadPerf[kBDWebviewCDNTotalStartKey] = dic[kBDWebviewCDNTotalStartKey];
    resLoadPerf[kBDWebviewCDNTotalFinishKey] = dic[kBDWebviewCDNTotalFinishKey];
    resLoadPerf[kBDWebviewCDNCacheStartKey] = dic[kBDWebviewCDNCacheStartKey];
    resLoadPerf[kBDWebviewCDNCacheFinishKey] = dic[kBDWebviewCDNCacheFinishKey];
    resLoadPerf[kBDWebviewCDNStartKey] = dic[kBDWebviewCDNStartKey];
    resLoadPerf[kBDWebviewCDNFinishKey] = dic[kBDWebviewCDNFinishKey];
    resLoadPerf[kBDWebviewBuiltinStartKey] = dic[kBDWebviewBuiltinStartKey];
    resLoadPerf[kBDWebviewBuiltinFinishKey] = dic[kBDWebviewBuiltinFinishKey];
    
    resLoadError[kBDWebviewResLoaderErrorCodeKey] = dic[kBDWebviewResLoaderErrorCodeKey];
    resLoadError[kBDWebviewResErrorMsgKey] = dic[kBDWebviewResErrorMsgKey];
    resLoadError[kBDWebviewNetLibraryErrorCodeKey] = dic[kBDWebviewNetLibraryErrorCodeKey];
    resLoadError[kBDWebviewHttpStatusCodeKey] = dic[kBDWebviewHttpStatusCodeKey];
    resLoadError[kBDWebviewGeckoLibraryReadErrorCodeKey] = dic[kBDWebviewGeckoLibraryReadErrorCodeKey];
    resLoadError[kBDWebviewGeckoLibraryReadErrorMsgKey] = dic[kBDWebviewGeckoLibraryReadErrorMsgKey];
    resLoadError[kBDWebviewGeckoLibraryUpdateErrorCodeKey] = dic[kBDWebviewGeckoLibraryUpdateErrorCodeKey];
    resLoadError[kBDWebviewGeckoLibraryUpdateErrorMsgKey] = dic[kBDWebviewGeckoLibraryUpdateErrorMsgKey];
    resLoadError[kBDWebviewGeckoErrorCodeKey] = dic[kBDWebviewGeckoErrorCodeKey];
    resLoadError[kBDWebviewGeckoErrorMsgKey] = dic[kBDWebviewGeckoErrorMsgKey];
    resLoadError[kBDWebviewGeckoConfigErrorMsgKey] = dic[kBDWebviewGeckoConfigErrorMsgKey];
    resLoadError[kBDWebviewCDNCacheErrorMsgKey] = dic[kBDWebviewCDNCacheErrorMsgKey];
    resLoadError[kBDWebviewCDNErrorMsgKey] = dic[kBDWebviewCDNErrorMsgKey];
    resLoadError[kBDWebviewBuiltinErrorMsgKey] = dic[kBDWebviewBuiltinErrorMsgKey];
    
    NSMutableDictionary *rlMonitorDic = [[NSMutableDictionary alloc] init];
    rlMonitorDic[kBDWebviewResLoaderInfoKey] = [resLoaderInfo copy];
    rlMonitorDic[kBDWebviewResInfoKey] = [resInfo copy];
    rlMonitorDic[kBDWebviewResLoadPerfKey] = [resLoadPerf copy];
    rlMonitorDic[kBDWebviewResLoadErrorKey] = [resLoadError copy];
    
    NSString *monitorEventName = kBDWebViewMonitorResLoaderPerfEventType;
    NSString *monitorErrorEventName = kBDWebViewMonitorResLoaderErrorEventType;
    NSString *resScene = [dic[kBDWebviewResSceneKey] isKindOfClass:[NSString class]] ? dic[kBDWebviewResSceneKey] : @"other";
    if ([resScene isEqualToString:@"lynx_template"] || [resScene isEqualToString:@"web_main_document"]) {
        monitorEventName = kBDWebViewMonitorResLoaderPerfTemplateEventType;
        monitorErrorEventName = kBDWebViewMonitorResLoaderErrorTemplateEventType;
    }
    
    if (callback) {
        callback(monitorEventName, [rlMonitorDic copy]);
        NSString *resState = [dic[kBDWebviewResStateKey] isKindOfClass:[NSString class]] ? dic[kBDWebviewResStateKey] : @"failed";
        if ([resState isEqualToString:@"failed"]) {
            callback(monitorErrorEventName, [rlMonitorDic copy]);
        }
    }
}
