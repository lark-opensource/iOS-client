#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDWADBlockUtil : NSObject

// 获取ADBlock白名单(域名)
+ (NSArray *)adBlockDomainWhiteList;

// 获取广告过滤规则(未编译的原生规则字符串)
+ (NSString *)adBlockRuleList;

// 获取指定的规则文件内容(json)
+ (NSString *)adBlockResourceWithName:(NSString *)name;

// 获取预编译规则文件生成的WKContentRuleListStore
+ (nullable WKContentRuleListStore *)precompiledAdblockStore API_AVAILABLE(ios(11.0));

// 上报广告过滤相关状态信息
+ (void)trackADBlockStatus;

@end

NS_ASSUME_NONNULL_END
