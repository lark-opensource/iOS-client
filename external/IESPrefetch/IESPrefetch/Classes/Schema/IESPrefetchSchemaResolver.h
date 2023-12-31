//
//  IESPrefetchSchemaResolver.h
//  Pods
//
//  Created by yuanyiyang on 2019/12/1.
//

#ifndef IESPrefetchSchemaResolver_h
#define IESPrefetchSchemaResolver_h

/// 数据预取Schema解析器
@protocol IESPrefetchSchemaResolver <NSObject>

/// 是否可以拦截解析该具有多层schema的字符串
- (BOOL)shouldInterceptHierachicalSchema:(NSString *)urlString;

/// 需要将带有多层schema的转化成一层schema
/// e.g.: sslocal://webview?hide_nav_bar=1&disable_bounces=1&url=https%3A%2F%2Fhotsoon.snssdk.com%2Ffalcon%2Flive_inapp%2Fpage%2Fpush_hot%2Findex.html%23%2F%3Fenter_from%3Dpublish_finish%26item_id%3D6724185674863496455
/// 以上就是一个多层schema的例子，本身是一个schema，而其中的参数url也是一层schema。对于数据预取模块需要将内嵌的多层schema打平成一层
/// e.g.: https://hotsoon.snssdk.com/falcon/live_inapp/page/push_hot/index.html#/?enter_from=publish_finish&item_id=6724185674863496455
- (NSURL *)resolveFlatSchema:(NSString *)urlString;

@end

#endif /* IESPrefetchSchemaResolver_h */
