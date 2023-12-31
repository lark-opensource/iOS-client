//
//  HMDCloudCommandManager.m
//  
//
//  Created by fengyadong on 2018/8/22.
//

#import "HMDCloudCommandManager.h"
#import <AWECloudCommand/AWECloudCommandManager.h>
#import "HMDCloudCommandNetworkIMP.h"
#import "HMDGCD.h"
#import "hmd_section_data_utility.h"
#if RANGERSAPM
#import "HMDInjectedInfo+NetworkSchedule.h"
#import "RangersAPMCloudCommandURLProvider.h"
#else
#import "HMDInjectedInfo.h"
#import "HMDPerformanceUpload.h"
#import "HMDExceptionUpload.h"
#import <AWECloudCommand/AWECloudCommandManager.h>
#import "HMDInjectedInfo.h"
#import "HMDInjectedInfo+NetworkSchedule.h"
#import "HMDCloudCommandFileDelete.h"
#import "Heimdallr+Private.h"
#import "HMDGeneralAPISettings.h"
#endif
#import "HMDCloudCommandManager+Private.h"
// PrivateServices
#import "HMDDebugLogger.h"
#import "HMDURLManager.h"
#import "HMDURLSettings.h"

NSString *const kHMDModuleCloudCommand = @"cloud_command";

HMD_LOCAL_MODULE_CONFIG(HMDCloudCommandManager)

@interface HMDCloudCommandManager()

@property (nonatomic, assign) int32_t serviceID;
@property (nonatomic, assign) int32_t methodID;
@property (atomic, assign, readwrite) BOOL isRunning;
@property (atomic, assign) BOOL isAutoPullEnabled;
@property (nonatomic, assign) BOOL isObserving;//是否正在监听应用切换到前台的通知
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (atomic, assign) BOOL isUpdatedConfig;
@property (nonatomic, strong, readwrite) HMDCloudCommandConfig *cloudCommandConfig;
@property (nonatomic, strong) dispatch_semaphore_t configUpdateSemphore;

@end

@implementation HMDCloudCommandManager

@synthesize isObserving = _isObserving;

+ (instancetype)sharedInstance {
    static HMDCloudCommandManager *instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDCloudCommandManager alloc] init];
    });
    
    return instance;
}

- (instancetype)init {
    if(self = [super init]) {
        _serviceID = 1004;
        _methodID = 1;
        _isAutoPullEnabled = YES;
        _isObserving = NO;
        _configUpdateSemphore = dispatch_semaphore_create(0);
        _serialQueue = dispatch_queue_create("com.heimdallr.cloudcommand", DISPATCH_QUEUE_SERIAL);
#if !RANGERSAPM
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkRequestEnableChanged) name:kHMDNetworkScheduleNotification object:nil];
#endif
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupLongConnectChannelIfAvailable {
    hmd_safe_dispatch_async(self.serialQueue, ^{
        [self _setupLongConnectChannel];
    });
}

- (void)_setupLongConnectChannel {
    [[AWECloudCommandManager sharedInstance] setCloudCommandParamModelBlock:^AWECloudCommandParamModel * _Nonnull{
        AWECloudCommandParamModel *model = [[AWECloudCommandParamModel alloc] init];
        model.appID = [HMDInjectedInfo defaultInfo].appID;
        model.deviceId = [HMDInjectedInfo defaultInfo].deviceID;
        model.userId = [HMDInjectedInfo defaultInfo].userID;
        
        return model;
    }];
    
    [self setPushManagerBroadcastEnabled:YES];
#if RANGERSAPM
    [[AWECloudCommandManager sharedInstance] setURLBlock:^NSString * _Nullable(AWECloudCommandURLType type) {
        id<HMDURLProvider> provider = nil;
        if (type == AWECloudCommandURLTypeFetch) {
            provider = [[RangersAPMCloudCommandDownloadURLProvider alloc] init];
        } else if (type == AWECloudCommandURLTypeUpload) {
            provider = [[RangersAPMCloudCommandUploadURLProvider alloc] init];
        }
        if (provider) {
            return [HMDURLManager URLWithProvider:provider forAppID:[HMDInjectedInfo defaultInfo].appID];
        }
        return nil;
    }];
#else
    //configure common params from host
    [AWECloudCommandManager sharedInstance].commonParamsBlock = [HMDInjectedInfo defaultInfo].commonParamsBlock;
    
    //云控上报域名和异常文件上报域名保持一致
    if ([HMDInjectedInfo defaultInfo].fileUploadHost) {
        [AWECloudCommandManager sharedInstance].host = [HMDInjectedInfo defaultInfo].fileUploadHost;
    }
#endif
    // 设置云控的网络代理
    [self setCloudCommandNetWorkDelegateIMP];
    [self setupCustomerCloudCommand];
    
    [HMDDebugLogger printLog:@"CloudCommand start successfully!"];
    
    //启动时候尝试拉取云控指令
    [self getCloudCommandIfAvailable];
}

// 设置 AWECloudCommand 的网络库代理实现  -> TTNet
- (void)setCloudCommandNetWorkDelegateIMP {
    // 如果不存在 cloudCommand 的网络的代理设置为 Heimdallr 的
#if RANGERSAPM
    HMDCloudCommandNetworkIMP *networkDelegate = [HMDCloudCommandNetworkIMP sharedInstance];
    [AWECloudCommandNetworkHandler sharedInstance].networkDelegate = networkDelegate;
#else
    if (![AWECloudCommandNetworkHandler sharedInstance].networkDelegate) {
        HMDCloudCommandNetworkIMP *networkDelegate = [HMDCloudCommandNetworkIMP sharedInstance];
        [AWECloudCommandNetworkHandler sharedInstance].networkDelegate = networkDelegate;
    }
#endif
}

// 添加自定义删除指令
- (void)setupCustomerCloudCommand {
#if !RANGERSAPM
    [[AWECloudCommandManager sharedInstance] addCustomCommandHandlerCls:[HMDCloudCommandFileDelete class]];
#endif
}

- (void)closeLongConnetChannelIfAvailable {
    [self setPushManagerBroadcastEnabled:NO];
    self.isObserving = NO;
}

- (void)setAutoPullCommandEnable:(BOOL)enabled {
    self.isAutoPullEnabled = enabled;
    self.isObserving = enabled;
}

#if !RANGERSAPM
- (void)setFilePathBlockList:(NSArray<NSString *> *)blockList {
    [AWECloudCommandManager sharedInstance].blockList = blockList;
}

- (void)setIfForbidCloudCommandBlock:(BOOL (^)(AWECloudCommandModel * type))block {
    if ([[AWECloudCommandManager sharedInstance] respondsToSelector:@selector(forbidCloudCommandUpload)]) {
        [AWECloudCommandManager sharedInstance].forbidCloudCommandUpload = block;
    }
}
#endif

- (void)setIsObserving:(BOOL)isObserving {
    __weak typeof(self) weakSelf = self;
    hmd_safe_dispatch_async(self.serialQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf && strongSelf->_isObserving != isObserving) {
            strongSelf->_isObserving = isObserving;
            if (isObserving) {
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
            } else {
                [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
            }
        }
    });
}

- (BOOL)isObserving {
    __block BOOL isObserving = NO;
    __weak typeof(self) weakSelf = self;
    dispatch_sync(self.serialQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            isObserving = strongSelf->_isObserving;
        }
    });
    
    return isObserving;
}

- (void)executeCommandWithData:(NSData *)data ran:(NSString *)ran{
    [[AWECloudCommandManager sharedInstance] executeCommandWithData:data ran:ran];
}

- (void)onPushManagerDidReceiveMessage:(NSNotification *)notification {
#if !RANGERSAPM
    if([self requestNeedBlocked]) return;
    
    id commandMsg = [notification.userInfo objectForKey:@"kTTPushManagerOnReceivingMessageUserInfoKey"];
    
    if (commandMsg && [commandMsg isKindOfClass:NSClassFromString(@"PushMessageBaseObject")]) {
        if ([commandMsg respondsToSelector:NSSelectorFromString(@"service")] && [commandMsg respondsToSelector:NSSelectorFromString(@"method")]) {
            NSNumber *commandService = [commandMsg valueForKey:@"service"];
            NSNumber *commandMethod = [commandMsg valueForKey:@"method"];
            if(commandService.intValue == self.serviceID && commandMethod.intValue == self.methodID) {
                if([commandMsg respondsToSelector:NSSelectorFromString(@"payload")] && [commandMsg respondsToSelector:NSSelectorFromString(@"headers")]) {
                    id headers = [commandMsg valueForKey:@"headers"];
                    if([headers isKindOfClass:[NSDictionary class]]){
                        NSString *ran = [headers objectForKey:@"ran"];
                        [self executeCommandWithData:[commandMsg valueForKey:@"payload"] ran:ran];
                    }
                    
                }
            }
        }
    } else {
        NSAssert(false, @"error object");
    }
#endif
}

- (void)setPushManagerBroadcastEnabled:(BOOL)isEnabled {
#if !RANGERSAPM
    Class clazz = NSClassFromString(@"TTPushManager");
    if (clazz == NULL) return;
    
    if (isEnabled) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onPushManagerDidReceiveMessage:)
                                                     name:@"kTTPushManagerOnReceivingMessage" object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"kTTPushManagerOnReceivingMessage" object:nil];
    }
#endif
}

/// 请求是否需要阻塞
- (BOOL)requestNeedBlocked {
    if([[HMDInjectedInfo defaultInfo].disableNetworkRequest boolValue]) return YES;
#if RANGERSAPM
    return NO;
#else
    HMDCloudCommandSetting *setting = Heimdallr.shared.config.apiSettings.cloudCommandSetting;
    if(setting != nil) return !setting.enableOpen;
    else return NO;
#endif
}

- (void)networkRequestEnableChanged {
    [self getCloudCommandIfAvailable];
}

- (void)getCloudCommandIfAvailable {
    if (self.isAutoPullEnabled && ![self requestNeedBlocked]) {
        self.isObserving = YES;
        hmd_safe_dispatch_async(self.serialQueue, ^{
            [[AWECloudCommandManager sharedInstance] getCloudControlCommandData];
        });
    } else {
        self.isObserving = NO;
    }
}

#pragma mark - HeimdallrLocalModule+ (id)getInstance;

+ (id)getInstance {
    return [self sharedInstance];
}

- (NSString *)moduleName {
    return kHMDModuleCloudCommand;
}

- (void)start {
    [self setupLongConnectChannelIfAvailable];
    [self setDiskComplianceHandler];
    self.isRunning = YES;
}

- (void)stop {
    [self closeLongConnetChannelIfAvailable];
    self.isRunning = NO;
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    [self getCloudCommandIfAvailable];
}

@end
