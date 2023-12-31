//
//  IESPrefetchFlatSchema.h
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/11/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 数据预取模块定义的URL标准schema，数据预取模块只接受一层schema，多层schema也只使用第一层schema
/// e.g.: sslocal://webview?hide_nav_bar=1&disable_bounces=1&url=https%3A%2F%2Fhotsoon.snssdk.com%2Ffalcon%2Flive_inapp%2Fpage%2Fpush_hot%2Findex.html%23%2F%3Fenter_from%3Dpublish_finish%26item_id%3D6724185674863496455
/// 以上就是一个多层schema的例子，本身是一个schema，而其中的参数url也是一层schema。对于数据预取模块需要将内嵌的多层schema打平成一层
/// e.g.: https://hotsoon.snssdk.com/falcon/live_inapp/page/push_hot/index.html#/?enter_from=publish_finish&item_id=6724185674863496455
@interface IESPrefetchFlatSchema : NSObject

/// URI标准中的scheme协议，不能为nil
@property (nonatomic, copy) NSString *scheme;
/// host部分
@property (nonatomic, copy) NSString *host;
/// path部分，可能为nil
@property (nonatomic, copy) NSString *path;
/// Hash部分，可能为nil，存在 ?query#/fragment 和 #/fragment?query两种情况
@property (nonatomic, copy) NSString *fragment;
/// 按key/value解析过后的参数，不会自动decode。
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *queryItems;
/// 按照路由规则解析后得到的path参数
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *pathVariables;

+ (instancetype)schemaWithURL:(NSURL *)url;

- (instancetype)initWithURL:(NSURL *)url NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (NSString *)urlString;

@end

NS_ASSUME_NONNULL_END
