//
//  TTRoute.m
//  Pods
//
//  Created by 冯靖君 on 17/3/19.
//
//

#import "TTRoute.h"

#define tt_isEmptyString(str) (!str || ![str isKindOfClass:[NSString class]] || str.length == 0)

@implementation TTRouteObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@\nrouteObject:%@\nrouteParam:%@\nrouteAction:%d", [super description], self.instance, [self.paramObj description], self.action != nil];
}

@end

@interface TTRoute ()

@property (nonatomic, weak)   UIWindow *appWindow;
@property (nonatomic, strong) NSMutableDictionary <NSString*, TTRouteParamObj*> *cachedRouteParamObjDict;
@property (nonatomic, assign, getter=isPresenting) BOOL presenting;

@end

@implementation TTRoute

#pragma mark - public

+ (TTRoute *)sharedRoute
{
    static TTRoute *sharedRoute;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedRoute = [[TTRoute alloc] init];
        sharedRoute.appWindow = [[[UIApplication sharedApplication] delegate] window];
    });
    return sharedRoute;
}

- (UIWindow *)appWindow
{
    if (!_appWindow) {
        _appWindow = [[[UIApplication sharedApplication] delegate] window];
    }
    return _appWindow;
}

+ (BOOL)conformsToRouteWithScheme:(NSString *)scheme
{
    if (!scheme || tt_isEmptyString(scheme)) {
        return NO;
    }
    
    NSString *snssdkScheme = nil;
    NSArray *schemes = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleURLTypes"];
    for (NSDictionary *tDict in schemes) {
        NSString *schemeID = [tDict objectForKey:@"CFBundleURLName"];
        if ([schemeID isEqualToString:@"own"]) {
            NSArray *snssdkSchemes = [tDict objectForKey:@"CFBundleURLSchemes"];
            if ([snssdkSchemes count] > 0) {
                snssdkScheme = [NSString stringWithFormat:@"%@://", [snssdkSchemes objectAtIndex:0]];
            }
        }
    }
    
    return [scheme isEqualToString:[[self sharedRoute] localHost]] || [scheme isEqualToString:snssdkScheme];
}

+ (void)registerRouteEntry:(NSString *)entryName withObjClass:(Class)objClass
{
    //允许覆盖，热修等场景
//    NSAssert(!self.routeTables[entryName], @"try register duplicated key is not permitted");
    NSAssert(![entryName isEqualToString:TTRouteReservedActionEntry], @"try register reserved key \"%@\" is not permitted, try again", TTRouteReservedActionEntry);
    if (!tt_isEmptyString(entryName) && objClass) {
        BOOL available = [objClass conformsToProtocol:@protocol(TTRouteInitializeProtocol)] || [objClass instancesRespondToSelector:@selector(initWithRouteParamObj:)];
        NSAssert(available, @"obj register to route but no designated initialization implemented!");
        [self.routeTables setValue:NSStringFromClass(objClass) forKey:entryName];
    }
}

+ (void)registerWithRouteEntries:(NSDictionary<NSString *,NSString *> *)routeTable
{
    //允许覆盖，热修等场景
    [routeTable enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull entryName, NSString * _Nonnull routeObjClassName, BOOL * _Nonnull stop) {
        [self registerRouteEntry:entryName withObjClass:NSClassFromString(routeObjClassName)];
    }];
    //Debug模式下校验
//#ifdef DEBUG
//    for (NSString *hostName in self.routeTables) {
//        NSString *desc = [NSString stringWithFormat:@"RuntimeOpps: class %@ for host %@ not exists!",[self.routeTables objectForKey:hostName],hostName];
//        NSAssert(nil != NSClassFromString([self.routeTables objectForKey:hostName]), desc);
//    }
//#endif
}

+ (void)unregisterRouteEntry:(NSString *)entryName
{
    if (self.routeTables[entryName]) {
        [self.routeTables removeObjectForKey:entryName];
    }
}

- (BOOL)canOpenURL:(NSURL *)url
{
    NSString *urlString = [url absoluteString];
    if (!url || tt_isEmptyString(urlString)) {
        return NO;
    }
    
    //处理url中的+i
    [self _handlePlusSymbolInURLString:&urlString];
    url = [NSURL URLWithString:urlString];
    
    TTRouteParamObj *paramObj = [self _routeParamObjWithURL:url];
    if (![self.class conformsToRouteWithScheme:paramObj.scheme]) {
        return NO;
    }
    if (!tt_isEmptyString(paramObj.host)) {
        if ([paramObj hasRouteAction]) {
            // 先监测是否为route action
            NSString *actionValue = [paramObj routeActionIdentifier];
            return !tt_isEmptyString(actionValue) && [[TTRoute actionTables] objectForKey:actionValue];
        }
        
        NSString *objClassName = nil;
        if (_datasource && [_datasource respondsToSelector:@selector(ttRouteLogic_classForKey:)]) {
            objClassName = [_datasource ttRouteLogic_classForKey:paramObj.host];
        }
        
        //动态注册的schema会覆盖配置文件的同名schema
        NSString *routeObjClassNameFromTable = [self.class _routeObjClassNameForParamObj:paramObj];
        if (!tt_isEmptyString(routeObjClassNameFromTable)) {
            objClassName = routeObjClassNameFromTable;
        }
        
        if (!tt_isEmptyString(objClassName)) {
            return YES;
        }
        
        if ([paramObj.host isEqualToString:@"open"]) {
            return YES;
        }
        
        if ([self _canFallbackWithParamObj:paramObj]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)openURL:(NSURL *)url userInfo:(TTRouteUserInfo *)userInfo objHandler:(TTRouteObjHandler)handler
{
    if (![self canOpenURL:url]) {
        return NO;
    }
    
    TTRouteObject *obj = [self routeObjWithOpenURL:url userInfo:userInfo];
    if (obj) {
        if (obj.instance) {
            if (handler && obj) {
                handler(obj);
                return YES;
            } else {
                return nil != obj;
            }
        } else {
            return [self _executeActionWithRouteObj:obj];
        }
    } else {
        return NO;
    }
}

- (BOOL)openURLByViewController:(NSURL *)url userInfo:(TTRouteUserInfo *)userInfo
{
    if (![self canOpenURL:url]) {
        return NO;
    }
    
    TTRouteObject *obj = [self routeObjWithOpenURL:url userInfo:userInfo];
    if (obj) {
        if (obj.instance) {
            if (![obj.instance isKindOfClass:[UIViewController class]]) {
                if([obj.instance respondsToSelector:@selector(customOpenTargetWithParamObj:)]){
                    [obj.instance customOpenTargetWithParamObj:obj.paramObj];
                    return YES;
                }else{
                    NSAssert(NO, @"try to open an obj which is not a viewController or respondes to customOpenTargetWithParamObj!");
                    return NO;
                }
            }
            
            // 特殊业务处理，暂保留
            BOOL isPadDevice = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
            NSString *backButtonIconKey = @"back_button_icon";
            NSMutableDictionary *allDict = [obj.paramObj.queryParams mutableCopy];
            NSMutableDictionary *innerDict = [NSMutableDictionary dictionary];
            [innerDict setValue:obj.paramObj.userInfo.refer forKey:@"refer"];
            [innerDict setValue:obj.paramObj.userInfo.animated forKey:@"animated"];
            [allDict addEntriesFromDictionary:innerDict];
            [allDict addEntriesFromDictionary:obj.paramObj.userInfo.extra];
            if ([[allDict allKeys] containsObject:backButtonIconKey] && !isPadDevice) {
                NSString *backButtonIcon = nil;
                id value = [allDict objectForKey:backButtonIconKey];
                if (value && [value isKindOfClass:[NSString class]]) {
                    backButtonIcon = value;
                }else if(value && [value isKindOfClass:[NSNumber class]]){
                    backButtonIcon = [value stringValue];
                }else{
                    backButtonIcon = nil;
                }
                if ([backButtonIcon isEqualToString:@"down_arrow"] ||
                    [backButtonIcon isEqualToString:@"close"]) {
                    return [self _openViewControllerForRouteObj:obj byOpenStyle:TTRouteViewControllerOpenStylePush app:nil vcHandlerDelegate:nil];
                }
            }
            
            // preferredRouteViewControllerOpenStyle取值决定打开方式，默认push
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
            if ([obj.instance.class respondsToSelector:@selector(preferredRouteViewControllerOpenStyle)]) {
                TTRouteViewControllerOpenStyle style = (TTRouteViewControllerOpenStyle)[obj.instance.class performSelector:@selector(preferredRouteViewControllerOpenStyle)];
#pragma clang diagnostic pop
                return [self _openViewControllerForRouteObj:obj byOpenStyle:style app:nil vcHandlerDelegate:nil];
            }
            else {
                return [self _openViewControllerForRouteObj:obj byOpenStyle:TTRouteViewControllerOpenStylePush app:nil vcHandlerDelegate:nil];
            }
        } else {
            return [self _executeActionWithRouteObj:obj];
        }
    } else {
        return NO;
    }
}

- (BOOL)openURLByPushViewController:(NSURL *)url
{
    return [self openURLByPushViewController:url userInfo:nil];
}

- (BOOL)openURLByPushViewController:(NSURL *)url userInfo:(TTRouteUserInfo *)userInfo
{
    return [self openURLByPushViewController:url userInfo:userInfo pushHandler:nil];
}

- (BOOL)openURLByPushViewController:(NSURL *)url userInfo:(TTRouteUserInfo *)userInfo pushHandler:(TTRouteVCPushHandler)handler
{
    return [self openURLByPushViewController:url userInfo:userInfo pushHandler:handler app:nil vcHandlerDelegate:nil];
}

- (BOOL)openURLByPushViewController:(NSURL *)url userInfo:(TTRouteUserInfo *)userInfo pushHandler:(TTRouteVCPushHandler)handler app:(BDBizApp *)app vcHandlerDelegate:(id<TTRouteVCHandlerDelegate>)vcHandlerDelegate
{
    if (![self canOpenURL:url]) {
        return NO;
    }
    
    TTRouteObject *obj = [self routeObjWithOpenURL:url userInfo:userInfo];
    if (obj) {
        if (obj.instance) {
            if (![obj.instance isKindOfClass:[UIViewController class]]) {
                if ([obj.instance respondsToSelector:@selector(customOpenTargetWithParamObj:)]) {
                    [obj.instance customOpenTargetWithParamObj:obj.paramObj];
                    if (app && self.bizAppManagerDelegate && [self.bizAppManagerDelegate respondsToSelector:@selector(didShowAppVC:)]) {
                        [self.bizAppManagerDelegate didShowAppVC:app];
                    }
                    return YES;
                } else {
                    NSAssert(NO, @"try to open an obj which is not a viewController or respondes to customOpenTargetWithParamObj!");
                    return NO;
                }
            } else {
                return [self _openViewControllerForRouteObj:obj byOpenStyle:TTRouteViewControllerOpenStylePush pushHandler:handler app:app vcHandlerDelegate:vcHandlerDelegate];
            }
        } else {
            return [self _executeActionWithRouteObj:obj];
        }
    } else {
        return NO;
    }
}

- (BOOL)openURLByPresentViewController:(NSURL *)url userInfo:(TTRouteUserInfo *)userInfo
{
    return [self openURLByPresentViewController:url userInfo:userInfo app:nil vcHandlerDelegate:nil];
}

- (BOOL)openURLByPresentViewController:(NSURL *)url userInfo:(TTRouteUserInfo *)userInfo app:(BDBizApp *)app vcHandlerDelegate:(id<TTRouteVCHandlerDelegate>)vcHandlerDelegate
{
    if (![self canOpenURL:url]) {
        return NO;
    }
    
    TTRouteObject *obj = [self routeObjWithOpenURL:url userInfo:userInfo];
    if (obj) {
        if (obj.instance) {
            if (![obj.instance isKindOfClass:[UIViewController class]]) {
                if ([obj.instance respondsToSelector:@selector(customOpenTargetWithParamObj:)]) {
                    [obj.instance customOpenTargetWithParamObj:obj.paramObj];
                    if (app && self.bizAppManagerDelegate && [self.bizAppManagerDelegate respondsToSelector:@selector(didShowAppVC:)]) {
                        [self.bizAppManagerDelegate didShowAppVC:app];
                    }
                    return YES;
                } else {
                    NSAssert(NO, @"try to open an obj which is not a viewController or respondes to customOpenTargetWithParamObj!");
                    return NO;
                }
            } else {
                return [self _openViewControllerForRouteObj:obj byOpenStyle:TTRouteViewControllerOpenStylePresent app:app vcHandlerDelegate:vcHandlerDelegate];
            }
        } else {
            return [self _executeActionWithRouteObj:obj];
        }
    } else {
        return NO;
    }
}

- (BOOL)_openViewControllerForRouteObj:(TTRouteObject *)obj byOpenStyle:(TTRouteViewControllerOpenStyle)style app:(BDBizApp *)app vcHandlerDelegate:(id<TTRouteVCHandlerDelegate>)vcHandlerDelegate
{
    return [self _openViewControllerForRouteObj:obj byOpenStyle:style pushHandler:nil app:app vcHandlerDelegate:vcHandlerDelegate];
}

- (BOOL)_openViewControllerForRouteObj:(TTRouteObject *)obj byOpenStyle:(TTRouteViewControllerOpenStyle)style pushHandler:(TTRouteVCPushHandler)handler app:(BDBizApp *)app vcHandlerDelegate:(id<TTRouteVCHandlerDelegate>)vcHandlerDelegate
{
    UINavigationController *nav = [self _navigationControllerForRoute];
    if (!nav) {
        NSAssert(NO, @"try to open an obj but no navigationController designated!");
        return NO;
    }
    
    UIViewController<TTRouteInitializeProtocol> *controller = (UIViewController<TTRouteInitializeProtocol> *)obj.instance;
    
    if (!vcHandlerDelegate && [controller respondsToSelector:@selector(vcHandlerDelegate)]) {
        vcHandlerDelegate = [controller performSelector:@selector(vcHandlerDelegate)];
    }
    
    if (app && self.bizAppManagerDelegate && [self.bizAppManagerDelegate respondsToSelector:@selector(willShowAppVC:rootVC:)]) {
        [self.bizAppManagerDelegate willShowAppVC:app rootVC:controller];
    }
    
    [self _handlePresentedViewController:&nav];
    
    BOOL animated = obj.paramObj.userInfo.animated ? [obj.paramObj.userInfo.animated boolValue] : YES;
    //自定义动画的VC操作没有等结束后才做bizAppManagerDelegate相关处理，而是调用完自定义方法后直接做bizAppManagerDelegate相关处理，是避免业务自定义动画方法中不回调TTRoute导致栈乱
    if (TTRouteViewControllerOpenStylePush == style) {
        //优先走自定义push动作
        if (handler) {
            handler(nav, obj);
        } else if (vcHandlerDelegate && [vcHandlerDelegate respondsToSelector:@selector(navigationControllerHandlePushVC:vc:animated:)]) {
            [vcHandlerDelegate navigationControllerHandlePushVC:nav vc:(UIViewController *)obj.instance animated:animated];
        } else {
            [nav pushViewController:controller animated:animated];
        }
        if (app && self.bizAppManagerDelegate && [self.bizAppManagerDelegate respondsToSelector:@selector(didShowAppVC:)]) {
            [self.bizAppManagerDelegate didShowAppVC:app];
        }
        
    }
    else {
        UINavigationController *presentedNav;
        if (vcHandlerDelegate && [vcHandlerDelegate respondsToSelector:@selector(presentNavigationControllerForVC:)]) {
            presentedNav = [vcHandlerDelegate presentNavigationControllerForVC:controller];
        }
        if (![presentedNav isKindOfClass:[UINavigationController class]]) {
            NSString *navVcClassString = @"BDNavigationController";
            if (_datasource && [_datasource respondsToSelector:@selector(ttRouteLogic_registeredNavigationControllerClass)]) {
                navVcClassString = [_datasource ttRouteLogic_registeredNavigationControllerClass];
            }
            
            if ([controller respondsToSelector:@selector(presentNavigationControllerName)]) {
                navVcClassString = [controller presentNavigationControllerName];
            }
            
            if (![NSClassFromString(navVcClassString) instancesRespondToSelector:@selector(initWithRootViewController:)]) {
                navVcClassString = NSStringFromClass(UINavigationController.class);
            }
            presentedNav = [[NSClassFromString(navVcClassString) alloc] initWithRootViewController:controller];
        }
        if (_delegate && [_delegate respondsToSelector:@selector(ttRouteLogic_configNavigationController:)]) {
            [_delegate ttRouteLogic_configNavigationController:presentedNav];
        }
        
        NSObject <UIViewControllerTransitioningDelegate> *transitioningDelegate = [obj.paramObj.userInfo.allInfo valueForKey:@"transitioningDelegate"];
        if (transitioningDelegate != nil) {
            presentedNav.transitioningDelegate = transitioningDelegate;
            presentedNav.modalPresentationStyle = UIModalPresentationCustom;
        }
        self.presenting = YES;
        BOOL animated = obj.paramObj.userInfo.animated ? [obj.paramObj.userInfo.animated boolValue] : YES;
        if (vcHandlerDelegate && [vcHandlerDelegate respondsToSelector:@selector(navigationControllerHandlePresentVC:vc:animated:)]) {
            [vcHandlerDelegate navigationControllerHandlePresentVC:nav vc:presentedNav animated:animated];
            self.presenting = NO;
            if (app && self.bizAppManagerDelegate && [self.bizAppManagerDelegate respondsToSelector:@selector(didShowAppVC:)]) {
                [self.bizAppManagerDelegate didShowAppVC:app];
            }
        } else {
            [nav presentViewController:presentedNav animated:animated completion:^{
                self.presenting = NO;
                if (app && self.bizAppManagerDelegate && [self.bizAppManagerDelegate respondsToSelector:@selector(didShowAppVC:)]) {
                    [self.bizAppManagerDelegate didShowAppVC:app];
                }
            }];
        }
    }
    return YES;
}

- (TTRouteObject *)routeObjWithOpenURL:(NSURL *)url userInfo:(TTRouteUserInfo *)userInfo
{
    NSString *urlString = [url absoluteString];
    if (!url || tt_isEmptyString(urlString)) {
        NSAssert(NO, @"url为空，请确保url创建成功!");
        return nil;
    }
    
    //处理url中的+
    [self _handlePlusSymbolInURLString:&urlString];
    url = [NSURL URLWithString:urlString];
    
    //解析url并映射到param对象
    TTRouteParamObj *paramObj = [self _routeParamObjWithURL:url];
    if ([paramObj hasRouteAction]) {
        NSAssert(![userInfo.allInfo.allKeys containsObject:TTRouteReservedActionKey], @"custom userInfo contains reserved key \"%@\", please remove it", TTRouteReservedActionKey);
    }
    paramObj.userInfo = userInfo;
    
    Class classInstance = nil;
    TTRouteAction action = nil;
    id instance = nil;
    
    if ([paramObj hasRouteAction]) {
        // 路由action
        action = [[TTRoute actionTables] objectForKey:[paramObj routeActionIdentifier]];
    }
    else {
        // 页面路由
        if (_datasource && [_datasource respondsToSelector:@selector(ttRouteLogic_isLoginRelatedLogic:)]) {
            if ([_datasource ttRouteLogic_isLoginRelatedLogic:paramObj]) {
                return nil;
            }
        }
        
        NSString *host = paramObj.host;
        if ([host isEqualToString:@"open"]) {
            NSString *from = [paramObj.queryParams objectForKey:@"from"];
            if (!tt_isEmptyString(from)) {
                if (_delegate && [_delegate respondsToSelector:@selector(ttRouteLogic_sendOpenTrackWithFromKey:)]) {
                    [_delegate ttRouteLogic_sendOpenTrackWithFromKey:from];
                }
            }
            return nil;
        }
        
        NSString *routeObjClassName = nil;
        if (_datasource && [_datasource respondsToSelector:@selector(ttRouteLogic_classForKey:)]) {
            routeObjClassName = [_datasource ttRouteLogic_classForKey:host];
        }
        
        //动态注册的schema会覆盖配置文件的同名schema
        NSString *routeObjClassNameFromTable = [self.class _routeObjClassNameForParamObj:paramObj];
        if (!tt_isEmptyString(routeObjClassNameFromTable)) {
            routeObjClassName = routeObjClassNameFromTable;
        }
        
        //尝试fallback到普通web页
        //两种fallback方式，路由查找失败被动fallback，或，指定shouldfall=1主动fallback
        if (tt_isEmptyString(routeObjClassName) || [self _shouldFallbackByRemote:paramObj]) {
            if ([self _canFallbackWithParamObj:paramObj]) {
                NSURL *fallbackURL = [self _fallbackURLWithParamObj:paramObj];
                return [self routeObjWithOpenURL:fallbackURL userInfo:userInfo];
            }
        }
        
        //业务方需要实现TTRouteInitializeProtocol，同时也提供弱约束方法校验
        classInstance = NSClassFromString(routeObjClassName);
        if (![classInstance conformsToProtocol:@protocol(TTRouteInitializeProtocol)] &&
            ![classInstance instancesRespondToSelector:@selector(initWithRouteParamObj:)]) {
            NSAssert(NO, @"obj register to route but no designated initialization implemented!");
            return nil;
        }
        
        //路由URL重定向
        if ([classInstance conformsToProtocol:@protocol(TTRouteInitializeProtocol)] &&
            [classInstance respondsToSelector:@selector(redirectURLWithRouteParamObj:)]) {
            NSURL *redirectURL = [classInstance redirectURLWithRouteParamObj:paramObj];
            if ([self _canRedirectToURL:redirectURL comparedToOriURLRouteParamObj:paramObj]) {
                return [self routeObjWithOpenURL:redirectURL userInfo:userInfo];
            }
        }
        
        //跳转前目的路由对象修改业务上下文参数
        if ([classInstance conformsToProtocol:@protocol(TTRouteInitializeProtocol)] &&
            [classInstance respondsToSelector:@selector(reassginedUserInfoWithParamObj:)]){
            TTRouteUserInfo *reassignedUserInfo = [classInstance reassginedUserInfoWithParamObj:paramObj];
            NSAssert([reassignedUserInfo isKindOfClass:[TTRouteUserInfo class]], @"invalid reassigned userinfo!");
            paramObj.userInfo = reassignedUserInfo;
        }
        
        instance = [[classInstance alloc] initWithRouteParamObj:paramObj];
    }
    
    TTRouteObject *obj = [[TTRouteObject alloc] init];
    obj.instance = instance;
    obj.paramObj = paramObj;
    obj.action = action;
    return obj;
}

- (TTRouteParamObj *)routeParamObjWithURL:(NSURL *)url
{
    NSString *urlString = [url absoluteString];
    if (!url || tt_isEmptyString(urlString)) {
        NSAssert(NO, @"url为空，请确保url创建成功!");
        return nil;
    }
    return [self _routeParamObjWithURL:url];
}

// 执行route action
- (BOOL)executeRouteActionURL:(NSURL *)url userInfo:(TTRouteUserInfo *)userInfo
{
    if (![self canOpenURL:url]) {
        return NO;
    }
    
    TTRouteObject *obj = [self routeObjWithOpenURL:url userInfo:userInfo];
    if (obj) {
        return [self _executeActionWithRouteObj:obj];
    } else {
        return NO;
    }
}

+ (void)registerAction:(TTRouteAction)action withIdentifier:(NSString *)identifier
{
    if (!tt_isEmptyString(identifier) && action) {
        [self.actionTables setValue:[action copy] forKey:identifier];
    }
}

+ (void)unregisterActionWithIdentifier:(NSString *)identifier
{
    if (self.actionTables[identifier]) {
        [self.actionTables removeObjectForKey:identifier];
    }
}

#pragma mark - private

+ (NSMutableDictionary *)routeTables
{
    // 路由表项是entryName-classString格式
    static NSMutableDictionary <NSString*, NSString*> *_routeTables;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _routeTables = [NSMutableDictionary dictionary];
    });
    return _routeTables;
}

- (NSMutableDictionary *)cachedRouteParamObjDict
{
    if (!_cachedRouteParamObjDict) {
        _cachedRouteParamObjDict = [NSMutableDictionary dictionary];
    }
    return _cachedRouteParamObjDict;
}

+ (NSString *)_routeObjClassNameForParamObj:(TTRouteParamObj *)paramObj
{
    //优先匹配host/segment
    NSString *hostSegment = [NSString stringWithFormat:@"%@/%@", paramObj.host, paramObj.segment];
    NSString *routeObjClassName = nil;
    if (!tt_isEmptyString(hostSegment)) {
        routeObjClassName = [self.routeTables objectForKey:hostSegment];
        if (tt_isEmptyString(routeObjClassName) && !tt_isEmptyString(paramObj.host)) {
            routeObjClassName = [self.routeTables objectForKey:paramObj.host];
        }
    }
    return routeObjClassName;
}

- (TTRouteParamObj *)_routeParamObjWithURL:(NSURL *)url
{
    NSString *urlString = [url absoluteString];
    if (!url || tt_isEmptyString(urlString)) {
        NSAssert(NO, @"url为空，请确保url创建成功!");
        return nil;
    }
    
    //先做decode才能确保url解析成功
    //@fengjingjun 传入的URL正确做法是对query做encode，而不是整体；直接对正确encode的URL解析参数，再对各个参数逐一decode
//    [self _decodeWithEncodedURLString:&urlString];
    
    if([self.cachedRouteParamObjDict.allKeys containsObject:urlString]) {
        return [self.cachedRouteParamObjDict objectForKey:urlString];
    }
    
    TTRouteParamObj *paramObj = [[TTRouteParamObj alloc] init];
    
    NSString *scheme = nil;
    NSString *host = nil;
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    
    NSRange schemeSegRange = [urlString rangeOfString:@"://"];
    NSString *outScheme = nil;
    if (schemeSegRange.location != NSNotFound) {
        scheme = [urlString substringToIndex:NSMaxRange(schemeSegRange)];
        outScheme = [urlString substringFromIndex:NSMaxRange(schemeSegRange)];
    }
    else {
        outScheme = urlString;
    }
    
    NSArray *substrings = [outScheme componentsSeparatedByString:@"?"];
    NSString *path = [substrings objectAtIndex:0];
    NSArray *hostSeg = [path componentsSeparatedByString:@"/"];
    
    host = [hostSeg objectAtIndex:0];
    // deal with profile page depend on is login
    if ([host isEqualToString:TTProfileManagerPageKey]) {
        if (_datasource && [_datasource respondsToSelector:@selector(ttRouteLogic_isLogin)]) {
            if ([_datasource ttRouteLogic_isLogin]) {
                host = TTAccountPageLogicKey;
            }
            else {
                host = TTAuthorityPageLogicKey;
            }
        }
    }
    
    if ([substrings count] > 1) {
        NSString *queryString = [substrings objectAtIndex:1];
        NSArray *paramsList = [queryString componentsSeparatedByString:@"&"];
        [paramsList enumerateObjectsUsingBlock:^(NSString *param, NSUInteger idx, BOOL *stop){
            NSArray *keyAndValue = [param componentsSeparatedByString:@"="];
            if ([keyAndValue count] > 1) {
                NSString *paramKey = [keyAndValue objectAtIndex:0];
                NSString *paramValue = [keyAndValue objectAtIndex:1];
//                if ([paramValue rangeOfString:@"%"].length > 0) {
//                    //v0.2.17 递归decode解析query参数
//                    paramValue = [TTRoute recursiveDecodeForParamValue:paramValue];
//                }
                
                //v0.2.19 去掉递归decode，外部保证传入合法encode的url
                [self _decodeWithEncodedURLString:&paramValue];
                
                if (paramValue && paramKey) {
                    [queryParams setValue:paramValue forKey:paramKey];
                }
            }
        }];
    }
    
    if ([hostSeg count] > 1) {
        paramObj.segment = [hostSeg objectAtIndex:1];
    }
    
    paramObj.scheme = scheme;
    paramObj.host = host;
    paramObj.sourceURL = url;
    paramObj.queryParams = [queryParams copy];
    
    if ([host isEqualToString:TTAccountPageLogicKey] ||
        [host isEqualToString:TTAuthorityPageLogicKey]) {
        // 不做任何处理
        // profile_manager 页面不换存解析结果
    }
    else {
        [self.cachedRouteParamObjDict setValue:paramObj forKey:urlString];
    }
    
    return paramObj;
}

//+ (NSString *)recursiveDecodeForParamValue:(NSString *)paramValue
//{
//    if (!paramValue || ![paramValue isKindOfClass:[NSString class]] || 0 == paramValue.length) {
//        return paramValue;
//    }
//
//    NSString *recursiveDecodedString = nil;
//    do {
//        recursiveDecodedString = [paramValue copy];
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wdeprecated-declarations"
//        CFStringRef decodedStringRef = CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (__bridge CFStringRef)paramValue, CFSTR(""), kCFStringEncodingUTF8);
//#pragma clang diagnostic pop
//        paramValue = (__bridge_transfer NSString *)decodedStringRef;
//    } while (nil != paramValue && ![paramValue isEqualToString:recursiveDecodedString]);
//    return recursiveDecodedString;
//}

- (BOOL)_shouldFallbackByRemote:(TTRouteParamObj *)paramObj
{
    id shouldFallObj = [paramObj.queryParams objectForKey:TTShouldFallBackURLKey];
    if (!shouldFallObj) {
        return NO;
    }
    if ([shouldFallObj isKindOfClass:[NSNumber class]]) {
        return [shouldFallObj boolValue];
    }
    else if ([shouldFallObj isKindOfClass:[NSString class]]) {
        return [shouldFallObj isEqualToString:@"1"];
    }
    else {
        return NO;
    }
}

- (BOOL)_canFallbackWithParamObj:(TTRouteParamObj *)paramObj
{
    //注册了webview控件的路由且包含fallbackurl时才尝试降级到web页打开
    NSString *objcClassname = [[TTRoute routeTables] objectForKey:TTWebViewEntryKey];
    return !tt_isEmptyString(objcClassname) && [paramObj.queryParams.allKeys containsObject:TTFallbackURLKey];
}

- (BOOL)_canRedirectToURL:(NSURL *)redirectURL comparedToOriURLRouteParamObj:(TTRouteParamObj *)oriRouteParam
{
    if (![redirectURL isKindOfClass:[NSURL class]]) {
        return NO;
    }
    
    //重定向保护，防止死循环：1.route key相同 2.route key不同，但命中路由表同一个value
    if ([redirectURL.host isEqualToString:oriRouteParam.host]) {
        return NO;
    }
    
    TTRouteParamObj *redirectRouteParam = [self _routeParamObjWithURL:redirectURL];
    NSString *oriRouteObjClassName = [self.class _routeObjClassNameForParamObj:oriRouteParam];
    NSString *redirectObjClassName = [self.class _routeObjClassNameForParamObj:redirectRouteParam];
    if ([redirectObjClassName isEqualToString:oriRouteObjClassName]) {
        return NO;
    }
    
    return YES;
}

- (void)_handlePresentedViewController:(UINavigationController **)rootController
{
    //  遍历查找当前的所有presentedVC
    UIViewController *pViewController = (*rootController).presentedViewController;
    NSInteger depth = 0;
    while (pViewController.presentedViewController) {
        pViewController = pViewController.presentedViewController;
        depth++;
        //增加保护防止死循环
        if (depth > 15) {
            break;
        }
    }
    
    if (pViewController) {
        // 如果presentedViewController是登陆界面，则不改变*rootController
        if ([pViewController isKindOfClass:NSClassFromString(@"TTAccountNavigationController")]) {
            return;
        }
        if ([pViewController isKindOfClass:[UINavigationController class]]) {
            UIViewController *topVC = [(UINavigationController *)pViewController viewControllers].firstObject;
            if ([topVC isKindOfClass:NSClassFromString(@"NewsHDSettingPopOverViewController")] ||
                [topVC isKindOfClass:NSClassFromString(@"SSEditUserProfileViewController")]) {
                [pViewController dismissViewControllerAnimated:NO completion:nil];
            } else if ([topVC isKindOfClass:NSClassFromString(@"ArticleQuickBaseViewController")] || [topVC isKindOfClass:NSClassFromString(@"SSIntroduceViewController")]) {
                // 如果pViewController是iPad的登陆界面或登陆引导页，则不改变*rootController
                return;
            }
            else {
                *rootController = (UINavigationController *)pViewController;
            }
        } else {
            [pViewController dismissViewControllerAnimated:NO completion:nil];
        }
    }
    else {
        //处理查看文章大图时的外链
        if ([*rootController isKindOfClass:[UINavigationController class]]) {
            UIViewController *topVC = [[[[UIApplication sharedApplication] delegate].window rootViewController] childViewControllers].lastObject;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
            if ([topVC isKindOfClass:NSClassFromString(@"SSPhotoScrollViewController")] &&
                [topVC respondsToSelector:@selector(dismissSelf)]) {
                [UIView performWithoutAnimation:^{
                    [topVC performSelectorOnMainThread:@selector(dismissSelf) withObject:nil waitUntilDone:YES];
                }];
            }
#pragma clang diagnostic pop
        }
    }
}

- (void)_handlePlusSymbolInURLString:(NSString **)urlString
{
    if ([*urlString rangeOfString:@"+"].location != NSNotFound) {
        *urlString = [*urlString stringByReplacingOccurrencesOfString:@"+" withString:@"%20"];
    }
}

- (void)_decodeWithEncodedURLString:(NSString **)urlString
{
    if ([*urlString rangeOfString:@"%"].length == 0){
        return;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    *urlString = (__bridge_transfer NSString *)(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (__bridge CFStringRef)*urlString, CFSTR(""), kCFStringEncodingUTF8));
#pragma clang diagnostic pop
}

- (NSURL *)_fallbackURLWithParamObj:(TTRouteParamObj *)paramObj
{
    NSMutableString *querys = [NSMutableString string];
    if ([paramObj.queryParams.allKeys count] > 0) {
        [paramObj.queryParams enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString *  _Nonnull value, BOOL * _Nonnull stop) {
            //对已经fallback的情况，remote开关如果有则强制关，避免死循环
            if ([key isEqualToString:TTShouldFallBackURLKey]) {
                value = @"0";
            }
            [querys appendFormat:@"%@=%@", key, value];
            [querys appendString:@"&"];
        }];
    }
    [querys appendString:[NSString stringWithFormat:@"url=%@", [paramObj.queryParams objectForKey:TTFallbackURLKey]]];
    
    NSString *fallbackURLString = [NSString stringWithFormat:@"%@%@?%@", paramObj.scheme, TTWebViewEntryKey, querys];
    NSURL *fallbackURL = [NSURL URLWithString:fallbackURLString];
    return fallbackURL;
}

+ (NSMutableDictionary *)actionTables
{
    static NSMutableDictionary <NSString*, TTRouteAction> *_actionTables;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _actionTables = [NSMutableDictionary dictionary];
    });
    return _actionTables;
}

- (BOOL)_executeActionWithRouteObj:(TTRouteObject *)obj
{
    NSAssert(obj.action != nil, @"try open route action without registration");
    if (obj.action) {
        obj.action(obj.paramObj.allParams);
    }
    return !!obj.action;
}

#pragma mark - TTRoute navigationController

- (UINavigationController *)_topMostNavigationController
{
    UIView *topView = self.appWindow.subviews.lastObject;
    UIViewController *topController = [self _topViewControllerFor:topView];
    if (topController.presentedViewController && [topController.presentedViewController isKindOfClass:[UINavigationController class]]) {
        return (UINavigationController *)(topController.presentedViewController);
    }
    else if ([topController isKindOfClass:[UINavigationController class]]) {
        return (UINavigationController *)topController;
    }
    else if (topController.navigationController) {
        return topController.navigationController;
    }
    else {
        return nil;
    }
}

- (UIViewController*)_topViewControllerFor:(UIResponder*)responder
{
    UIResponder *topResponder = responder;
    while(topResponder && ![topResponder isKindOfClass:[UIViewController class]]) {
        topResponder = [topResponder nextResponder];
    }
    if(!topResponder) {
        topResponder = self.appWindow.rootViewController;
    }
    return (UIViewController*)topResponder;
}

- (UINavigationController *)_navigationControllerForRoute
{
    //首先取业务方指定的navigationController
    if (self.designatedNavDatasource && [self.designatedNavDatasource respondsToSelector:@selector(designatedRouteNavigationController)]) {
        return [self.designatedNavDatasource designatedRouteNavigationController];
    }
    else {
        //如果业务方不提供，取app当前responderChain最上层的navigationController，也可能为空
        return self.initialRouteNavigationController?:[self _topMostNavigationController];
    }
}

#pragma mark - Set & Get
- (NSString *)localHost {
    if ([self.datasource respondsToSelector:@selector(ttRouteLocalHost)]) {
        return [self.datasource ttRouteLocalHost];
    }
    return TTLocalScheme;
}

@end
