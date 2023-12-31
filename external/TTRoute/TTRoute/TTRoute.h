//
//  TTRoute.h
//  Pods
//
//  Created by 冯靖君 on 17/3/19.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TTRouteDefine.h"

/*使用说明
 1.registerRouteEntry或registerWithRouteEntries方法注册路由，或者使用RegisterRouteObjWithURL()宏直接注册当前类名到路由
 2.openURL执行路由，支持：
 在block回调中实现自定义action
 - openURLBy...方式跳转路由，适合vc路由场景。其中openURLByViewController方法将根据preferredRouteViewControllerOpenStyle的值确定打开方式，默认是push
 - routeObjWithOpenURL方式获取映射到的路由对象
 3.路由对象统一使用<TTRouteInitializeProtocol>定义的initWithRouteParamObj方法作为入口，参数是TTRouteParamObj对象，提供通过dict初始化的方法，预留refer和animated两个key
 4.给TTRoute设置navigationController。可通过给TTRoute单例对象的initialRouteNavigationController属性指定全局nav，或设置实现了<TTRouteDesignatedNavProtocol>协议的designatedNavDatasource代理对象，通过其designatedRouteNavigationController方法提供实时datasource
 5.TTRouteLogicDelegate和TTRouteLogicDatasource为头条业务钩子，新业务插件可不care
 6.作为基本约定，不支持路由url中自定义scheme，必须为sslocal或snssdk+ownScheme形式
 7.路由支持注册host/segment格式，解析时优先做两端匹配再fallback到单一的host匹配
 8.路由支持重定向。实现TTRouteInitializeProtocol协议的redirectURLWithRouteParamObj方法返回重新构造的URL，路由会在跳转到原entry前重定向
 9.路由预留query参数@"openurl",作为查找native页面失败或指定shouldfall=1时，路由fallback到webView展示的url key
 注意：fallback功能必须在业务插件引入了TTWebView组件的前提下才会生效，否则不做任何处理
 
 updated 2017.11.23, 支持注册block，预留host为target，同名普通路由将中assertion。schema格式：sslocal://target?action=identifier&param0=abc&param1=def, identifier为注册的block唯一标识，参数封装为字典传入block
 */

// 注册请联系框架开发写入统一注册表，不要自行调用此类方法，此类方法不删除是考虑到 支持 动态化下发代码 的因素
#define RegisterRouteObjWithEntryName(entryName)   [TTRoute registerRouteEntry:entryName withObjClass:self.class]
// 注册请联系框架开发写入统一注册表，不要自行调用此类方法，此类方法不删除是考虑到 支持 动态化下发代码 的因素
#define UnregisterRouteObjForEntryName(entryName)  [TTRoute unregisterRouteEntry:entryName]

@class BDBizApp;

@protocol TTRouteBizAppManagerDelegate <NSObject>

- (void)willShowAppVC:(BDBizApp *)app rootVC:(UIViewController *)rootVC;
- (void)didShowAppVC:(BDBizApp *)app;

@end

typedef void (^TTRouteAction)(NSDictionary *params);

// 对外暴露TTRouteObject对象，包含实例对象及参数
@interface TTRouteObject : NSObject

@property (nonatomic, strong) NSObject <TTRouteInitializeProtocol> *instance;
@property (nonatomic, strong) TTRouteParamObj *paramObj;
@property (nonatomic, copy) TTRouteAction action;

@end    

typedef void (^TTRouteObjHandler)(TTRouteObject *routeObj);
typedef void (^TTRouteVCPushHandler)(UINavigationController *nav, TTRouteObject *routeObj);

@interface TTRoute : NSObject

@property (nonatomic, weak) NSObject <TTRouteBizAppManagerDelegate> *bizAppManagerDelegate;
@property (nonatomic, weak) NSObject <TTRouteLogicDelegate>   *delegate;
@property (nonatomic, weak) NSObject <TTRouteLogicDatasource> *datasource;
@property (nonatomic, weak) NSObject <TTRouteDesignatedNavProtocol> *designatedNavDatasource;
@property (nonatomic, weak) UINavigationController *initialRouteNavigationController;

+ (TTRoute *)sharedRoute;

// scheme是否能被TTRoute处理
+ (BOOL)conformsToRouteWithScheme:(NSString *)scheme;

// 注册路由  usually used in +load
// entry format: host or host/segment
// 注册请联系框架开发写入统一注册表，不要自行调用此类方法，此类方法不删除是考虑到 支持 动态化下发代码 的因素
+ (void)registerRouteEntry:(NSString *)entryName withObjClass:(Class)objClass;

// 批量注册路由 not in +load
// 仅限框架开发调用，业务方注册请联系框架开发写入统一注册表，不要自行调用此类方法，此类方法不删除是考虑到 支持 动态化下发代码 的因素
+ (void)registerWithRouteEntries:(NSDictionary<NSString *,NSString *> *)routeTable;
// 注册请联系框架开发写入统一注册表，不要自行调用此类方法，此类方法不删除是考虑到 支持 动态化下发代码 的因素
+ (void)unregisterRouteEntry:(NSString *)entryName;

//执行路由
- (BOOL)canOpenURL:(NSURL *)url;
- (BOOL)openURL:(NSURL *)url userInfo:(TTRouteUserInfo *)userInfo objHandler:(TTRouteObjHandler)handler;

//便捷接口
// ViewController native transition
- (BOOL)openURLByViewController:(NSURL *)url userInfo:(TTRouteUserInfo *)userInfo;
- (BOOL)openURLByPushViewController:(NSURL *)url;
- (BOOL)openURLByPushViewController:(NSURL *)url userInfo:(TTRouteUserInfo *)userInfo;
- (BOOL)openURLByPushViewController:(NSURL *)url userInfo:(TTRouteUserInfo *)userInfo pushHandler:(TTRouteVCPushHandler)handler;  //自定义push操作，比如转场动画
- (BOOL)openURLByPushViewController:(NSURL *)url userInfo:(TTRouteUserInfo *)userInfo pushHandler:(TTRouteVCPushHandler)handler app:(BDBizApp *)app vcHandlerDelegate:(id<TTRouteVCHandlerDelegate>)vcHandlerDelegate;
- (BOOL)openURLByPresentViewController:(NSURL *)url userInfo:(TTRouteUserInfo *)userInfo;
- (BOOL)openURLByPresentViewController:(NSURL *)url userInfo:(TTRouteUserInfo *)userInfo app:(BDBizApp *)app vcHandlerDelegate:(id<TTRouteVCHandlerDelegate>)vcHandlerDelegate;

// return routed object
- (TTRouteObject *)routeObjWithOpenURL:(NSURL *)url userInfo:(TTRouteUserInfo *)userInfo;

// 只返回解析路由得到的routeParams
- (TTRouteParamObj *)routeParamObjWithURL:(NSURL *)url;

// 执行route action
- (BOOL)executeRouteActionURL:(NSURL *)url userInfo:(TTRouteUserInfo *)userInfo;

// 注册block行为，需指定identifier作为标识
+ (void)registerAction:(TTRouteAction)action withIdentifier:(NSString *)identifier;
+ (void)unregisterActionWithIdentifier:(NSString *)identifier;

@end
