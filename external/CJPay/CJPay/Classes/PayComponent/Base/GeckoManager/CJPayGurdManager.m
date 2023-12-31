//
// Created by 易培淮 on 2020/12/9.
//

#import "CJPayGurdManager.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayGurdService.h"
#import <IESGeckoKit/IESGeckoKit.h>
#import <BDWebKit/IESFalconManager.h>
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "UIImage+CJPay.h"
#import "CJPayABTestManager.h"
#import "CJPaySyncChannelsConfigModel.h"


NSString * const CJPayGurdWebViewOfflineNotification = @"CJPayWebViewOfflineNotification";
NSString * const CJPayGurdWebViewActionKey = @"action";

typedef NS_ENUM(NSUInteger, CJPayOfflineActionType) {
    CJPayOfflineActionTypeNew = 0,
    CJPayOfflineActionTypePermanent = 1,
    CJPayOfflineActionTypeDealloc = 2,
};

@interface CJPayGurdManager () <IESGurdEventDelegate, CJPayGurdService, IESFalconCustomInterceptor>

@property (nonatomic, copy) NSString *accessKey;
@property (nonatomic, copy) NSString *groupName;
@property (nonatomic, copy) NSArray<NSString *> *imgChannelList;
@property (nonatomic, copy) NSString *cdnUrl;

@property (nonatomic, assign) BOOL enable;
@property (nonatomic, copy) NSArray<NSString *> *prefixArray;
@property (nonatomic, copy) CJPayGurdSettingsModel *configModel;
@property (nonatomic, copy) CJPayGurdImgModel *imgConfigModel;
@property (nonatomic, assign) BOOL isFalconRegister;
@property (nonatomic, assign) BOOL isEnableMergeGurdRequest;

@end

@implementation CJPayGurdManager

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(defaultService), CJPayGurdService)
})

+ (instancetype)defaultService {
    static CJPayGurdManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [CJPayGurdManager new];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _enable = NO;
        _enableImg = YES;
        _enableCDNImg = YES;
        _isFalconRegister = NO;
        _enableGurdImg = NO;
        _isEnableMergeGurdRequest = NO;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Gecko API

- (void)i_enableMergeGurdRequest:(BOOL)enable {
    CJPayLogInfo(@"[CJPayGurdManager i_enableMergeGurdRequest:%@]", @(enable).stringValue);
    self.isEnableMergeGurdRequest = enable;
}

- (void)i_enableGurdOfflineAfterSettings {
    self.enable = YES;
    self.configModel = [CJPaySettingsManager shared].currentSettings.gurdFalconModel;
    self.imgConfigModel = [CJPaySettingsManager shared].currentSettings.gurdImgModel;
    [self p_syncResources];
    self.enableGurdImg = YES;
    [self p_addWebViewObserver];
}

#pragma mark - Gecko Config

- (void)p_syncResources {
    //发起聚合请求
    if (!self.enable) {
        return;
    }
    if (![IESGeckoKit didSetup]) {
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [IESGurdKit registerAccessKey:self.accessKey SDKVersion:CJString([CJSDKParamConfig defaultConfig].version)];
        //settings和端上都能控制是否由sdk请求离线包资源，默认平台下发
        if (self.configModel.isMergeRequest && self.isEnableMergeGurdRequest) {
            return;
        }
        
        @CJWeakify(self)
        [IESGurdKit enqueueSyncResourcesTaskWithParamsBlock:^(IESGurdFetchResourcesParams * _Nonnull params) {
            @CJStrongify(self)
            params.accessKey = self.accessKey;
            params.groupName = self.groupName;
            params.downloadPriority = IESGurdDownloadPriorityLow;
        } completion: ^(BOOL succeed, IESGurdSyncStatusDict dict) {
            @CJStrongify(self)
            NSString *eventName = [NSString stringWithFormat:@"wallet_rd_%@_offline_sync", DW_gecko];
            [CJMonitor trackService:eventName
                           category:@{@"success": @(succeed),
                                      @"group_name":CJString(self.groupName)}
                              extra:@{}];
            
        }];
    });
    [self syncResourcesWhenInit];
}

- (void)syncResourcesWhenInit
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *syncChannelsConfigJsonStr = [[CJPayABTestManager sharedInstance] getABTestValWithKey:CJPaySyncChannelsConfig exposure:NO];
        JSONModelError *error;
        CJPaySyncChannelsConfigModel *model = [[CJPaySyncChannelsConfigModel alloc] initWithString:syncChannelsConfigJsonStr error:&error];
        if (!error) {
            CGFloat delayTime = model.initDelayTime;
            BOOL disableThrottle = model.disableThrottle;
            NSDictionary<NSString *, NSArray<NSString *> *> *channels = model.sdkInitChannels;
            if (delayTime > 0) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    // 预取channels
                    [self p_syncResourcesWithChannels:channels disableThrottle:disableThrottle scene:@"sdk_init"];
                });
            }
        }
    });
}

- (void)syncResourcesWhenSelectNotify
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 预取channels
        NSString *syncChannelsConfigJsonStr = [[CJPayABTestManager sharedInstance] getABTestValWithKey:CJPaySyncChannelsConfig exposure:NO];
        JSONModelError *error;
        CJPaySyncChannelsConfigModel *model = [[CJPaySyncChannelsConfigModel alloc] initWithString:syncChannelsConfigJsonStr error:&error];
        if (!error) {
            BOOL disableThrottle = model.disableThrottle;
            NSDictionary<NSString *, NSArray<NSString *> *> *channels = model.selectNotifyChannels;
            [self p_syncResourcesWithChannels:channels disableThrottle:disableThrottle scene:@"select_notify"];
        }
    });
}

- (void)syncResourcesWhenSelectHomepage
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 预取channels
        NSString *syncChannelsConfigJsonStr = [[CJPayABTestManager sharedInstance] getABTestValWithKey:CJPaySyncChannelsConfig exposure:NO];
        JSONModelError *error;
        CJPaySyncChannelsConfigModel *model = [[CJPaySyncChannelsConfigModel alloc] initWithString:syncChannelsConfigJsonStr error:&error];
        if (!error) {
            BOOL disableThrottle = model.disableThrottle;
            NSDictionary<NSString *, NSArray<NSString *> *> *channels = model.selectHomePageChannels;
            [self p_syncResourcesWithChannels:channels disableThrottle:disableThrottle scene:@"select_homepage"];
        }
    });
}

- (void)p_syncResourcesWithChannels:(NSDictionary<NSString *, NSArray<NSString *> *> *)allChannels disableThrottle:(BOOL)disableThrottle scene:(NSString *)scene
{
    if (BTD_isEmptyDictionary(allChannels)) {
        return;
    }
    if (![IESGeckoKit didSetup]) {
        return;
    }
    
    [allChannels enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull accessKey, NSArray<NSString *> * _Nonnull channels, BOOL * _Nonnull stop) {
        if (BTD_isEmptyArray(channels) || BTD_isEmptyString(accessKey)) {
            return;
        }
        
        __block BOOL accessKeyHasRegistered = NO;
        if ([accessKey isEqualToString:[CJPayGurdManager defaultService].accessKey]) {
            accessKeyHasRegistered = YES;
            [IESGeckoKit registerAccessKey:[CJPayGurdManager defaultService].accessKey SDKVersion:CJString([CJSDKParamConfig defaultConfig].version)];
        } else {
            [[IESGeckoKit allRegisterModels] enumerateObjectsUsingBlock:^(IESGurdRegisterModel * _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([model.accessKey isEqualToString:accessKey] && model.isRegister) {
                    accessKeyHasRegistered = YES;
                    *stop = YES;
                }
            }];
        }
        
        if (accessKeyHasRegistered) {
            // 访问channel
            [channels enumerateObjectsUsingBlock:^(NSString *  _Nonnull channel, NSUInteger idx, BOOL * _Nonnull stop) {
                if (!BTD_isEmptyString(channel)) {
                    [IESGurdKit rootDirForAccessKey:accessKey channel:channel];
                }
            }];
            // 拉取离线包
            @CJWeakify(self)
            [IESGeckoKit syncResourcesWithParamsBlock:^(IESGurdFetchResourcesParams * _Nonnull params) {
                @CJStrongify(self)
                params.accessKey = accessKey;
                params.channels = channels;
                params.disableThrottle = disableThrottle;
                params.downloadPriority = IESGurdDownloadPriorityUserInteraction;
            } completion:^(BOOL succeed, IESGurdSyncStatusDict  _Nonnull dict) {
                CJPayLogInfo(@"forceUpdateChannel:%@, result:%@, status:%@", channels, @(succeed), dict);
                if ([channels containsObject:@"cpay"]) {
                    NSInteger code = dict[@"cpay"] ? [dict cj_integerValueForKey:@"cpay"] : -9999;
                    [CJTracker event:@"wallet_rd_force_update_channel_result" params:@{
                        @"cpay_channel_result" : @(code),
                        @"cpay_channel_is_success" : @(succeed),
                        @"scene" : CJString(scene)
                    }];
                }
            }];
        }
    }];
}

#pragma mark - Falcon Config

- (void)p_registerFalcon {
    if (!self.enable) {
        return;
    }
    if (!self.configModel.falconSettings.enableIntercept) {
        return;
    }
    if (self.isFalconRegister) {
        return;
    }
    self.isFalconRegister = YES;
    self.prefixArray = [self p_getPrefix];
    if (Check_ValidArray(self.prefixArray)) {
        [IESFalconManager registerPatterns:self.prefixArray forGurdAccessKey:self.accessKey];
    }
    [IESFalconManager registerCustomInterceptor:self];
    CJPayLogInfo(@"成功开启Falcon");
}

- (void)p_unRegisterFalcon {
    if (!self.isFalconRegister) {
        return;
    }
    //Falcon 反注册
    [IESFalconManager unregisterCustomInterceptor:self];
    if (Check_ValidArray(self.prefixArray)) {
        [IESFalconManager unregisterPatterns:self.prefixArray];
    }
    self.isFalconRegister = NO;
    CJPayLogInfo(@"成功关闭Falcon");
}


#pragma mark - IESGurdEventDelegate

- (void)gurdDidSyncResourceWithAccessKey:(NSString *)accessKey
                                 succeed:(BOOL)succeed
                              statusDict:(IESGurdSyncStatusDict)statusDict {
    if (!self.configModel.isMergeRequest || !self.isEnableMergeGurdRequest) {
        return;
    }
    if (Check_ValidString(accessKey) && Check_ValidString(self.accessKey) && [accessKey isEqualToString:self.accessKey]) {
        NSString *eventName = [NSString stringWithFormat:@"wallet_rd_%@_offline_sync", DW_gecko];
        [CJMonitor trackService:eventName
                       category:@{@"success": @(succeed),
                                  @"group_name":CJString([statusDict cj_toStr])}
                          extra:@{}];
    }
}


#pragma mark - Getter

- (NSString *)accessKey {
    _accessKey = @"c0493580c3e3829043cb33227b6e2d80";
    return _accessKey;
}

- (NSString *)groupName {
    _groupName = [NSString stringWithFormat:@"cjpay_%@", DW_gecko];
    return _groupName;
}

- (NSString *)cdnUrl {
    if (self.imgConfigModel && Check_ValidString(self.imgConfigModel.cdnUrl)) {
        return self.imgConfigModel.cdnUrl;
    } else {
        return @"https://lf3-static.bytednsdoc.com/obj/eden-cn/zly_zvp_fhwqj/ljhwZthlaukjlkulzlp/prod";
    }
}

- (NSArray<NSString *> *)imgChannelList {
    if (self.imgConfigModel && Check_ValidArray(self.imgConfigModel.iosImgChannelList)) {
        return self.imgConfigModel.iosImgChannelList;
    } else {
        return @[[NSString stringWithFormat:@"cjpay_img_%@", DW_gecko]];
    }
}

#pragma mark - Gecko IMG API

- (nullable NSString *)i_getImageUrlOrName:(NSString *_Nullable)imageName {
    if (!Check_ValidString(imageName)) {
        return nil;
    }
    UIImage *image = [UIImage cj_imageWithName:imageName];
    if (image) {
        return imageName;
    }
    if ([imageName hasPrefix:@"#"]){
        return imageName;
    }
    if (!self.enableImg) {
        return nil;
    }
    NSString *gurdChannelPath;
    if (self.enableGurdImg && [self p_isImageExistGurd:imageName]) {
        gurdChannelPath = [IESGeckoKit rootDirForAccessKey:self.accessKey channel:self.imgChannelList.firstObject];
    }
    if (gurdChannelPath) {
        return [NSString stringWithFormat:@"CJ%@//%@/%@.png", UP_Gecko, gurdChannelPath, imageName];
    }
    if (self.enableCDNImg) {
        return [NSString stringWithFormat:@"%@/%@.png", [self cdnUrl],imageName];
    } else {
        return nil;
    }
}

- (NSDictionary *)i_getPerformanceMonitorConfigDictionary {
    NSData *data = [IESGeckoKit dataForPath:@"event_upload_rules.json" accessKey:self.accessKey channel:@"cjpay_performance_monitor"];
    if (!data) {
        return @{};
    }
    NSDictionary *cjpayPerformanceMonitor = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];//转换数据格式
    return cjpayPerformanceMonitor;
}

#pragma mark - Private Method

- (BOOL) p_isGurdImgEnable {
    if (self.imgConfigModel) {
        return self.enable && self.enableImg && self.enableGurdImg && self.imgConfigModel.enableGurdImg;
    } else {
        return self.enable && self.enableImg && self.enableGurdImg;
    }
}

- (nullable NSData *)p_getFileFromGurdWithName:(NSString *)fileName channel:(NSString *)channel{
    return [IESGurdKit dataForPath:fileName accessKey:self.accessKey channel:channel];
}

- (BOOL )p_isImageExistGurd:(NSString *)imageName {
    if (![self p_isGurdImgEnable] || !Check_ValidArray(self.imgChannelList)) {
        return NO;
    }
    NSString *absoluteName = [NSString stringWithFormat:@"%@.png", imageName];
    NSData *data = [self p_getFileFromGurdWithName:absoluteName channel:self.imgChannelList.firstObject];
    if (data) {
        return YES;
    } else {
        NSString *eventName = [NSString stringWithFormat:@"wallet_rd_%@_img_loss", DW_gecko];
        [CJMonitor trackService:eventName
                       category:@{@"image_name" : CJString(imageName),
                                  @"img_channel_list" : CJString([self.imgChannelList  componentsJoinedByString:@","]),
                                  @"channel_status" : [self p_checkChannelStatus:self.imgChannelList.firstObject]
                       }
                          extra:@{}];
        [self p_updateGurdImgResources];
        return NO;
    }
}

- (void)p_updateGurdImgResources {
    if (![IESGeckoKit didSetup]){
        return;
    }
    [IESGeckoKit registerAccessKey:[CJPayGurdManager defaultService].accessKey SDKVersion:CJString([CJSDKParamConfig defaultConfig].version)];
    
    @CJWeakify(self)
    [IESGeckoKit syncResourcesWithParamsBlock:^(IESGurdFetchResourcesParams * _Nonnull params) {
        @CJStrongify(self)
        params.accessKey = self.accessKey;
        params.channels = self.imgChannelList;
        params.disableThrottle = YES;
    } completion:nil];
}

- (nullable NSArray<NSString *>*)p_getPrefix {
    CJPaySettings *curSettings = [CJPaySettingsManager shared].currentSettings;
    if (!curSettings.gurdFalconModel.falconSettings.enableIntercept) {
        return nil;
    }
    NSMutableArray<NSString *>* prefixArray =  [NSMutableArray new];
    if(Check_ValidArray(curSettings.gurdFalconModel.falconSettings.falconConfigList)) {
        NSArray<CJPayFalconDefaultConfigModel> *array = curSettings.gurdFalconModel.falconSettings.falconConfigList;
        [array enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[CJPayFalconDefaultConfigModel class]]) {
                CJPayFalconDefaultConfigModel *defaultModel = (CJPayFalconDefaultConfigModel*)obj;
                if (defaultModel.enableDefaultConfig){
                    [prefixArray addObjectsFromArray: defaultModel.prefixList];
                }
            }
        }];
    }
    return [prefixArray copy];
}

// 判断是否属于静态资源
- (BOOL)p_isStaticSourceWithString:(NSString * _Nonnull)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    NSArray *extensionStrs = @[@"css", @"js", @"png", @"jpg", @"jpeg", @"eot", @"svg", @"ttf", @"woff", @"otf"];
    return [extensionStrs containsObject:url.path.pathExtension];
}

- (nullable NSString *)p_getStaticSourceFilePath:(NSURL *)url model:(CJPayFalconCustomConfigModel *)model {
    // 找匹配的前缀
    BOOL isMatched = Check_ValidString(model.assetPath) && [url.path hasPrefix:model.assetPath];
    if (!isMatched) {
        return nil;
    }
    // 去掉前缀，保留后缀
    if (url.path.length <= model.assetPath.length) {
        return nil;
    }
    NSString *subPath = [url.path substringFromIndex:model.assetPath.length];
    
    return [subPath stringByReplacingOccurrencesOfString:@"//" withString:@"/"];
}

- (nullable NSString *)p_getHtmlSourceFilePath:(NSURL *)url model:(CJPayFalconCustomConfigModel *)model {
    if (!model.interceptHtml) {
        return @"";
    }
    __block NSString *localFilePath = nil;
    
    [model.htmlFileList enumerateObjectsUsingBlock:^(CJPayFalconHtmlConfigModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (Check_ValidString(obj.path) && [url.path hasPrefix:obj.path]) {
            localFilePath = obj.file;
            *stop = YES;
        }
    }];
    return localFilePath;
}

// 在单个channel匹配到资源前缀后转成本地路径
- (nullable NSString *)p_parseAssetURLString:(NSString * _Nonnull)urlString
                              model:(CJPayFalconCustomConfigModel * _Nonnull)model
{
    NSURL *url = [NSURL URLWithString:urlString];
    if (!(Check_ValidString(urlString)) || !model || !url) {
        return @"";
    }

    // 看请求的域名是否在拦截的域名列表里
    if (![model.hostList containsObject:url.host]) {
        return @"";
    }
    
    if ([self p_isStaticSourceWithString:urlString]) {
        return [self p_getStaticSourceFilePath:url model:model];
    } else {
        return [self p_getHtmlSourceFilePath:url model:model];
    }
}

// 从URL中尝试匹配获取本地数据
- (nullable NSData *)p_localDataWithString:(NSString * _Nonnull)urlString
{
    __block NSData *localData;
    NSArray<CJPayFalconCustomConfigModel> *customConfigModelList = self.configModel.falconSettings.customConfigList;
    @CJWeakify(self);
    [customConfigModelList enumerateObjectsUsingBlock:^(CJPayFalconCustomConfigModel *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @CJStrongify(self);
        if (!obj.enableCustomConfig) {
            return;
        }
        NSString *filePath = [self p_parseAssetURLString:urlString model:obj];
        if (!Check_ValidString(filePath)) {
            return;
        }
        
        *stop = YES;
        
        if ([IESGeckoKit cacheStatusForAccessKey:self.accessKey channel:obj.channel] == IESGurdChannelCacheStatusNotFound) {
            NSString *eventName = [NSString stringWithFormat:@"wallet_rd_%@_channel_loss", DW_gecko];
            [CJMonitor trackService:eventName
                           category:@{@"url":CJString(urlString),
                                      @"filePath":CJString(filePath),
                                      @"download_channel":CJString(obj.channel),
                                      @"channel_status":CJString([self p_checkChannelStatus:obj.channel])}
                              extra:@{}];
            return;
        }
        uint64_t packageVersion = [IESGeckoKit packageVersionForAccessKey:self.accessKey channel:obj.channel];
        if (packageVersion == 0) {
            [IESGeckoKit applyInactivePackageForAccessKey:self.accessKey
                                                  channel:obj.channel
                                               completion:nil];
        }
        
        CJPayLogInfo(@"%@资源: 版本: %llu, url: %@", DW_gecko, packageVersion, urlString);
        
        localData = [IESGurdKit dataForPath:filePath accessKey:self.accessKey channel:obj.channel];
        if (!localData) {
            NSString *eventName = [NSString stringWithFormat:@"wallet_rd_%@_offline_loss", DW_gecko];
            [CJMonitor trackService:eventName
                           category:@{@"url":CJString(urlString),
                                      @"filePath":CJString(filePath),
                                      @"download_channel":CJString(obj.channel),
                                      @"channel_status":CJString([self p_checkChannelStatus:obj.channel])}
                              extra:@{}];
        } else {
            if (![self p_isStaticSourceWithString:urlString]) {
                NSURL *url = [NSURL URLWithString:urlString];
                NSString *keyName = [NSString stringWithFormat:@"is_use_%@", DW_gecko];//is_use_gecko
                [CJTracker event:@"wallet_rd_webview_hit_offline"
                          params:@{@"host": CJString(url.host),
                                   @"path": CJString(url.path),
                                   keyName: @"1"}];
            }
        }
    }];
    return localData;
}

- (void)p_addWebViewObserver {
    [[NSNotificationCenter defaultCenter] addObserverForName:CJPayGurdWebViewOfflineNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        @synchronized(self) {
            if (!(note.object[CJPayGurdWebViewActionKey])) {
                return;
            }
            CJPayOfflineActionType type = [note.object[CJPayGurdWebViewActionKey] integerValue];
            switch (type) {
                case CJPayOfflineActionTypeNew: {
                    [self p_registerFalcon];
                    break;
                }
                case CJPayOfflineActionTypeDealloc: {
                    [self p_unRegisterFalcon];
                    break;
                }
                case CJPayOfflineActionTypePermanent:
                default:
                    break;
            }
        }
    }];
}

- (NSString *)p_checkChannelStatus:(NSString *)channelName {
    if (Check_ValidString(channelName)){
        IESGurdChannelCacheStatus status = [IESGeckoKit cacheStatusForAccessKey:self.accessKey channel:channelName];
        switch (status) {
            case IESGurdChannelCacheStatusActive:
                return @"Active";
            case IESGurdChannelCacheStatusInactive:
                return @"Inactive";
            case IESGurdChannelCacheStatusNotFound:
            default:
                return @"NotFound";
        }
    } else {
        return @"NULLName";
    }
}

#pragma mark - IESFalconCustomInterceptor

- (NSData * _Nullable)falconDataForURLRequest:(NSURLRequest *)request {
    return [self p_localDataWithString:request.URL.absoluteString];
}

- (BOOL)shouldInterceptForRequest:(NSURLRequest*)request {
    
    if (!request || !request.URL || !(Check_ValidString(request.URL.absoluteString))) {
        return NO;
    }
    
    // 只拦截get请求
    if (![request.HTTPMethod isEqualToString:@"GET"]) {
        // only handle GET request
        return NO;
    }
    
    NSString* urlString = request.URL.absoluteString;
    NSData * data = [self p_localDataWithString:urlString];
    CJPayLogInfo(@"离线包拦截结果%@,  URL：%@", data ? @"成功" : @"失败", urlString);
    if (data) {
        return YES;
    } else {
        return NO;
    }
}

@end
