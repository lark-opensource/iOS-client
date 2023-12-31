//
//  IESGurdSettingsManager.m
//  IESGeckoKit
//
//  Created by liuhaitian on 2021/4/19.
//

#import "IESGurdSettingsManager.h"

#import "IESGeckoKit.h"
#import "IESGeckoDefines.h"
#import "IESGurdSettingsRequest.h"
#import "IESGurdResourceManager+Settings.h"
#import "IESGurdSettingsCacheManager.h"
#import "IESGurdAutoRequestManager.h"
#import "IESGurdAppLogger.h"
#import "IESGurdPackagesExtraManager.h"
#import "IESGurdDiskUsageManager.h"

static BOOL kIESGurdKitSettingsCacheLoaded = NO;

@interface IESGurdSettingsManager ()

@property (nonatomic, strong, readwrite) IESGurdSettingsResponse *settingsResponse;

@property (nonatomic, assign, getter=isPollingEnabled) BOOL pollingEnabled;

@property (nonatomic, assign) NSInteger pollingInterval;

@property (nonatomic, strong) NSTimer *pollingRequestTimer;

@property (nonatomic, strong) NSDate *date;

@end

@implementation IESGurdSettingsManager

#pragma mark - Public

+ (instancetype)sharedInstance {
    static IESGurdSettingsManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    if (!kIESGurdKitSettingsCacheLoaded) {
        if ([IESGurdKit didSetup]) {
            // setup之前是获取不到缓存的，因为cachedSettingsResponse需要检查版本号
            // 宿主可能会在setup之前调[IESGurdKit setEnable]，然后就会调到这里来
            kIESGurdKitSettingsCacheLoaded = YES;
            instance.settingsResponse = [[IESGurdSettingsCacheManager sharedManager] cachedSettingsResponse];
        }
    }
    return instance;
}

- (void)fetchSettingsWithRequestType:(IESGurdSettingsRequestType)requestType
{
    NSAssert([IESGurdKit didSetup], @"should setupWithAppId before fetch settings");
    
    IESGurdSettingsRequest *request = [IESGurdSettingsRequest request];
    request.version = self.settingsResponse.version;
    request.requestType = requestType;
    
    __weak IESGurdSettingsManager *weakSelf = self;
    [IESGurdResourceManager fetchSettingsWithRequest:request completion:^(IESGurdSettingsStatus settingsStatus, IESGurdSettingsResponse *response, IESGurdSettingsResponseExtra *extra) {
        weakSelf.extra = extra;
        
        if (settingsStatus == IESGurdSettingsStatusDidUpdate) {
            weakSelf.settingsResponse = response;
        } else if (settingsStatus == IESGurdSettingsStatusUnavailable) {
            response = weakSelf.settingsResponse;
            // 服务不可用，停止轮询
            response.settingsConfig = [[IESGurdSettingsConfig alloc] init];
        } else {
            response = weakSelf.settingsResponse;
        }
        
        [weakSelf handleSettingsResponse:response];
        
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        userInfo[IESGurdSettingsFetchStatusKey] = @(settingsStatus);
        userInfo[IESGurdSettingsFetchResponseKey] = response;
        [[NSNotificationCenter defaultCenter] postNotificationName:IESGurdSettingsDidFetchNotification
                                                            object:nil
                                                          userInfo:userInfo];
        
        if (requestType == IESGurdSettingsRequestTypeNormal) {
            [[IESGurdPackagesExtraManager sharedManager] setup];
            [self uploadSettingsVersion];
            [[IESGurdDiskUsageManager sharedInstance] recordUsageIfNeeded];
        }
    }];
}

- (void)uploadSettingsVersion
{
    // 每天上报一次
    if (!self.date) {
        self.date = [[NSUserDefaults standardUserDefaults] objectForKey:@"gecko_upload_settings_version"] ?: [NSDate dateWithTimeIntervalSinceNow:-(24*60*60)];
    }
    NSDate *currentDate = [NSDate date];
    BOOL isSameDay = [[NSCalendar currentCalendar] isDate:currentDate inSameDayAsDate:self.date];
    if (isSameDay) {
        return;
    }
    self.date = currentDate;
    [[NSUserDefaults standardUserDefaults] setObject:currentDate forKey:@"gecko_upload_settings_version"];
    
    [IESGurdAppLogger recordEventWithType:IESGurdAppLogEventTypeSettings
                                  subtype:IESGurdAppLogEventSubtypeSettingsVersion
                                   params:nil
                                extraInfo:[NSString stringWithFormat:@"%ld", self.settingsResponse.version]
                             errorMessage:nil];
}

- (void)cleanCache
{
    [[IESGurdSettingsCacheManager sharedManager] cleanCache];
    self.settingsResponse = nil;
}

#pragma mark - Private

- (void)fetchSettingsPollingHandler
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self fetchSettingsWithRequestType:IESGurdSettingsRequestTypePolling];
    });
}

- (void)handleSettingsResponse:(IESGurdSettingsResponse *)response
{
    if (response.settingsConfig) {
        [self handleSettingsConfig:response.settingsConfig];
    }
    
    if (response.requestMeta) {
        [[IESGurdAutoRequestManager sharedManager] handleRequestMeta:response.requestMeta];
    }
}

- (void)handleSettingsConfig:(IESGurdSettingsConfig *)settingsConfig
{
    self.pollingEnabled = settingsConfig.pollingEnabled;
    self.pollingInterval = settingsConfig.pollingInterval;
    [self setupTimerIfNeeded];
}

- (void)setupTimerIfNeeded
{
    NSInteger pollingInterval = self.pollingInterval;
    if (!self.isPollingEnabled || pollingInterval == 0) {
        // 关闭轮询 timer
        [self.pollingRequestTimer invalidate];
        self.pollingRequestTimer = nil;
        return;
    }
    
    if (self.pollingRequestTimer.timeInterval == pollingInterval) {
        // 轮询间隔不变，无需修改 timer
        return;
    }
    
    [self.pollingRequestTimer invalidate];
    self.pollingRequestTimer = [NSTimer timerWithTimeInterval:pollingInterval
                                                       target:self
                                                     selector:@selector(fetchSettingsPollingHandler)
                                                     userInfo:nil
                                                      repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.pollingRequestTimer forMode:NSRunLoopCommonModes];
}

@end
