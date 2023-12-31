//
//  EMAPermissionManager.m
//  Pods
//
//  Created by 武嘉晟 on 2019/4/24.
//

#import "EMAPermissionManager.h"
#import <OPFoundation/EMAPermissionData.h>
#import <OPFoundation/BDPAuthorization.h>
#import <OPFoundation/BDPCommon.h>
#import <OPFoundation/BDPCommonManager.h>
#import <TTMicroApp/BDPTask.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>

@interface EMAPermissionManager()

// 因为目前网页应用没有本地化，且与BDPCommon等是解耦的，其engine生命周期也是随VC的，所以这里记录网页应用的授权信息
// 用NSMapTable来weak持有auth模块，当网页应用的生命周期结束，auth模块生命周期随之结束，table会自动移除，不需要手动管理remove
@property (nonatomic, strong) NSMapTable<OPAppUniqueID *, BDPAuthorization *> *webAppAuthProviders;

@end

@implementation EMAPermissionManager

+ (instancetype)sharedManager {
    static EMAPermissionManager *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[EMAPermissionManager alloc] init];
        sharedInstance.webAppAuthProviders = [[NSMapTable alloc] initWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableWeakMemory capacity:5];
    });
    return sharedInstance;
}

+ (id<BDPBasePluginDelegate>)sharedPlugin {
    return [self sharedManager];
}

/**
 获取应用权限数据

 @param uniqueID uniqueID
 @return 权限数组
 */
- (NSArray<EMAPermissionData *> *)getPermissionDataArrayWithUniqueID:(BDPUniqueID *)uniqueID {
    BDPAuthorization *auth = [self getAuthForUniqueID:uniqueID];
    NSArray<NSDictionary *> *usedScopes = [auth usedScopes];
    if (usedScopes.count == 0) {
        return [NSArray array];
    } else {
        NSMutableArray *mutableArray = [[NSMutableArray alloc] init];
        for (NSDictionary *scope in usedScopes) {
            EMAPermissionData *data = [[EMAPermissionData alloc] init];
            data.name = [scope bdp_stringValueForKey:@"name"];
            data.isGranted = [scope bdp_boolValueForKey:@"value"];
            data.scope = [scope bdp_stringValueForKey:@"key"];
            data.mod = [scope bdp_integerValueForKey:@"mod"];
            [mutableArray addObject:data];
        }
        NSArray *array = mutableArray.copy;
        return array;
    }
}

- (void)fetchAuthorizeData:(BDPUniqueID *)uniqueID storage:(BOOL)storage completion:(void (^ _Nonnull)(NSDictionary * _Nullable result, NSDictionary * _Nullable bizData, NSError * _Nullable error))completion {
    BDPAuthorization *auth = [self getAuthForUniqueID:uniqueID];
    [auth fetchAuthorizeData:storage completion:completion];
}

/**
 设置应用权限

 @param permissons 标识授权状态的键值对：@{(NSString *)scopeKey: @((BOOL)approved)}
 @param uniqueID uniqueID
 */
- (void)setPermissons:(NSDictionary<NSString *, NSNumber *> *)permissons uniqueID:(BDPUniqueID *)uniqueID {
    BDPAuthorization *auth = [self getAuthForUniqueID:uniqueID];
    [auth updateScopes:permissons notify:YES];
}

- (BDPAuthorization *)getAuthForUniqueID:(BDPUniqueID *)uniqueID {
    BDPAuthorization *auth;
    switch (uniqueID.appType) {
        case BDPTypeWebApp:
            auth = [[self webAppAuthProviders] objectForKey:uniqueID];
            break;
        default:
        {
            BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:uniqueID];
            auth = common.auth;
            break;
        }
    }
    return auth;
}

- (void)setWebAppAuthProviderForUniqueID:(BDPUniqueID *)uniqueID authProvider:(BDPAuthorization *)authProvider {
    [[self webAppAuthProviders] setObject:authProvider forKey:uniqueID];
}

@end
