//
//  TTMicroAppNetwork.h
//  Timor
//
//  Created by muhuai on 2017/11/29.
//  Copyright © 2017年 muhuai. All rights reserved.
//

#import "BDPPluginBase.h"
typedef NS_ENUM(NSUInteger, BDPNetworkRequestType) {
    BDPNetworkRequestTypeUnknown = 0,
    BDPNetworkRequestTypeRequest,
    BDPNetworkRequestTypeDownload,
    BDPNetworkRequestTypeUpload
};

@interface TMAPluginNetwork : BDPPluginBase

// 公开
BDP_EXPORT_HANDLER(createRequestTask)
BDP_EXPORT_HANDLER(createUploadTask)

/// 优先更换download和operate为BDP_HANDLER
BDP_HANDLER(createDownloadTask)
BDP_HANDLER(operateDownloadTask)
BDP_HANDLER(operateRequestTask)
BDP_HANDLER(operateUploadTask)

@end

NS_ASSUME_NONNULL_BEGIN
@interface TMAPluginNetwork (Utils)
+ (BDPTracing *)generateRequestTracing:(BDPUniqueID *)uniqueID;

/// tt.request 相关 URLSession 配置，隔离状态下禁用原生 cookie 设置
+ (NSURLSessionConfiguration *)urlSessionConfiguration;

+ (void)handleCookieWithResponse: (NSHTTPURLResponse *)response
                        uniqueId: (OPAppUniqueID *)uniqueId;
    
+ (NSDictionary *)processHeader:(NSDictionary *)header
                      URLString:(NSString *)url
                           type:(BDPNetworkRequestType)type
                        tracing:(BDPTracing *)tracing
                       uniqueID:(BDPUniqueID *)uniqueID
       patchCookiesMonitorValue:(NSString * _Nullable *)patchCookiesMonitorValue;
@end
NS_ASSUME_NONNULL_END
