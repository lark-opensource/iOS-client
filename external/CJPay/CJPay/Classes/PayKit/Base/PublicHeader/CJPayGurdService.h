//
//  CJPayGurdService.h
//  CJPay
//
//  Created by 易培淮 on 2020/12/09.
//

#ifndef CJPayGurdService_h
#define CJPayGurdService_h

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayGurdService <NSObject>

// 是否聚合请求
- (void)i_enableMergeGurdRequest:(BOOL)enable;
// 启用Gecko离线化
- (void)i_enableGurdOfflineAfterSettings;
// 切到消息tab时触发
- (void)syncResourcesWhenSelectNotify;
// 切到我的tab时触发
- (void)syncResourcesWhenSelectHomepage;

// 获取图片URL
- (nullable NSString *)i_getImageUrlOrName:(NSString *_Nullable)imageName;

- (NSDictionary *)i_getPerformanceMonitorConfigDictionary;

@end

NS_ASSUME_NONNULL_END

#endif /* CJPayGurdService_h */
