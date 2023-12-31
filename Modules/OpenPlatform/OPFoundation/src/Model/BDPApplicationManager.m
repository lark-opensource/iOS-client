//
//  BDPApplicationManager.m
//  Timor
//
//  Created by 王浩宇 on 2019/1/26.
//

#import "BDPApplicationManager.h"
#import "BDPTimorClient.h"
#import "BDPUtils.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>

NSString *const BDPAppNameKey = @"appName";
NSString *const BDPAppVersionKey = @"appVersion";
NSString *const BDPAppLanguageKey = @"language";

@interface BDPApplicationManager ()

@property (nonatomic, copy, readwrite) NSDictionary *sceneInfo;

@end

@implementation BDPApplicationManager

#pragma mark - Initilize
/*-----------------------------------------------*/
//              Initilize - 初始化相关
/*-----------------------------------------------*/
+ (instancetype)sharedManager
{
    static BDPApplicationManager *client;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        client = [[BDPApplicationManager alloc] init];
    });
    return client;
}

#pragma mark - Function Implementation
/*-----------------------------------------------*/
//       Function Implementation - 方法实现
/*-----------------------------------------------*/
- (NSDictionary *)applicationInfo
{
    NSDictionary *applicationInfo = @{};
    BDPPlugin(applicationPlugin, BDPApplicationPluginDelegate);
    if ([applicationPlugin respondsToSelector:@selector(bdp_registerApplicationInfo)]) {
        applicationInfo = [applicationPlugin bdp_registerApplicationInfo];
    }
    return applicationInfo;
}

- (NSDictionary *)sceneInfo
{
    if (!_sceneInfo) {
        BDPPlugin(applicationPlugin, BDPApplicationPluginDelegate);
        if ([applicationPlugin respondsToSelector:@selector(bdp_registerSceneInfo)]) {
            _sceneInfo = [applicationPlugin bdp_registerSceneInfo];
        }
    }
    return _sceneInfo;
}

#pragma mark - Convenient Methods
/*-----------------------------------------------*/
//         Convenient Methods - 便捷方法
/*-----------------------------------------------*/
+ (NSDictionary *)getLaunchOptionParams:(BDPSchema *)schema type:(BDPType)type
{
    // Get Path & Query
    NSString *path = @"";
    NSString *query = @"";
    if (type == BDPTypeNativeApp) {
        path = [schema startPagePath] ?: @"";
        query = [schema startPageQuery] ?: @"";
    }
    
    // Generate Launch Params
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:4];
    [params setValue:path forKey:@"path"];
    [params setValue:query forKey:@"query"];
    [params setValue:schema.shareTicket forKey:@"shareTicket"];
    
    // Generate Scene Params
    NSDictionary *enterParams = [self getOnAppEnterForegroundParams:schema];
    [params addEntriesFromDictionary:enterParams];
    
    [params setValue:schema.groupId?:@"" forKey:@"group_id"];
    
    if (schema.chatID.length > 0) {
        [params setValue:schema.chatID forKey:@"chat_id"];
    }
    
    if (schema.mode.length > 0) {
        [params setValue:schema.mode forKey:@"mode"];
    }
       
    return [params copy];
}

+ (NSDictionary *)getOnAppEnterForegroundParams:(BDPSchema *)schema
{
    // Get Application Info
    NSDictionary *sceneInfo = [[BDPApplicationManager sharedManager] sceneInfo];
    NSString *launchFrom = [[schema launchFrom] copy];
    
    // Get Scene Value
    NSString *scene = [schema scene];
    NSString *subScene = [schema subScene];
    if (!scene) {
        scene = [sceneInfo bdp_stringValueForKey:launchFrom];
    }
    
    // Generate Scene Params - 2019-4-26,scene和subScene默认传空字符串.
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithCapacity:2];
    [params setValue:(scene ?: @"") forKey:@"scene"];
    [params setValue:(subScene ?: @"") forKey:@"subScene"];
    
    // get Referer Info
    NSDictionary *refererInfo = schema.refererInfoDictionary;
    if (!BDPIsEmptyDictionary(refererInfo)) {
        [params setValue:refererInfo forKey:@"refererInfo"];
    }
    
    if (BDPIsEmptyDictionary(params)) {
        [params setValue:@"" forKey:@"scene"];
        [params setValue:@"" forKey:@"subScene"];
    }
    
    return [params copy];
}

+ (NSString *)language {
    // lint:disable:next lark_storage_check
    return [BDPApplicationManager.sharedManager.applicationInfo bdp_stringValueForKey:BDPAppLanguageKey] ?: [NSUserDefaults.standardUserDefaults arrayForKey:@"AppleLanguages"].firstObject;
}

@end
