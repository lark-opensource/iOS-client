//
//  BDUGShareDataManager.m
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/4/8.
//

#import "BDUGShareDataManager.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import "BDUGShareDataModel.h"
#import <TTNetworkManager/TTDefaultHTTPRequestSerializer.h>
#import <TTNetworkManager/TTHTTPResponseSerializerBase.h>
#import "BDUGSharePostRequestSerializer.h"
#import "BDUGShareEvent.h"
#import "BDUGShareConfiguration.h"

@interface BDUGShareDataManager ()

@property (nonatomic, strong) NSMutableDictionary *cacheDict;
@property (nonatomic, strong) NSMutableDictionary *requestStatusDict;

@end

@implementation BDUGShareDataManager

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMemoryWarning:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification {
    [self cleanCache];
}

#pragma mark - data request & get

- (void)requestShareInfoWithPanelID:(NSString *)panelID
                            groupID:(NSString *)groupID
                          extroData:(NSDictionary *)extroData
                         completion:(BDUGShareDataRequestFinishBlock)completion {
    [self requestShareInfoWithPanelID:panelID groupID:groupID extroData:extroData useMemeryCache:YES completion:completion];
}

- (void)requestShareInfoWithPanelID:(NSString *)panelID
                            groupID:(NSString *)groupID
                          extroData:(NSDictionary *)extroData
                     useMemeryCache:(BOOL)useCache
                         completion:(BDUGShareDataRequestFinishBlock)completion {
    if (self.config.isLocalMode) {
        //本地模式不请求。
        return;
    }
    if (!_cacheDict) {
        _cacheDict = [[NSMutableDictionary alloc] init];
    }
    if (!_requestStatusDict) {
        _requestStatusDict = [[NSMutableDictionary alloc] init];
    }
    NSString *key = [self requestStatusKeyWithPanelId:panelID resourceId:groupID];
    if (useCache) {
        //使用内存缓存且缓存命中，则返回数据。
        BDUGShareDataModel *model = [self.cacheDict objectForKey:key];
        if (model) {
            !completion ?: completion(0, nil, model);
            return;
        }
    }
    [self.requestStatusDict setObject:@(BDUGShareDataRequestStatusRequesting) forKey:key];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    params[@"share_panel_id"] = panelID;
    params[@"resource_id"] = groupID;
    
    if (extroData) {
        NSError * err;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:extroData options:0 error:&err];
        NSString *myString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        params[@"data"] = myString;
    }
    
    //不使用缓存或者缓存没有命中，则触发请求。
    
    BDUGLoggerInfo(([NSString stringWithFormat:@"info接口参数：%@", params]));
    NSString *requestURLString = [self.config.hostString stringByAppendingString:[self.class shareInfoPath]];
    [[TTNetworkManager shareInstance] requestForJSONWithURL:requestURLString params:params method:@"post" needCommonParams:YES requestSerializer:[BDUGSharePostRequestSerializer class] responseSerializer:nil autoResume:YES callback:^(NSError *error, id jsonObj) {
        [self.requestStatusDict setObject:@(BDUGShareDataRequestStatusDefault) forKey:key];
        BDUGShareDataModel *model;
        NSString *condition = @"failed";
        NSNumber *monitorResult = @(1);
        if (!error && [jsonObj isKindOfClass:[NSDictionary class]]) {
            if ([jsonObj isKindOfClass:[NSDictionary class]]) {
                model = [[BDUGShareDataModel alloc] initWithDict:jsonObj];
                //todo： 参照settings相关的数据缓存和网络隔离。
                [self.cacheDict setObject:model forKey:key];
                
                //请求成功才标记为status为finish结束。
                [self.requestStatusDict setObject:@(BDUGShareDataRequestStatusFinish) forKey:key];
                condition = @"success";
                monitorResult = @(0);
            }
        } else {
            BDUGLoggerError(([NSString stringWithFormat:@"BDUGShare - 分享信息接口请求失败：%@", error.description]));
        }
        !completion ?: completion(error.code, error.description, model);
        [BDUGShareEventManager event:kShareEventInfoInterfaceRequest params:@{
                                                                    @"is_success" : condition,
                                                                    }];
        [BDUGShareEventManager trackService:kShareMonitorInfo attributes:@{@"status" : monitorResult}];

    }];
}

- (BDUGShareDataItemModel *)itemModelWithPlatform:(NSString *)platform
                                          panelId:(NSString *)panelID
                                       resourceID:(NSString *)resourceID {
    if (self.config.isLocalMode) {
        return nil;
    }
    if (!panelID || panelID.length == 0) {
        return nil;
    }
    NSString *key = [self requestStatusKeyWithPanelId:panelID resourceId:resourceID];
    BDUGShareDataModel *model = [self.cacheDict objectForKey:key];
    if (!model) {
        return nil;
    }
    __block BDUGShareDataItemModel *result;
    [model.infoList enumerateObjectsUsingBlock:^(BDUGShareDataItemModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj isKindOfClass:[BDUGShareDataItemModel class]]) {
            return ;
        }
        if ([obj.sharePlatformActivityType isEqualToString:platform]) {
            result = obj;
            *stop = YES;
        }
    }];
    return result;
}

- (BDUGShareDataRequestStatus)requestStatusWithPanelId:(NSString *)panelId resourceId:(NSString *)resourceId {
    if (self.config.isLocalMode) {
        return BDUGShareDataRequestStatusFinish;
    }
    NSString *key = [self requestStatusKeyWithPanelId:panelId resourceId:resourceId];
    //todo:bytedancekit替换ttbase
    return [self.requestStatusDict btd_integerValueForKey:key];
}

- (void)cleanCache {
    [self.cacheDict removeAllObjects];
    [self.requestStatusDict removeAllObjects];
}

- (NSString *)requestStatusKeyWithPanelId:(NSString *)panelId resourceId:(NSString *)resourceId {
    NSString *key = [NSString stringWithFormat:@"p=%@r=%@", panelId, resourceId];
    return key;
}

#pragma mark - get

+ (NSString *)shareInfoPath {
    return @"share_strategy/v1/info/";
}

@end
