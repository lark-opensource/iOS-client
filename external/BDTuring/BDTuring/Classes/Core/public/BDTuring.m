//
//  BDTuring.m
//  BDTuring
//
//  Created by bob on 2019/8/23.
//

#import "BDTuring.h"
#import "BDTuring+Delegate.h"
#import "BDTuring+Notification.h"
#import "BDTuring+Preload.h"

#import "BDTuringVerifyModel+Result.h"
#import "BDTuringVerifyModel+Config.h"
#import "BDTuringVerifyModel+Creator.h"
#import "BDTuringVerifyModel+View.h"
#import "BDTuringConfig+Parameters.h"
#import "BDTuringVerifyResult.h"
#import "BDTuringVerifyState.h"
#import "BDTuringParameterVerifyModel.h"

#import "BDTuringMacro.h"
#import "BDTuringVerifyView+Piper.h"
#import "BDTuringVerifyView+Result.h"

#import "BDTuringVerifyConstant.h"
#import "BDTuringCoreConstant.h"
#import "BDTuringDeviceHelper.h"
#import "BDTuringUtility.h"

#import "NSDictionary+BDTuring.h"
#import "BDTuringUIHelper.h"
#import "BDTuringEventService.h"
#import "BDTuringServiceCenter.h"
#import "BDTuringService.h"
#import "BDTuringSettings.h"
#import "BDTuringSettingsKeys.h"
#import "BDTuringParameter.h"
#import "BDTuringVerifyResult.h"
#import "BDTuringParameterVerifyModel.h"
#import "BDTuringVerifyModel+Parameter.h"
#import "BDTNetworkManager.h"
#import "BDTuringEventConstant.h"

@interface BDTuring ()<BDTuringVerifyService>

@property (nonatomic, assign) BOOL isShowVerifyView;
@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *serviceName;
@property (nonatomic, strong) BDTuringConfig *config;
@property (nonatomic, strong) BDTuringVerifyView *verifyView;

@property (nonatomic, strong) BDTuringVerifyView *autoVerifyView;

@property (nonatomic, strong) BDTuringSettings *settings;

@property (nonatomic, assign) BOOL usePreload;
@property (nonatomic, assign) BOOL preloadVerifyViewReady;
@property (nonatomic, strong, nullable) BDTuringVerifyView *preloadVerifyView;
@property (nonatomic, strong) NSLock *callbackLock;
@property (nonatomic, copy) NSArray<NSString *> *skipPathList;

@end


@implementation BDTuring

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[BDTuringParameter sharedInstance] addCreator:[BDTuringParameterVerifyModel class]];
    });
}

+ (instancetype)turingWithAppID:(NSString *)appID {
    NSCAssert(appID != nil, @"appID should not be nil");
    NSString *serviceName = NSStringFromClass([BDTuringVerifyModel class]);
    BDTuring *turing = [[BDTuringServiceCenter defaultCenter] serviceForName:serviceName
                                                                       appID:appID];
    if (![turing isKindOfClass:[BDTuring class]]) {
        return nil;
    }
    
    return turing;
}

+ (instancetype)turingWithConfig:(BDTuringConfig *)config {
    BDTuring *turing = [self turingWithAppID:config.appID];
    if (turing == nil) {
        turing = [[self alloc] initWithConfig:config];
    }
    
    return turing;
}

- (instancetype)initWithConfig:(BDTuringConfig *)config {
    self = [super init];
    if (self) {
        self.callbackLock = [[NSLock alloc] init];
        self.serviceName = NSStringFromClass([BDTuringVerifyModel class]);
        long long startTime = turing_duration_ms(0);
        NSCAssert(config.appID, @"appID should not be nil");
        NSCAssert(config.appName, @"appName should not be nil");
        NSCAssert(config.channel, @"channel should not be nil");
        NSCAssert(config.language, @"language should not be nil");
        NSCAssert(config.delegate, @"delegate should not be nil");
        NSCAssert([config.delegate conformsToProtocol:@protocol(BDTuringConfigDelegate)], @"delegate should be  BDTuringConfigDelegate");
        
        self.adjustViewWhenKeyboardHiden = YES;
        self.verifyView = nil;
        NSString *appID = config.appID;
        self.config = config;
        self.appID = appID;
        
        self.usePreload = NO;
        self.preloadVerifyViewReady = NO;
        self.preloadVerifyView = nil;
                
        BDTuringEventService *eventService = [BDTuringEventService sharedInstance];
        eventService.config = config;
        
        [BDTNetworkManager sharedInstance];
        
        self.settings = [BDTuringSettings settingsForConfig:config];
        [self.settings checkAndFetchSettingsWithCompletion:nil];
        self.isShowVerifyView = NO;
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        
        [center addObserver:self
                   selector:@selector(onWillChangeStatusBarOrientation:)
                       name:UIApplicationWillChangeStatusBarOrientationNotification
                     object:nil];

        [center addObserver:self
                   selector:@selector(onDidEnterBackground)
                       name:UIApplicationDidEnterBackgroundNotification
                     object:nil];
        [center addObserver:self
                   selector:@selector(onWillEnterForeground)
                       name:UIApplicationWillEnterForegroundNotification
                     object:nil];
        
        self.delegate = nil;
        self.closeVerifyViewWhenTouchMask = YES;
        
        long long duration =turing_duration_ms(startTime);
        NSMutableDictionary *param = [NSMutableDictionary new];
        [param setValue:@(duration) forKey:kBDTuringDuration];
        [eventService collectEvent:BDTuringEventNameSDKSart data:param];
        
        [[BDTuringServiceCenter defaultCenter] registerService:self];
    }

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)closeVerifyView {
    if (!self.isShowVerifyView) {
        return;
    }
    self.isShowVerifyView = NO;
    BDTuringVerifyView *verifyView = self.verifyView;
    [verifyView handleCallbackStatus:BDTuringVerifyStatusCloseFromAPI];
    [self.verifyView closeVerifyView:@"app_close"];
    self.verifyView = nil;
}

- (void)setCloseVerifyViewWhenTouchMask:(BOOL)closeVerifyViewWhenTouchMask {
    [BDTuringUIHelper sharedInstance].shouldCloseFromMask = closeVerifyViewWhenTouchMask;
}

- (BOOL)closeVerifyViewWhenTouchMask {
    return [BDTuringUIHelper sharedInstance].shouldCloseFromMask;
}

- (void)popVerifyViewWithCallback:(BDTuringVerifyResultCallback)callback {
    NSDictionary *parameter = [[BDTuringParameter sharedInstance] currentParameter];
    if (parameter == nil) {
        if (callback) {
            callback([BDTuringVerifyResult okResult]);
        }
        
        return;
    }
    
    BDTuringVerifyModel *model = [[BDTuringParameter sharedInstance] modelWithParameter:parameter];
    model.appID = self.appID;
    model.callback = callback;
    [[BDTuringServiceCenter defaultCenter] popVerifyViewWithModel:model];
}

- (void)preloadVerifyViewWithModel:(BDTuringVerifyModel *)model {
    if (model == nil) {
        return;
    }
    
    if (self.preloadVerifyView != nil) {
        return;
    }

    if (@available(iOS 8.0, *)) {
        /// do nothing
    } else {
        [[BDTuringEventService sharedInstance] collectEvent:BDTuringEventNameSystemLow data:nil];
        [model handleResultStatus:BDTuringVerifySystemVersionLow];
        return;
    }
    
    if (!model.state.validated) {
        [model handleResultStatus:BDTuringVerifyStatusResponseError];
        return;
    }
    
    model.appID = self.config.appID;
    self.config.model = model;
    long long startTime = turing_duration_ms(0);
    BDTuringWeakSelf;
    [self.settings checkAndFetchSettingsWithCompletion:^{
        BDTuringStrongSelf;
        NSInteger preloadSettings = [[self.settings settingsForPlugin:kBDTuringSettingsPluginCommon
                                                                  key:kBDTuringSettingsPreload
                                                         defaultValue:@"0"] integerValue];
        if (preloadSettings == 1) {
            self.usePreload = YES;
        }
        if (self.usePreload) {
            [self startPreloadWithModel:model startTime:startTime];
        }
    }];
}


- (void)popVerifyViewWithModel:(BDTuringVerifyModel *)model {
    if(![model.handlerName isEqualToString:NSStringFromClass([BDTuringVerifyModel class])]) {
        model.appID = self.appID;
        [[BDTuringServiceCenter defaultCenter] popVerifyViewWithModel:model];
        return;
    }
    if (self.usePreload && self.preloadVerifyViewReady) {
        [self popPreloadVerifyView];
        return;
    }
    BDTuringEventService *eventService = [BDTuringEventService sharedInstance];
    if (@available(iOS 8.0, *)) {
        /// do nothing
    } else {
        [eventService collectEvent:BDTuringEventNameSystemLow data:nil];
        [model handleResultStatus:BDTuringVerifySystemVersionLow];
        return;
    }
    
    if (!model.state.validated) {
        [model handleResultStatus:BDTuringVerifyStatusResponseError];
        return;
    }
    
    if (self.isShowVerifyView) {
        [model handleResultStatus:BDTuringVerifyStatusConflict];
        return;
    }
    
    BDTuringConfig *config = self.config;
    model.appID = config.appID;
    config.model = model;
    [eventService collectEvent:BDTuringEventNamePop data:nil];
    if ([model isKindOfClass:NSClassFromString(@"BDAutoVerifyModel")]) {
        [self popAutoVerifyViewWithConfig:config model:model];
    } else {
        [self popTuringVerifyViewWithConfig:config model:model];
    }
}

- (void)popTuringVerifyViewWithConfig:(BDTuringConfig *)config model:(BDTuringVerifyModel *)model {

    long long startTime = turing_duration_ms(0);
    
    self.isShowVerifyView = YES;
    BDTuringWeakSelf;
    [self.settings checkAndFetchSettingsWithCompletion:^{
        BDTuringStrongSelf;
        [BDTuringUIHelper sharedInstance].supportLandscape = model.supportLandscape;
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        NSInteger orientationValue = (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) ? 2 : 1;
        NSDictionary *orientationParam = @{BDTuringEventParamResult : @(orientationValue)};
        [[BDTuringEventService sharedInstance] collectEvent:BDTuringEventNameOrientation data:orientationParam];
        BDTuringVerifyView *verifyView = [config.model createVerifyView];
        self.verifyView = verifyView;
        verifyView.model = model;
        verifyView.startLoadTime = startTime;
        verifyView.delegate = self;
        verifyView.config = config;
        verifyView.adjustViewWhenKeyboardHiden = self.adjustViewWhenKeyboardHiden;
        
        [model loadVerifyView:verifyView];
        if (!model.hideLoading) {
            [verifyView showVerifyView];
        }
    }];
}

- (void)popAutoVerifyViewWithConfig:(BDTuringConfig *)config model:(BDTuringVerifyModel *)model {
        long long startTime = turing_duration_ms(0);
        BDTuringVerifyView *verifyView = [model createVerifyView];
        self.autoVerifyView = verifyView;
        verifyView.model = model;
        BDTuringWeakSelf;
        [self.settings checkAndFetchSettingsWithCompletion:^{
            BDTuringStrongSelf;
            
            UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
            NSInteger orientationValue = (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) ? 2 : 1;
            NSDictionary *orientationParam = @{BDTuringEventParamResult : @(orientationValue)};
            [[BDTuringEventService sharedInstance] collectEvent:BDTuringEventNameOrientation data:orientationParam];
            verifyView.startLoadTime = startTime;
            verifyView.delegate = self;
            verifyView.config = config;
            verifyView.adjustViewWhenKeyboardHiden = self.adjustViewWhenKeyboardHiden;
        
            [model loadVerifyView:verifyView];
            [verifyView showVerifyView];
    }];
}

- (void)startPreloadWithModel:(BDTuringVerifyModel *)model startTime:(long long)startTime {
    BDTuringVerifyView *verifyView = [model createVerifyView];
    verifyView.model = model;
    verifyView.delegate = self;
    verifyView.config = self.config;
    verifyView.startPreloadTime = startTime;
    verifyView.adjustViewWhenKeyboardHiden = self.adjustViewWhenKeyboardHiden;
    verifyView.isPreloadVerifyView = YES;
    self.preloadVerifyView = verifyView;
    
    [model loadVerifyView:verifyView];
}

- (void)popPictureVerifyViewWithRegionType:(BDTuringRegionType)regionType
                             challengeCode:(NSInteger)challengeCode
                                  callback:(BDTuringVerifyCallback)callback {
    BDTuringVerifyModel *model = [BDTuringVerifyModel pictureModelWithCode:challengeCode];
    model.regionType = regionType;
    model.callback = ^(BDTuringVerifyResult *result) {
        if (callback) {
            callback(result.status, result.token, result.mobile);
        }
    };
    [self popVerifyViewWithModel:model];
}

- (void)popSMSVerifyViewWithRegionType:(BDTuringRegionType)regionType
                                 scene:(NSString *)scene
                              callback:(BDTuringVerifyCallback)callback {
    BDTuringVerifyModel *model = [BDTuringVerifyModel smsModelWithScene:scene];
    model.regionType = regionType;
    model.callback = ^(BDTuringVerifyResult *result) {
        if (callback) {
            callback(result.status, result.token, result.mobile);
        }
    };
    
    [self popVerifyViewWithModel:model];
}


#pragma mark - Class

+ (NSString *)sdkVersion {
    return [BDTuringSDKVersion mutableCopy];
}

@end
