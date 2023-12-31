#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKUserContentController (BDWADBlock)

// 初始化规则包,若Gecko资源不存,不会同步等待Gecko包下载
+ (void)bdw_initADBlockRultList:(NSString *_Nonnull)geckoAccessKey;

// 注册RuleList,一般是WebView创建后,根据域名过滤注入规则
- (BOOL)bdw_registerADBlockRultList:(BOOL)useTestRuleList;

// 注销过滤规则
- (BOOL)bdw_unregisterADBlockRultList;

@end

NS_ASSUME_NONNULL_END
