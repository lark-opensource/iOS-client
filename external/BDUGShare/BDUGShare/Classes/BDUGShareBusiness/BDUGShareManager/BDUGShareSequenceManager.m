//
//  BDUGShareSequenceManager.m
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/3/22.
//

typedef NS_ENUM(NSInteger, BDUGInitializeRequestStatus) {
    BDUGInitializeRequestStatusDefault = 0,
    BDUGInitializeRequestStatusRequesting = 1,
    BDUGInitializeRequestStatusSucceed = 2,
    BDUGInitializeRequestStatusFailed = 3,
};

#import "BDUGShareSequenceManager.h"
#import <TTNetworkManager/TTNetworkManager.h>
#import <TTNetworkManager/TTDefaultHTTPRequestSerializer.h>
#import <TTNetworkManager/TTHTTPResponseSerializerBase.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import "BDUGShareEvent.h"
#import "BDUGShareMacros.h"
#import "BDUGShareSettingsUtil.h"
#import "BDUGShareDataManager.h"
#import "BDUGShareDataModel.h"

static NSString *const kBDUGSharePanelDataKey = @"kBDUGSharePanelDataKey";

@implementation BDUGShareInitializeModel

- (NSDictionary *)dictFromProperties
{
    if (_channelList.count == 0 || _panelID.length == 0) {
        //panelID为空或者channelList为空，则直接返回nil
        return nil;
    }
    return @{@"channel_list" : _channelList ?: @[],
             @"filtered_channel_list" : _filteredChannelList ?: @[],
             @"panel_id" : _panelID ?: @"",
    };
}

@end

@interface BDUGShareSequenceManager ()

@property (nonatomic, strong) NSArray *sequenceArray;
//@property (nonatomic, strong) NSDictionary *sequenceDict;
@property (nonatomic, copy) NSString *tokenRegex;
@property (nonatomic, assign) BDUGInitializeRequestStatus requestStatus;

@end

@implementation BDUGShareSequenceManager

@synthesize sequenceArray = _sequenceArray;

+ (instancetype)sharedInstance {
    static dispatch_once_t once;
    static BDUGShareSequenceManager * sharedInstance;
    dispatch_once(&once, ^ { sharedInstance = [[self alloc] init]; });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.requestStatus = BDUGInitializeRequestStatusDefault;
        [BDUGShareEventManager setCommonParamsblock:^NSDictionary<NSString *,NSString *> *{
            return [self commonParamDict];
        }];
    }
    return self;
}

#pragma mark - public method

- (void)requestShareSequence {
    [self requestShareSequenceWithCompletion:nil];
}

- (void)requestShareSequenceWithCompletion:(BDUGInitializeRequestHandler)completion
{
    if (self.configuration.isLocalMode) {
        //localMode，不请求接口。
        !completion ?: completion(NO);
        return;
    }
    if (self.requestStatus == BDUGInitializeRequestStatusSucceed) {
        !completion ?: completion(YES);
        return;
    }
    self.requestStatus = BDUGShareDataRequestStatusRequesting;
    //https://bytedance.feishu.cn/space/doc/doccnreWBS1JVeDTpGwUQq
    NSString *requestURLString = [self.configuration.hostString stringByAppendingString:[self shareStrategyPath]];
    [[TTNetworkManager shareInstance] requestForJSONWithURL:requestURLString
                                                     params:nil method:@"GET"
                                           needCommonParams:YES
                                          requestSerializer:[TTDefaultHTTPRequestSerializer class]
                                         responseSerializer:[TTHTTPJSONResponseSerializerBase class]
                                                 autoResume:YES
                                                   callback:^(NSError *error, id jsonObj) {
                                                       BOOL succeed = NO;
                                                       if (!error && [jsonObj isKindOfClass:[NSDictionary class]] && [jsonObj[@"data"][@"panel_list"] isKindOfClass:[NSArray class]]) {
                                                           self.sequenceArray = jsonObj[@"data"][@"panel_list"];
                                                           self.tokenRegex = jsonObj[@"data"][@"token_reg"];
                                                           [[BDUGShareSettingsUtil sharedInstance] settingsRequestFinish:jsonObj[@"data"][@"settings"]];
                                                           succeed = YES;
                                                           self.requestStatus = BDUGInitializeRequestStatusSucceed;
                                                       } else {
                                                           BDUGLoggerError(([NSString stringWithFormat:@"BDUGShare - 初始化接口请求失败: error：%@", error.description]));
                                                           self.requestStatus = BDUGInitializeRequestStatusFailed;
                                                       }
                                                       !completion ?: completion(succeed);
                                                       [BDUGShareEventManager event:kShareEventInitialInterfaceRequest params:@{
                                                           @"is_success" : (succeed ? @"success" : @"failed"),
                                                       }];
                                                       [BDUGShareEventManager trackService:kShareMonitorInitial attributes:@{@"status" : @((succeed ? 0 : 1))}];
                                                   }];
}

- (NSArray *)resortActivityItems:(NSArray *)activityItems
                         panelId:(NSString *)panelId {
    NSArray *sequenceArray = [self.class validContentItemsWithPanelId:panelId];
    if (!sequenceArray || sequenceArray.count == 0) {
        return activityItems;
    }
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if ([[activityItems firstObject] isKindOfClass:[NSArray class]]) {
        //二维数组
        [activityItems enumerateObjectsUsingBlock:^(NSArray *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSArray *itemResult = [self resortActivityItems:obj
                                                    panelId:panelId];
            if (itemResult.count > 0) {
                [result addObject:itemResult];
            }
        }];
        return result;
    } else {
        NSMutableArray *inOrderUnion = [[NSMutableArray alloc] init];
        [sequenceArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![obj isKindOfClass:[NSString class]] || obj.length == 0) {
                return ;
            }
            Class activityItemClass = NSClassFromString(obj);
            if (activityItemClass == nil) {
                //todo：接log平台，未定义分享类型。
                return;
            }
            [activityItems enumerateObjectsUsingBlock:^(id<BDUGActivityContentItemProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:activityItemClass]) {
                    //在服务端控制的array中
                    [inOrderUnion addObject:obj];
                }
            }];
        }];
        NSInteger j = 0;
        NSArray *serverControllArray = [BDUGShareDataItemModel inServerControllItemTypeDict].allValues;
        for (NSInteger i = 0; i < activityItems.count; i++) {
            id<BDUGActivityContentItemProtocol> object = activityItems[i];
            if ([inOrderUnion containsObject:object]) {
                if (j < inOrderUnion.count) {
                    //在并集中的。
                    [result addObject:inOrderUnion[j]];
                    j++;
                }
            } else if (![serverControllArray containsObject:NSStringFromClass(object.class)]) {
                //服务器不控制的
                [result addObject:object];
            }
        }
        return result;
    }
}

+ (NSArray *)validContentItemsWithPanelId:(NSString *)panelId {
    __block NSArray *sequenceArray;
    [[BDUGShareSequenceManager sharedInstance].sequenceArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj[@"panel_id"] isEqualToString:panelId]) {
            sequenceArray = obj[@"channel_list"];
            *stop = YES;
        }
    }];
    sequenceArray = [[self sharedInstance] configSequenceArray:sequenceArray];
    return sequenceArray;
}

+ (NSArray *)hiddenContentItemsWhenNotInstalledWithPanelId:(NSString *)panelId {
    __block NSArray *sequenceArray;
    [[BDUGShareSequenceManager sharedInstance].sequenceArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj[@"panel_id"] isEqualToString:panelId]) {
            sequenceArray = obj[@"filtered_channel_list"];
            *stop = YES;
        }
    }];
    sequenceArray = [[self sharedInstance] configSequenceArray:sequenceArray];
    return sequenceArray;
}

#pragma mark - tricky

- (void)configInitlizeDataWithItemModel:(BDUGShareInitializeModel *)model
{
    if (!self.configuration.isLocalMode) {
        return;
    }
    NSDictionary *dict = [model dictFromProperties];
    if (!dict) {
        return;
    }
    if (self.sequenceArray.count == 0) {
        //原本没有数据，直接赋值
        self.sequenceArray = @[dict];
    } else {
        __block NSInteger index = -1;
        [self.sequenceArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj[@"panel_id"] isEqualToString:model.panelID]) {
                index = idx;
                *stop = YES;
            }
        }];
        NSMutableArray *copyArray = self.sequenceArray.mutableCopy;
        if (index == -1) {
            //没有对应的panel数据，直接拼接
            [copyArray addObject:dict];
        } else {
            //panel重复，替换.
            [copyArray replaceObjectAtIndex:index withObject:dict];
        }
        self.sequenceArray = copyArray.copy;
    }
}

#pragma mark - common param

- (NSDictionary *)commonParamDict
{
    return @{
        @"ug_share_did" : (self.configuration.deviceID ?: @""),
        @"ug_share_aid" : (self.configuration.appID ?: @""),
        @"ug_share_v_code" : BDUG_SHARE_SDK_VERSION,
        @"ug_share_v_name" : BDUG_SHARE_SDK_NAME,
        @"ug_share_os_api" : ([UIDevice currentDevice].systemVersion ?: @""),
        @"ug_share_platform" : @"iPhone",
        @"tag" : @"ug_sdk_share",
    };
}

#pragma mark - clean

- (void)cleanCache {
    self.sequenceArray = nil;
    self.tokenRegex = nil;
    self.requestStatus = BDUGInitializeRequestStatusDefault;
}

#pragma mark - filter

//过滤客户端本地未定义的分享类型。
//todo： 文档完善：过滤逻辑的example
- (NSArray *)configSequenceArray:(NSArray *)serverArray {
    NSMutableArray *sequenceArray = [[NSMutableArray alloc] init];
    NSDictionary *adapterDict = [BDUGShareDataItemModel inServerControllItemTypeDict];
    [serverArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj isKindOfClass:[NSString class]]) {
            return ;
        }
        NSString *classString = adapterDict[obj];
        if (classString) {
            if (NSClassFromString(classString) == nil) {
                //todo：接log平台，未定义分享类型。
                return;
            }
            [sequenceArray addObject:classString];
        } else {
            //不处理即可。
        }
    }];
    return sequenceArray.copy;
}

- (void)setTokenRegex:(NSString *)tokenRegex {
    _tokenRegex = tokenRegex;
    [[NSUserDefaults standardUserDefaults] setObject:tokenRegex forKey:@"BDUGShareTokenRegex"];
}

#pragma mark - set

- (void)setSequenceArray:(NSArray *)sequenceArray {
    _sequenceArray = sequenceArray;
    [[NSUserDefaults standardUserDefaults] setObject:sequenceArray forKey:kBDUGSharePanelDataKey];
}

- (void)setRequestStatus:(BDUGInitializeRequestStatus)requestStatus {
    _requestStatus = requestStatus;
    BDUGSettingsRequestStatus settingsStatus;
    switch (requestStatus) {
        case BDUGInitializeRequestStatusDefault:
            settingsStatus = BDUGSettingsRequestStatusDefault;
            break;
        case BDUGInitializeRequestStatusSucceed:
            settingsStatus = BDUGSettingsRequestStatusSucceed;
            break;
        case BDUGInitializeRequestStatusRequesting:
            settingsStatus = BDUGSettingsRequestStatusRequesting;
            break;
        case BDUGInitializeRequestStatusFailed:
            settingsStatus = BDUGSettingsRequestStatusFailed;
            break;
        default:
            break;
    }
    [BDUGShareSettingsUtil sharedInstance].requestStatus = settingsStatus;
}

#pragma mark - get

//    wiki: https://bytedance.feishu.cn/space/doc/doccnreWBS1JVeDTpGwUQq#
- (NSString *)shareStrategyPath {
    return @"share_strategy/v2/init/";
}

- (NSArray *)sequenceArray {
    if (!_sequenceArray) {
        _sequenceArray = [[NSUserDefaults standardUserDefaults] objectForKey:kBDUGSharePanelDataKey];
    }
    return _sequenceArray;
}

@end
