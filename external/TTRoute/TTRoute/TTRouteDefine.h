//
//  TTRouteDefine.h
//  Pods
//
//  Created by 冯靖君 on 17/2/17.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// SSAppPageManager会根据openURL中的scheme是否与 SSLocalScheme 或 本地定义的identifier为“own”的scheme 相等判断是否为本应用
#ifndef TTLocalScheme
#define TTLocalScheme                                   @"sslocal://"
#endif

#define TTProfileManagerPageKey                         @"profile_manager"
#define TTAccountPageLogicKey                           @"account_manager"
#define TTAuthorityPageLogicKey                         @"authority_manager"
#define TTRecommendPageKey                              @"recommendtab"

#define TTShouldFallBackURLKey                          @"shouldfall"
#define TTFallbackURLKey                                @"fallbackurl"
#define TTWebViewEntryKey                               @"webview"

// 路由action
#define TTRouteReservedActionEntry      @"target"
#define TTRouteReservedActionKey        @"action"

typedef NS_ENUM(NSInteger, TTRouteViewControllerOpenStyle)
{
    TTRouteViewControllerOpenStylePush,
    TTRouteViewControllerOpenStylePresent
};

NS_ASSUME_NONNULL_BEGIN

@interface TTRouteUserInfo : NSObject

@property (nonatomic, copy)   NSString *refer;
@property (nonatomic, strong) NSNumber *animated;
@property (nonatomic, strong) NSDictionary *extra;
@property (nonatomic, strong) NSDictionary *allInfo;

- (instancetype)initWithInfo:(NSDictionary *)info;

@end

static inline TTRouteUserInfo* TTRouteUserInfoWithDict(NSDictionary *dict)
{
    TTRouteUserInfo *info = [[TTRouteUserInfo alloc] initWithInfo:dict];
    return info;
}

// 路由项参数，带上原始URL
@interface TTRouteParamObj : NSObject

// format:   scheme://host/segment?queryParams
@property (nonatomic, strong) NSURL *sourceURL;
@property (nonatomic, copy)   NSString *scheme;
@property (nonatomic, copy)   NSString *host;
@property (nonatomic, copy)   NSString *segment;   //
@property (nonatomic, strong) NSDictionary *queryParams;
@property (nonatomic, strong) TTRouteUserInfo *userInfo;
@property (nonatomic, strong, readonly) NSDictionary *allParams;

- (instancetype)initWithAllParams:(NSDictionary *)params;

- (BOOL)hasRouteAction;

- (NSString *)routeActionIdentifier;

@end

static inline TTRouteParamObj* TTRouteParamObjWithDict(NSDictionary *dict)
{
    TTRouteParamObj *paramObj = [[TTRouteParamObj alloc] initWithAllParams:dict];
    return paramObj;
}

@protocol TTRouteVCHandlerDelegate <NSObject>

@optional

//可选，present时 返回自己所需要的NavigationController实例，未实现则是默认的NavigationController
- (UINavigationController *)presentNavigationControllerForVC:(UIViewController *)vc;

//可选，自定义push操作，未实现则是默认Push效果
- (void)navigationControllerHandlePushVC:(UINavigationController *)navigationController vc:(UIViewController *)vc animated:(BOOL)animated;

//可选，自定义present操作，未实现则是默认Present效果
- (void)navigationControllerHandlePresentVC:(UINavigationController *)navigationController vc:(UIViewController *)vc animated:(BOOL)animated;

@end

@protocol TTRouteInitializeProtocol <NSObject>

@required

// 统一约束的路由对象初始化方法
- (instancetype)initWithRouteParamObj:(nullable TTRouteParamObj *)paramObj;

@optional

// 跳转前目的路由对象修改业务上下文参数
+ (TTRouteUserInfo *)reassginedUserInfoWithParamObj:(nullable TTRouteParamObj *)paramObj;

// 路由跳转前重定向url
+ (NSURL * _Nonnull )redirectURLWithRouteParamObj:(nullable TTRouteParamObj *)paramObj;

// 提供默认跳转方式
+ (TTRouteViewControllerOpenStyle)preferredRouteViewControllerOpenStyle;

// present时 指定自己所需要的NavigationController.
- (NSString *)presentNavigationControllerName;

/**
 非 vc 打开方式
 */
- (void)customOpenTargetWithParamObj:(nullable TTRouteParamObj *)paramObj;

- (id<TTRouteVCHandlerDelegate>)vcHandlerDelegate;

@end

// 业务方可指定路由需要用的navigationController
// 在TTRoute中直接设置属性进行初始化，或通过协议方法作为TTRoute的datasource动态获取最新nav对象
@protocol TTRouteDesignatedNavProtocol <NSObject>

@required

- (UINavigationController *)designatedRouteNavigationController;

@end

@protocol TTRouteLogicDatasource <NSObject>

@optional

- (NSString *)ttRouteLogic_registeredNavigationControllerClass;
- (BOOL)ttRouteLogic_isLogin;
//- (BOOL)ttRouteLogic_detailViewABEnabled;
- (NSString *)ttRouteLogic_classForKey:(NSString *)key;
- (BOOL)ttRouteLogic_isLoginRelatedLogic:(TTRouteParamObj *)paramObj;
- (NSString *)ttRouteLocalHost;

@end

@protocol TTRouteLogicDelegate <NSObject>

@optional

- (void)ttRouteLogic_sendOpenTrackWithFromKey:(NSString *)fromKey;
- (void)ttRouteLogic_configNavigationController:(UINavigationController *)nav;

@end
NS_ASSUME_NONNULL_END
