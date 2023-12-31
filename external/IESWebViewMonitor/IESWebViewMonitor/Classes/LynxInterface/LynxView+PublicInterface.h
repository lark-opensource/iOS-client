//
//  LynxView+PublicInterface.h
//  IESWebViewMonitor
//
//  Created by bytedance on 2020/10/21.
//

#import <Lynx/LynxView.h>

NS_ASSUME_NONNULL_BEGIN

@interface LynxView (PublicInterface)

// 绑定kv到上报的nativebase中去，注意，此处配置建议kv都是用string类型，是可枚举的值，如bizId，ABTest等，避免识别问题，此处block会被持有，避免在内部使用webview造成循环引用。
- (void)attachNativeBaseContextBlock:(NSDictionary *(^)(NSString *url))block;

// 绑定虚拟aid到对应容器上
- (void)attachVirtualAid:(NSString *)virtualAid;
- (NSString *)fetchVirtualAid;

// 绑定容器UUID到实例
- (void)attachContainerUUID:(NSString *)containerUUID;

// 上报ContainerError事件
- (void)reportContainerError:(nullable NSString *)virtualAid errorCode:(NSInteger)code errorMsg:(nullable NSString *)msg bizTag:(nullable NSString *)bizTag;

- (NSString *)bdlm_fetchCurrentUrl;

@end

NS_ASSUME_NONNULL_END
