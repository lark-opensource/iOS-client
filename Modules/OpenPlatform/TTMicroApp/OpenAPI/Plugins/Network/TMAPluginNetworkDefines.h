//
//  TMAPluginNetworkDefines.h
//  TTMicroApp
//
//  Created by 刘焱龙 on 2022/9/13.
//

extern NSString * const kTMAPluginNetworkMultipartBoundary;
extern NSString * const kTMAPluginNetworkMonitorMethod;
extern NSString * const kTMAPluginNetworkMonitorDomain;
extern NSString * const kTMAPluginNetworkMonitorPath;
extern NSString * const kTMAPluginNetworkMonitorDuration;
extern NSString * const kTMAPluginNetworkMonitorFileSize;
extern NSString * const kTMAPluginNetworkMonitorRequestID;
extern NSString * const kTMAPluginNetworkMonitorIsPrefetch;
extern NSString * const kTMAPluginNetworkMonitorPrefetchResultDetail;
extern NSString * const kTMAPluginNetworkMonitorUsePrefetch;
extern NSString * const kTMAPluginNetworkMonitorRequestHeader;
extern NSString * const kTMAPluginNetworkMonitorResponseHeader;
extern NSString * const kTMAPluginNetworkMonitorPatchSystemCookies;
extern NSString * const kTMAPluginNetworkMonitorRequestBodyLength;
extern NSString * const kTMAPluginNetworkMonitorResponseBodyLength;
extern NSString * const kTMAPluginNetworkMonitorNQEStatus;
extern NSString * const kTMAPluginNetworkMonitorNQEHttpRtt;
extern NSString * const kTMAPluginNetworkMonitorNQETransportRtt;
extern NSString * const kTMAPluginNetworkMonitorNQEDownstreamThroughput;
extern NSString * const kTMAPluginNetworkMonitorIsBackground;
extern NSString * const kTMAPluginNetworkMonitorNetStatus;
extern NSString * const kTMAPluginNetworkMonitorRustStatus;
extern NSString * const kTMAPluginNetworkMonitorRequestVersion;

extern NSString * const kTMAPluginNetworkMonitorPagePath;
extern NSString * const kTMAPluginNetworkMonitorHttpCode;

typedef enum : NSUInteger {
    SocketCloseTypeUnknown,
    SocketCloseTypeByUser,
    SocketCloseTypeAppInBackground,
    SocketCloseTypeOccurError,
} SocketCloseType;
