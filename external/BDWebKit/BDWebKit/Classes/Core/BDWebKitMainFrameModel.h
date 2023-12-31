//
//  BDWebKitMainFrameModel.h
//  Pods
//
//  Created by bytedance on 4/12/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 标记主文档加载情况
typedef NS_ENUM(NSUInteger, BDWebKitMainFrameStatus) {
    BDWebKitMainFrameStatusNone,
    BDWebKitMainFrameStatusUseFalconPlugin,
    BDWebKitMainFrameStatusUseForestPlugin,
    BDWebKitMainFrameStatusUseSchemeHandler,
    BDWebKitMainFrameStatusUseFalconURLProtocol
};

// Main frame loading progress event
extern NSString *const kBDWMainFrameReceiveLoadRequestEvent;
extern NSString *const kBDWMainFrameStartProvisionalNavigationEvent;
extern NSString *const kBDWMainFrameReceiveServerRedirectCount;
extern NSString *const kBDWMainFrameReceiveServerRedirectForProvisionalNavigationEvent;
extern NSString *const kBDWMainFrameReceiveNavigationResponseEvent;
extern NSString *const kBDWMainFrameCommitNavigationEvent;
extern NSString *const kBDWMainFrameFinishNavigationEvent;

@interface BDWebKitMainFrameModel : NSObject

@property (nonatomic, assign) BOOL loadFinishWithLocalData;

@property (nullable, atomic, copy) NSString *latestWebViewURLString;

@property (nonatomic) BDWebKitMainFrameStatus mainFrameStatus;

// 从资源加载器获取的字段, Key参考: BDWebResourceMonitorEventType.h
@property (nullable, nonatomic, strong) NSDictionary *mainFrameStatModel;

// loadRequest开始记录时间戳,key携带 'bdw_' 前缀, 即kBDWMainFrameXXXEvent
// 若使用TTNet完成在线请求,会补充TTNet埋点,参考:https://bytedance.feishu.cn/wiki/wikcnjabACtIn6bDSZsifuoPE6v
@property (nullable, nonatomic, strong) NSMutableDictionary *mainFramePerformanceTimingModel;

@end

NS_ASSUME_NONNULL_END
