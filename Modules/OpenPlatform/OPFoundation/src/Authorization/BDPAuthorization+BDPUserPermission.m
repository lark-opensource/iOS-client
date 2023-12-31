//
//  BDPAuthorization+UserPermission.m
//  Timor
//
//  Created by liuxiangxin on 2019/12/11.
//


#import "BDPAuthorization+BDPUserPermission.h"
#import "BDPAuthorization+BDPEvent.h"
#import "BDPAuthorization+BDPSystemPermission.h"
#import "BDPAuthorization+BDPUI.h"
#import "BDPAuthorization+BDPUtils.h"
#import "BDPAuthorizationUtilsDefine.h"
#import "BDPCommon.h"
#import "BDPCommonManager.h"
#import "BDPI18n.h"
//#import "BDPPermissionViewController.h"
#import "BDPResponderHelper.h"
#import "BDPTimorClient.h"
#import "BDPUserInfoManager.h"
#import "BDPUtils.h"
#import "NSArray+BDPExtension.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import "EEFeatureGating.h"
#import "BDPTracker.h"
#import "OPResolveDependenceUtil.h"

@implementation BDPAuthorization (BDPUserPermission)

#pragma mark - Request Single Permission

// 通过调用的方法来申请单个权限
- (void)requestUserPermissionIfNeed:(BDPJSBridgeMethod *)method
                           uniqueID:(OPAppUniqueID *)uniqueID
                       authProvider:(BDPAuthorization *)authProvider
                           delegate:(id<BDPAuthorizationDelegate>)delegate
                         completion:(BDPAuthorizationRequestCompletion)completion
{
    // 获取安全回调
    completion = [self generateSafeCompletion:completion uniqueID:uniqueID method:method];
    
    // Check Command In List
    NSString *scope = self.permission[method.name];
    if (BDPIsEmptyString(scope)) {
        AUTH_COMPLETE(BDPAuthorizationPermissionResultEnabled)
        return;
    }

    [self requestUserPermissionForScopeIfNeeded:scope uniqueID:uniqueID authProvider:authProvider delegate:delegate completion:completion];
}

// 通过传入scope来直接授权
- (void)requestUserPermissionForScopeIfNeeded:(NSString *)scope
                                     uniqueID:(OPAppUniqueID *)uniqueID
                                 authProvider:(BDPAuthorization *)authProvider
                                     delegate:(id<BDPAuthorizationDelegate>)delegate
                                   completion:(void (^)(BDPAuthorizationPermissionResult))completion
{
    if ([scope hasPrefix:BDPScopePrefix]) {
        scope = [self.class transfromScopeToInnerScope:scope];
    }
    // 支持宿主自定义授权状态
    BDPPlugin(authorizationPlugin, BDPAuthorizationPluginDelegate);
    if ([authorizationPlugin respondsToSelector:@selector(bdp_shouldCustomizePemissionForInnerScope:completion:)]) {
        BOOL isCustomized = [authorizationPlugin bdp_shouldCustomizePemissionForInnerScope:scope completion:completion];
        if (isCustomized) {
            return;
        }
    }

    // 应用角标fg
    if (scope && [scope isKindOfClass:[NSString class]] && [scope isEqualToString:BDPInnerScopeAppBadge] && ![EEFeatureGating boolValueForKey:EEFeatureGatingKeyGadgetOpenAppBadge]) {
        AUTH_COMPLETE(BDPAuthorizationPermissionResultInvalidScope);
        return;
    }

    if (![self.scope.allKeys containsObject:scope]) {
        AUTH_COMPLETE(BDPAuthorizationPermissionResultInvalidScope);
        return;
    }
    // 如果有该权限的历史授权信息，直接返回，没有则请求权限
    NSNumber *scopeStatus = [self statusForScope:scope];
    if (scopeStatus != nil) {
        if (scopeStatus.boolValue) {
            [self requestSystemPermissionForScopeIfNeed:scope uniqueID:uniqueID completion:completion];
        } else {
            BDPLogInfo(@"UserDisabled");
            AUTH_COMPLETE(BDPAuthorizationPermissionResultUserDisabled);
            BOOL showAlert = YES;
            if (scope && [scope isKindOfClass:[NSString class]] && [scope isEqualToString:BDPInnerScopeAppBadge]) {
                showAlert = NO;
            }
            if (showAlert) {
                [self onPersmissionDisabledForScope:scope firstTime:NO authProvider:authProvider delegate:delegate];
            }
        }
        return;
    }
    
    // 内部开发者默认直接授权
    if ([self isAuthFreeScope:scope]) {
        BDPLogInfo(@"is auth free");
        if(![self updateScope:scope approved:YES]) {
            BDPLogError(@"setScopeError innerApp scope:%@", scope);
        }
        [self requestSystemPermissionForScopeIfNeed:scope uniqueID:uniqueID completion:completion];
        return;
    }
    
    // 没有该权限的历史授权记录，弹出授权弹框
    // 如果已经弹出某个权限的弹窗，则加入队列
    if ([self scopeQueueIsWaiting:scope]) {
        [self scopeQueueAddCompletion:completion scope:scope];
        BDPLogInfo(@"Add scope queue %@", scope);
        return;
    }
    
    NSString *description = self.scope[scope][@"description"];
    NSString *title = [NSString stringWithFormat:BDPI18n.permissions_is_requesting, self.source.name];
    if (BDPIsEmptyString(self.source.name)) {
        title = BDPI18n.LittleApp_TTMicroApp_AllowAppPrmssn;
    }

    // 队列开始等待
    WeakSelf;
    dispatch_block_t blk = ^{
        StrongSelfIfNilReturn;
        
        [self scopeQueueStartWaiting:scope];
        BDPPermissionScopeType scopeType = [BDPAuthorization transformScopeToScopeType:scope];
        [self.class eventAlertShowForScope:scopeType uniqueID:uniqueID multipleAuth:NO];
        BDPLogInfo(@"showCustomPermissionVCWithTitle");

        NSMutableDictionary *trackerParams = [NSMutableDictionary dictionary];
        if (uniqueID.appType == BDPTypeNativeApp) {
            [trackerParams setValue:@"MP" forKey:@"application_type"];
        } else if (uniqueID.appType == BDPTypeWebApp) {
            [trackerParams setValue:@"H5" forKey:@"application_type"];
        }
        NSDictionary *keys = [BDPAuthorization mapForStorageKeyToScopeKey];
        NSString *scopeString = [keys bdp_stringValueForKey:scope];
        [trackerParams setValue:scopeString forKey:@"authorize_scope"];
        [trackerParams setValue:uniqueID.appID forKey:@"app_id"];
        BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
        NSString *appName = common.model.name ? common.model.name : @"";
        [trackerParams setValue:appName forKey:@"appname"];
        [BDPTracker event:@"authorize_modal_show" attributes:trackerParams.copy uniqueID:uniqueID];

        [self showCustomPermissionVCWithTitle:title description:description scopeType:scopeType completion:^(BOOL granted) {
            BDPLogInfo(@"showCustomPermissionVCWithTitle completion %@", BDPParamStr(title, description, granted));
            // 已授权
            if (granted) {
                if(![self updateScope:scope approved:YES]) {
                    BDPLogError(@"setScopeError granted scope:%@", scope);
                }
                [self requestSystemPermissionForScopeIfNeed:scope uniqueID:uniqueID completion:^(BDPAuthorizationPermissionResult result) {
                    [self.class eventAuthResultForScope:scopeType result:result uniqueID:uniqueID multipleAuth:NO];
                    AUTH_COMPLETE(result);
                    [self scopeQueueExcuteAllCompletion:result scope:scope];
                }];
                
                // 未授权
            } else {
                if(![self updateScope:scope approved:NO]) {
                    BDPLogError(@"setScopeError !granted scope:%@", scope);
                }
                [self.class eventAuthResultForScope:scopeType
                                       result:BDPAuthorizationPermissionResultUserDisabled
                                     uniqueID:uniqueID
                                 multipleAuth:NO];
                AUTH_COMPLETE(BDPAuthorizationPermissionResultUserDisabled);
                [self scopeQueueExcuteAllCompletion:BDPAuthorizationPermissionResultUserDisabled scope:scope];
            }
        }];
    };
    blk();
}


#pragma mark - Request Multiple Permissions

// 排队挨个申请权限, 如果中间遇到失败的权限就中断
- (void)requestUserPermissionQeueuedForScopeList:(NSArray<NSString *> *)scopeList
                                        uniqueID:(OPAppUniqueID *)uniqueID
                                    authProvider:(BDPAuthorization *)authProvider
                                        delegate:(id<BDPAuthorizationDelegate>)delegate
                                      completion:(BDPAuthorizationRequestCompletion)completion
{
    NSMutableArray<NSString *> *list = [scopeList mutableCopy];
    if (!list.count) {
        AUTH_COMPLETE(BDPAuthorizationPermissionResultEnabled);
        return;
    }
    
    NSString *scope = list.lastObject;
    [list removeLastObject];
    
    WeakSelf;
    [self requestUserPermissionForScopeIfNeeded:scope uniqueID:uniqueID authProvider:authProvider delegate:delegate completion:^(BDPAuthorizationPermissionResult result) {
        StrongSelfIfNilReturn;
        if (result != BDPAuthorizationPermissionResultEnabled) {
            AUTH_COMPLETE(result);
            return;
        }
        [self requestUserPermissionQeueuedForScopeList:list uniqueID:uniqueID authProvider:authProvider delegate:delegate completion:completion];
    }];
}

// 混合授权， 先排队挨个申请， 然后进行批量授权
- (void)requestUserPermissionHybridForScopeList:(NSArray<NSString *> *)scopeList
                                       uniqueID:(OPAppUniqueID *)uniqueID
                                   authProvider:(BDPAuthorization *)authProvider
                                       delegate:(id<BDPAuthorizationDelegate>)delegate
                                     completion:(void (^)(NSDictionary<NSString *,NSNumber *> *))completion
{
    BOOL shouldAllPendding = !self.shouldCombinedAuthorize;
    NSMutableArray<NSString *> *combianScopeList = [scopeList bdp_arrayByRemoveDuplicateObject].mutableCopy;
    NSMutableArray<NSString *> *penddingScopeList = [NSMutableArray array];
    [combianScopeList enumerateObjectsUsingBlock:^(NSString * _Nonnull scope, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL shouldPendding = shouldAllPendding;
        if (shouldPendding) {
            [penddingScopeList addObject:scope];
            [combianScopeList removeObject:scope];
        }
    }];
    
    WeakSelf;
    [self requestUserPermissionQueuedForScopeList:penddingScopeList uniqueID:uniqueID authProvider:authProvider delegate:delegate withDetailedCompletion:^(NSDictionary<NSString *,NSNumber *> * _Nonnull resultDic) {
        StrongSelfIfNilReturn;
        if (!combianScopeList.count) {
            AUTH_COMPLETE(resultDic);
            return;
        }

        [self requestUserPermissionBatchedForScopeList:combianScopeList uniqueID:uniqueID authProvider:authProvider delegate:delegate completion:^(NSDictionary<NSString *,NSNumber *> * _Nonnull resultDic2) {
            StrongSelfIfNilReturn;
            NSDictionary *allResult = resultDic.mutableCopy;
            [allResult setValuesForKeysWithDictionary:resultDic2];
            AUTH_COMPLETE(allResult.copy);
        }];
    }];
}

// 聚合授权方法，通过一个弹窗搞定所有授权
- (void)requestUserPermissionBatchedForScopeList:(NSArray<NSString *> *)scopeList
                                        uniqueID:(OPAppUniqueID *)uniqueID
                                    authProvider:(BDPAuthorization *)authProvider
                                        delegate:(id<BDPAuthorizationDelegate>)delegate
                                      completion:(void (^)(NSDictionary<NSString *,NSNumber *> *))completion
{
    //1. 先去掉所有重复的元素
    scopeList = [scopeList bdp_arrayByRemoveDuplicateObject];
    
    NSMutableArray<NSNumber *> *results = [NSMutableArray arrayWithCapacity:scopeList.count];

    const NSInteger needRequestSystemAuthorization = 1000;

    //都统一转换成内部的scope表示, 同时建立反向转换表， 在处理完后可以再次转换回去
    NSMutableArray<NSString *> *innerScopeList = [NSMutableArray array];
    // <innerScope -- outScope>
    NSMutableDictionary<NSString *, NSString *> *reverseScopeNameMap = [NSMutableDictionary dictionary];
    for (NSString *scope in scopeList) {
        NSString *innerScope = nil;
        if ([scope hasPrefix:BDPScopePrefix]) {
            innerScope = [self.class transfromScopeToInnerScope:scope];
        } else {
            innerScope = scope;
        }
        
        if (!innerScope) {
            //如果转换结果是nil， 那么就先不转换， 后面过滤非法scope时会过滤掉
            innerScope = scope;
        }
        
        [innerScopeList addObject:innerScope];
        [reverseScopeNameMap setValue:scope forKey:innerScope];
    }
    
    
    //这里建立一个反向查询的表， 可以根据scope来快速定位在scopeList中的位置
    NSMutableDictionary<NSString *, NSNumber *> *reverseIndexMap = [NSMutableDictionary dictionary];
    [innerScopeList enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [reverseIndexMap setValue:@(idx) forKey:obj];
    }];
    
    //init results
    [innerScopeList enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [results addObject:@(BDPAuthorizationPermissionResultEnabled)];
    }];

    //filter invalid scopes
    [innerScopeList enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![self.scope.allKeys containsObject:obj]) {
            results[idx] = @(BDPAuthorizationPermissionResultInvalidScope);
        }
    }];
    
    //内部开发者直接授权
    [innerScopeList enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (results[idx].integerValue != BDPAuthorizationPermissionResultInvalidScope && [self isAuthFreeScope:obj]) {
            [self.storage setObject:@(YES) forKey:obj];
        }
    }];

    //过滤一下是否已经有该权限的历史了， 如果有的话, 直接设置结果， 如果没有， 就弹窗请求权限
    NSMutableArray<NSString *> *requestSystemAuthoriationList = [NSMutableArray array];
    NSMutableArray<NSString *> *requestUserAuthorizationList = [NSMutableArray array];
    [innerScopeList enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (results[idx].integerValue == BDPAuthorizationPermissionResultInvalidScope) {
            return;
        }
        
        NSNumber *scopeStatus = [self statusForScope:obj];
        if (scopeStatus) {
            if (scopeStatus.boolValue) {
                [requestSystemAuthoriationList addObject:obj];
                results[idx] = @(needRequestSystemAuthorization);
            } else {
                results[idx] = @(BDPAuthorizationPermissionResultUserDisabled);
            }
        } else {
            [requestUserAuthorizationList addObject:obj];
        }
    }];

    //转换成ScopeType
    NSMutableArray<NSNumber *> *scopeTypeList = [NSMutableArray array];
    [requestUserAuthorizationList enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BDPPermissionScopeType type = [BDPAuthorization transformScopeToScopeType:obj];
        [scopeTypeList addObject:@(type)];
    }];

    BDPPermissionViewControllerAction action = nil;
    action = ^(NSArray<NSNumber *> * _Nonnull authorizedList, NSArray<NSNumber *> * _Nonnull deniedList) {
        //处理被拒绝的权限
        NSMutableArray<NSString *> *deniedInnerScopes = [NSMutableArray array];
        for (NSNumber *scopeNumer in deniedList) {
            [deniedInnerScopes addObject:[self.class transfromScopeTypeToInnerScope:scopeNumer.integerValue]];
        }
        [deniedInnerScopes enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.storage setObject:@(NO) forKey:obj];
            
            NSNumber *indexNumber = [reverseIndexMap objectForKey:obj];
            if (indexNumber) {
                NSInteger index = [indexNumber integerValue];
                if (index < results.count) {
                    results[index] = @(BDPAuthorizationPermissionResultUserDisabled);
                }
            }
        }];
        //处理允许的权限
        //把scopeType 转换成 scope string
        NSMutableArray<NSString *> *authorizedInnerScopes = [NSMutableArray array];
        for (NSNumber *scopeNumber in authorizedList) {
            [authorizedInnerScopes addObject:[self.class transfromScopeTypeToInnerScope:scopeNumber.integerValue]];
        }
        //加入到系统权限中
        [authorizedInnerScopes addObjectsFromArray:requestSystemAuthoriationList];
        for (NSString *scope in authorizedInnerScopes) {
            [self.storage setObject:@(YES) forKey:scope];
        }
        //排队申请系统权限
        WeakSelf;
        [self requestSystemPermissionForScopeListIfNeeded:authorizedInnerScopes uniqueID:uniqueID completion:^(NSDictionary<NSString *,NSNumber *> * resultDic) {
            StrongSelfIfNilReturn;
            [resultDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
                NSNumber *indexNumber = [reverseIndexMap objectForKey:key];
                if (indexNumber) {
                    NSInteger index = indexNumber.integerValue;
                    results[index] = obj;
                }
            }];
           
            NSMutableDictionary<NSString *, NSNumber *> *finalResultDic = [NSMutableDictionary dictionary];
            [innerScopeList enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSString *outScopeName = [reverseScopeNameMap bdp_stringValueForKey:obj];
                NSNumber *result = results[idx];
                [finalResultDic setValue:result forKey:outScopeName];
            }];
           
            //这里要上报聚合授权的结果， 只有所有都授权成功， 才算做是成功
            //如果有一个不成功， 就要算作是失败， 失败结果以最后一次授权失败的为准
            if (scopeTypeList.count) { //如果不展示多授权弹窗的话也没有必要上报授权弹窗的授权结果
                [self.class eventCombineAuthRessltWithUniqueID:uniqueID
                                              authResult:finalResultDic];
            }

            //这一些搞定之后要回调回去详细的授权信息
            AUTH_COMPLETE(finalResultDic.copy)
        }];
    };
    
    if (scopeTypeList.count) {
        // 需要申请权限， 展示弹窗
        //展示多个ScopeList的授权弹窗
        [self.class eventAlertShowForScope:BDPPermissionScopeTypeAlbum uniqueID:uniqueID multipleAuth:YES];
        BDPExecuteOnMainQueue(^{
            
            Class<BDPPermissionViewControllerDelegate> permissionVCClass = [OPResolveDependenceUtil permissionViewControllerClass];
            UIViewController<BDPPermissionViewControllerDelegate> *permissionVC = [permissionVCClass initControllerWithName:self.source.name icon:self.source.icon uniqueID:self.source.uniqueID authScopes:self.scope scopeList:scopeTypeList.copy];
            permissionVC.completion = action;
//            BDPPermissionViewController *permissionVC = [[BDPPermissionViewController alloc] initWithName:self.source.name icon:self.source.icon uniqueID:self.source.uniqueID authScopes:self.scope scopeList:scopeTypeList.copy];
//            permissionVC.completion = action;
            
            [[self class] showViewController:permissionVC animated:YES completion:nil];
        });
        //收集所有的需要系统授权的scope， 进行排队申请系统权限
    } else {
        action(scopeTypeList, [NSArray array]);
    }
}


// 挨个排队申请权限， 跟requestAllPerssions的区别是回调不同， 这个方法的回调可以详细给出所有的scope的授权结果
- (void)requestUserPermissionQueuedForScopeList:(NSArray<NSString *> *)scopeList
                                       uniqueID:(OPAppUniqueID *)uniqueID
                                   authProvider:(BDPAuthorization *)authProvider
                                       delegate:(id<BDPAuthorizationDelegate>)delegate
                         withDetailedCompletion:(void (^)(NSDictionary<NSString *, NSNumber *> *))completion
{
    NSMutableArray<NSString *> *list = scopeList.mutableCopy;
    NSMutableDictionary<NSString *, NSNumber *> *resultDic = [NSMutableDictionary dictionary];
    if (!scopeList.count) {
        AUTH_COMPLETE(resultDic)
        return;
    }
    
    [self _requestUserPermissionQueuedForScopeList:list
                                          uniqueID:uniqueID
                                      authProvider:authProvider
                                          delegate:delegate
                                         resultDic:resultDic
                                        completion:^{ AUTH_COMPLETE(resultDic); }];
}

- (void)_requestUserPermissionQueuedForScopeList:(NSMutableArray<NSString *> *)scopeList
                                        uniqueID:(OPAppUniqueID *)uniqueID
                                    authProvider:(BDPAuthorization *)authProvider
                                        delegate:(id<BDPAuthorizationDelegate>)delegate
                                       resultDic:(NSMutableDictionary<NSString *, NSNumber *> *)resultDic
                                      completion:(dispatch_block_t)completion
{
    if (!scopeList.count) {
        AUTH_COMPLETE()
        return;
    }
    
    NSString *nextScope = scopeList.lastObject;
    [scopeList removeLastObject];
    
    WeakSelf;
    [self requestUserPermissionForScopeIfNeeded:nextScope uniqueID:uniqueID authProvider:authProvider delegate:delegate completion:^(BDPAuthorizationPermissionResult result) {
        StrongSelfIfNilReturn;
        resultDic[nextScope] = @(result);
        
        [self _requestUserPermissionQueuedForScopeList:scopeList uniqueID:uniqueID authProvider:authProvider delegate:delegate resultDic:resultDic completion:completion];
    }];
}

- (BOOL)isAuthFreeScope:(NSString *)innerScope
{
    BDPAuthorizationFreeType authFreeType = [[self class] authorizationFreeTypeForInnerScope:innerScope];
    int64_t authPassBitMap = self.source.authPass;
    
    return authPassBitMap & authFreeType;
}

@end
