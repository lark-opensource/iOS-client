//
//  BDDebugFeedTuring.m
//  BDStartUp
//
//  Created by bob on 2020/4/1.
//

#import "BDDebugFeedTuring.h"
#import "BDTuringConfig.h"
#import "BDTuringVerifyResult.h"
#import "BDTuringVerifyModel.h"
#import "BDTuringVerifyModel+Creator.h"
#import "BDTuringSlidePictureVerifyModel.h"
#import "BDTuringWhirlPictureVerifyModel.h"
#import "BDTuringSMSVerifyModel.h"
#import "BDTuringQAVerifyModel.h"
#import "BDTuringPictureVerifyModel.h"
#import "BDTuringParameterVerifyModel.h"
#import "BDTuringVerifyModel+Parameter.h"
#import  "BDDebugFeedTwiceVerify.h"

#import "BDTuringStartUpTask.h"
#import "BDTuringConfig+Debug.h"
#import "BDTuringSettings.h"
#import "BDTuring+InHouse.h"

#import "BDTuring+UserInterface.h"
#import "BDTuringVerifyView.h"
#import "BDTuringVerifyViewDefine.h"
#import "PreloadViewController.h"

#import <BDDebugTool/BDDebugFeedLoader.h>
#import <BDDebugTool/BDDebugSettingModel.h>
#import <BDDebugTool/BDDebugSettings.h>

#import <BDStartUp/BDApplicationInfo.h>
#import <BDStartUp/BDDebugStartUpTask.h>
#import <BDDebugTool/BDDebugTextResultViewController.h>
#import <BDDebugTool/UIViewController+BDDebugAlert.h>
#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import <BDUGAccountSDKInterface/BDUGAccountSDKInterface.h>

static NSString *const kBDTuringDebugCloseTouchMask     = @"kBDTuringDebugCloseTouchMask";

static NSString *const kBDTuringDebugPicURL = @"kBDTuringDebugPicURL";
static NSString *const kBDTuringDebugSMSRL  = @"kBDTuringDebugSMSRL";
static NSString *const kBDTuringDebugQAURL  = @"kBDTuringDebugQAURL";
static NSString *const kBDTuringDebugAutoVerifyURL = @"kBDTuringDebugSmartURL";
static NSString *const kBDTuringDebugFullAutoVerifyURL = @"kBDTuringDebugFullSmartURL";

static NSString *const kBDTuringUseDebugURL   = @"kBDTuringUseDebugURL";

static NSString *const kBDTuringForbidLandscape   = @"kBDTuringForbidLandscape";
static NSString *const kBDTuringCustomTheme       = @"kBDTuringCustomTheme";

static NSString *const kBDTuringDebugChannel = @"kBDTuringDebugChannel";
static NSString *const kBDTuringDebugAppName = @"kBDTuringDebugAppName";
static NSString *const kBDTuringDebugLanguage = @"kBDTuringDebugLanguage";
static NSString *const kBDTuringDebugDid   = @"kBDTuringDebugDid";
static NSString *const kBDTuringDebugUid   = @"kBDTuringDebugUid";
static NSString *const kBDTuringDebugIID   = @"kBDTuringDebugIID";
static NSString *const kBDTuringDebugRegion   = @"kBDTuringDebugRegion";

BDAppDebugSettingRegisterFunction () {
    BDDebugSettings *settings = [BDDebugSettings sharedInstance];
    [settings registerDefaultValue:@(YES) forKey:kBDTuringDebugCloseTouchMask];
    [settings registerDefaultValue:@(NO) forKey:kBDTuringUseDebugURL];
    
    [settings registerDefaultValue:BDTuringBOEURLPicture forKey:kBDTuringDebugPicURL];
    [settings registerDefaultValue:BDTuringBOEURLSMS forKey:kBDTuringDebugSMSRL];
    [settings registerDefaultValue:BDTuringBOEURLQA forKey:kBDTuringDebugQAURL];
    [settings registerDefaultValue:BDTuringBOEURLAutoVerify forKey:kBDTuringDebugAutoVerifyURL];
    [settings registerDefaultValue:BDTuringBOEURLFullAutoVerify forKey:kBDTuringDebugFullAutoVerifyURL];
    
    [settings setSettingValue:[BDTrackerProtocol deviceID] forKey:kBDTuringDebugDid];
    [settings setSettingValue:[BDTrackerProtocol installID] forKey:kBDTuringDebugIID];
    [settings setSettingValue:@"3456476787259367" forKey:kBDTuringDebugUid];
    
    BDApplicationInfo *info = [BDApplicationInfo sharedInstance];
    [settings registerDefaultValue:info.appName forKey:kBDTuringDebugAppName];
    [settings registerDefaultValue:info.channel forKey:kBDTuringDebugChannel];
    [settings registerDefaultValue:info.language forKey:kBDTuringDebugLanguage];
    [settings registerDefaultValue:@(BDTuringRegionTypeCN) forKey:kBDTuringDebugRegion];
}

BDAppAddDebugFeedFunction() {
    if (![BDTuringStartUpTask sharedInstance].enabled) {
        return;
    }
    [BDDebugFeedLoader addDebugFeed:[BDDebugFeedTuring sharedInstance]];
    [[BDDebugStartUpTask sharedInstance] addCheckBlock:^NSString * {
        if ([BDApplicationInfo sharedInstance].isI18NApp) {
            if ([BDTuringStartUpTask sharedInstance].config.regionType == BDTuringRegionTypeCN
                || [[BDApplicationInfo sharedInstance].language.lowercaseString hasPrefix:@"zh"]) {
                return @"BDTuring";
            }
        }
        
        return nil;
    }];
}

@interface BDDebugFeedTuring ()<BDTuringConfigDelegate>

@property (nonatomic, strong) BDTuringConfig *config;
@property (nonatomic, strong) BDTuring *turing;

@end

@implementation BDDebugFeedTuring

+ (instancetype)sharedInstance {
    static BDDebugFeedTuring *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = @"验证码BDTuring示例";
        self.navigateBlock = ^(BDDebugFeedModel *feed, UINavigationController *navigate) {
            BDDebugTextResultViewController *result = [BDDebugTextResultViewController new];
            result.title = @"BDTuring";
            result.feeds = [BDDebugFeedTuring feedsWithNavigate:navigate];
            
            [navigate pushViewController:result animated:YES];
        };
        
        [self turingInit];
    }
    
    return self;
}

- (void)turingInit {
    BDDebugSettings *settings = [BDDebugSettings sharedInstance];
    
    BDTuringConfig *config = [BDTuringStartUpTask sharedInstance].config;
    config.channel = [settings settingValueForKey:kBDTuringDebugChannel];
    config.delegate = self;
    config.language = [settings settingValueForKey:kBDTuringDebugLanguage];
    config.appName = [settings settingValueForKey:kBDTuringDebugAppName];
    config.regionType = [[settings settingValueForKey:kBDTuringDebugRegion] integerValue];
    config.locale = @"zh";
    self.config = config;
    self.turing = [BDTuringStartUpTask sharedInstance].turing;
    self.turing.closeVerifyViewWhenTouchMask = [[settings settingValueForKey:kBDTuringDebugCloseTouchMask] boolValue];
    BOOL on = [[settings settingValueForKey:kBDTuringUseDebugURL] boolValue];
    [self loadDebugURL:on];
    [self addTheme:[[settings settingValueForKey:kBDTuringCustomTheme] boolValue]];
    [BDTuring setForbidLandscape:[[settings settingValueForKey:kBDTuringForbidLandscape] boolValue]];
}

- (void)loadDebugURL:(BOOL)on {
    BDTuringConfig * config = self.config;
    if (on) {
        BDDebugSettings *settings = [BDDebugSettings sharedInstance];
        [config setPictureURL:[settings settingValueForKey:kBDTuringDebugPicURL]];
        [config setSMSURL:[settings settingValueForKey:kBDTuringDebugSMSRL]];
        [config setQAURL:[settings settingValueForKey:kBDTuringDebugQAURL]];
    } else {
        [config setPictureURL:nil];
        [config setSMSURL:nil];
        [config setQAURL:nil];
        [config setSealURL:nil];
    }
}

- (void)addTheme:(BOOL)custom {
    if (custom) {
        [BDTuring setQATheme:[BDTuring inhouseCustomValueForKey:@"qa_theme"]];
        [BDTuring setSMSTheme:[BDTuring inhouseCustomValueForKey:@"sms_theme"]];
        [BDTuring setVerifyTheme:[BDTuring inhouseCustomValueForKey:@"picture_theme"]];
        [BDTuring setQAText:[BDTuring inhouseCustomValueForKey:@"qa_text"]];
        [BDTuring setSMSText:[BDTuring inhouseCustomValueForKey:@"sms_text"]];
    } else {
        [BDTuring setQATheme:nil];
        [BDTuring setSMSTheme:nil];
        [BDTuring setVerifyTheme:nil];
        [BDTuring setQAText:nil];
        [BDTuring setSMSText:nil];
    }
}

- (void)updateSettings {
    [[BDTuringSettings settingsForAppID:self.config.appID] loadLocalSettings];
}

- (void)cleanSettings {
    [[BDTuringSettings settingsForAppID:self.config.appID] cleanSettings];
}

+ (NSArray<BDDebugSectionModel *> *)feedsWithNavigate:(UINavigationController *)navigate {
    NSMutableArray<BDDebugSectionModel *> *sections = [NSMutableArray new];
    
    BDTuringVerifyResultCallback callback = ^(BDTuringVerifyResult *result) {
        [navigate bdd_showAlertWithMessage:[NSString stringWithFormat:@"验证结果 status(%zd)", result.status]];
    };
    
    NSArray<BDDebugSectionModel *> *twiceVerifyFeed = [BDDebugFeedTuring sharedInstance].twiceVerifyFeed;
    if ([twiceVerifyFeed isKindOfClass:[NSArray class]]) {
        [sections addObjectsFromArray:twiceVerifyFeed];
    }
    
    [sections addObject:({
        BDDebugSectionModel *model = [BDDebugSectionModel new];
        model.title = @"开关设置";
        NSMutableArray<BDDebugFeedModel *> *feeds = [NSMutableArray new];
        
        [feeds addObject:({
            BDDebugSettingModel *setting = [BDDebugSettingModel new];
            setting.title = @"点击蒙层关闭验证码开关";
            setting.feedType = BDDebugFeedModelTypeSwitch;
            setting.settingKey = kBDTuringDebugCloseTouchMask;
            setting.switchBlock = ^(BDDebugFeedModel *feed, BOOL on) {
                [BDDebugFeedTuring sharedInstance].turing.closeVerifyViewWhenTouchMask = on;
            };
           setting;
        })];
        
        [feeds addObject:({
            BDDebugSettingModel *setting = [BDDebugSettingModel new];
            setting.title = @"禁止横屏开关";
            setting.feedType = BDDebugFeedModelTypeSwitch;
            setting.settingKey = kBDTuringForbidLandscape;
            setting.switchBlock = ^(BDDebugFeedModel *feed, BOOL on) {
                [BDTuring setForbidLandscape:on];
            };
           setting;
        })];
        
        [feeds addObject:({
            BDDebugFeedModel *setting = [BDDebugFeedModel new];
            setting.title = @"点击清空验证码本地配置";
            setting.navigateBlock = ^(BDDebugFeedModel *feed, UINavigationController *navigate) {
                [[BDDebugFeedTuring sharedInstance] cleanSettings];
            };
            setting;
        })];
        
        [feeds addObject:({
            BDDebugSettingModel *setting = [BDDebugSettingModel new];
            setting.title = @"设置地区 1:CN 2:SG 3:VA 4:IN";
            setting.feedType = BDDebugFeedModelTypeInput;
            setting.settingKey = kBDTuringDebugRegion;
            setting.inputBlock = ^(BDDebugFeedModel *feed, NSString *input) {
                [BDDebugFeedTuring sharedInstance].config.regionType = [input integerValue];
            };
           setting;
        })];
        

        [feeds addObject:({
            BDDebugSettingModel *setting = [BDDebugSettingModel new];
            setting.title = @"修改验证码语言";
            setting.feedType = BDDebugFeedModelTypeInput;
            setting.settingKey = kBDTuringDebugLanguage;
            setting.inputBlock = ^(BDDebugFeedModel *feed, NSString *input) {
                [BDDebugFeedTuring sharedInstance].config.language = input;
            };
           setting;
        })];
        
        [feeds addObject:({
            BDDebugSettingModel *setting = [BDDebugSettingModel new];
            setting.title = @"设置AppName";
            setting.feedType = BDDebugFeedModelTypeInput;
            setting.settingKey = kBDTuringDebugAppName;
            setting.inputBlock = ^(BDDebugFeedModel *feed, NSString *input) {
                [BDDebugFeedTuring sharedInstance].config.appName = input;
            };
           setting;
        })];
        
        [feeds addObject:({
            BDDebugSettingModel *setting = [BDDebugSettingModel new];
            setting.title = @"设置Channel";
            setting.feedType = BDDebugFeedModelTypeInput;
            setting.settingKey = kBDTuringDebugChannel;
            setting.inputBlock = ^(BDDebugFeedModel *feed, NSString *input) {
                [BDDebugFeedTuring sharedInstance].config.channel = input;
            };
           setting;
        })];
        
        [feeds addObject:({
            BDDebugSettingModel *setting = [BDDebugSettingModel new];
            setting.title = @"修改验证码测试did";
            setting.feedType = BDDebugFeedModelTypeInput;
            setting.settingKey = kBDTuringDebugDid;
            setting;
        })];
        
        [feeds addObject:({
            BDDebugSettingModel *setting = [BDDebugSettingModel new];
            setting.title = @"修改验证码测试uid";
            setting.feedType = BDDebugFeedModelTypeInput;
            setting.settingKey = kBDTuringDebugUid;
            setting;
        })];
        
        [feeds addObject:({
            BDDebugSettingModel *setting = [BDDebugSettingModel new];
            setting.title = @"使用测试URL";
            setting.feedType = BDDebugFeedModelTypeSwitch;
            setting.settingKey = kBDTuringUseDebugURL;
            setting.switchBlock = ^(BDDebugFeedModel *feed, BOOL on) {
                [[BDDebugFeedTuring sharedInstance] loadDebugURL:on];
                [[BDDebugFeedTuring sharedInstance] updateSettings];
            };
           setting;
        })];
        
        [feeds addObject:({
            BDDebugSettingModel *setting = [BDDebugSettingModel new];
            setting.title = @"修改图片验证码测试URL";
            setting.feedType = BDDebugFeedModelTypeInput;
            setting.settingKey = kBDTuringDebugPicURL;
            setting.inputBlock = ^(BDDebugFeedModel *feed, NSString *input) {
                [[BDDebugFeedTuring sharedInstance].config setPictureURL:input];
                [[BDDebugFeedTuring sharedInstance] updateSettings];
            };
            setting;
        })];
        
        [feeds addObject:({
            BDDebugSettingModel *setting = [BDDebugSettingModel new];
            setting.title = @"修改短信验证码测试URL";
            setting.feedType = BDDebugFeedModelTypeInput;
            setting.settingKey = kBDTuringDebugSMSRL;
            setting.inputBlock = ^(BDDebugFeedModel *feed, NSString *input) {
                [[BDDebugFeedTuring sharedInstance].config setSMSURL:input];
                [[BDDebugFeedTuring sharedInstance] updateSettings];
            };
            setting;
        })];
        
        [feeds addObject:({
            BDDebugSettingModel *setting = [BDDebugSettingModel new];
            setting.title = @"修改问答验证码测试URL";
            setting.feedType = BDDebugFeedModelTypeInput;
            setting.settingKey = kBDTuringDebugQAURL;
            setting.inputBlock = ^(BDDebugFeedModel *feed, NSString *input) {
                [[BDDebugFeedTuring sharedInstance].config setQAURL:input];
                [[BDDebugFeedTuring sharedInstance] updateSettings];
            };
            setting;
        })];
        
        [feeds addObject:({
            BDDebugSettingModel *setting = [BDDebugSettingModel new];
             setting.title = @"修改无感验证测试URL";
             setting.feedType = BDDebugFeedModelTypeInput;
             setting.settingKey = kBDTuringDebugAutoVerifyURL;
             setting.inputBlock = ^(BDDebugFeedModel *feed, NSString *input) {
                 [[BDDebugFeedTuring sharedInstance].config setAutoVerifyURL:input];
                 [[BDDebugFeedTuring sharedInstance] updateSettings];
             };
            setting;
        })];
        
        [feeds addObject:({
            BDDebugSettingModel *setting = [BDDebugSettingModel new];
             setting.title = @"修改完全无感验证测试URL";
             setting.feedType = BDDebugFeedModelTypeInput;
             setting.settingKey = kBDTuringDebugFullAutoVerifyURL;
             setting.inputBlock = ^(BDDebugFeedModel *feed, NSString *input) {
                 [[BDDebugFeedTuring sharedInstance].config setFullAutoVerifyURL:input];
                 [[BDDebugFeedTuring sharedInstance] updateSettings];
             };
            setting;
        })];
        
        model.feeds = feeds;
        model;
    })];
    
    

    [sections addObject:({
        BDDebugSectionModel *model = [BDDebugSectionModel new];
        model.title = @"自定义主题设置";
        NSMutableArray<BDDebugFeedModel *> *feeds = [NSMutableArray new];
        
        [feeds addObject:({
            BDDebugSettingModel *setting = [BDDebugSettingModel new];
            setting.title = @"加载自定义主题开关";
            setting.feedType = BDDebugFeedModelTypeSwitch;
            setting.settingKey = kBDTuringCustomTheme;
            setting.switchBlock = ^(BDDebugFeedModel *feed, BOOL on) {
                [[BDDebugFeedTuring sharedInstance] addTheme:on];
            };
           setting;
        })];
        
        model.feeds = feeds;
        model;
    })];
    
    [sections addObject:({
        BDDebugSectionModel *model = [BDDebugSectionModel new];
        model.title = @"预加载相关";
        NSMutableArray<BDDebugFeedModel *> *feeds = [NSMutableArray new];
        
        [feeds addObject:({
            BDDebugFeedModel *model = [BDDebugFeedModel new];
            model.title = @"预加载测试";
            model.navigateBlock = ^(BDDebugFeedModel *feed, UINavigationController *navigate) {
                PreloadViewController *vc = [PreloadViewController new];
                [navigate pushViewController:vc animated:YES];
            };
            model;
        })];
        model.feeds = feeds;
        model;
    })];
    
    
    
    [sections addObject:({
        BDDebugSectionModel *model = [BDDebugSectionModel new];
        model.title = @"旧版本接口示例";
        NSMutableArray<BDDebugFeedModel *> *feeds = [NSMutableArray new];
        
        [feeds addObject:({
            BDDebugFeedModel *model = [BDDebugFeedModel new];
            model.title = @"加载图片 滑块验证码";
            model.navigateBlock = ^(BDDebugFeedModel *feed, UINavigationController *navigate) {
                BDTuringVerifyModel *model = [BDTuringVerifyModel pictureModelWithCode:3058];
                model.regionType = [BDDebugFeedTuring sharedInstance].config.regionType;
                model.callback = callback;
                [[BDDebugFeedTuring sharedInstance].turing popVerifyViewWithModel:model];
            };
           model;
        })];
        
        [feeds addObject:({
            BDDebugFeedModel *model = [BDDebugFeedModel new];
            model.title = @"加载图片 文字点选验证码";
            model.navigateBlock = ^(BDDebugFeedModel *feed, UINavigationController *navigate) {
                BDTuringVerifyModel *model = [BDTuringVerifyModel pictureModelWithCode:3059];
                model.regionType = [BDDebugFeedTuring sharedInstance].config.regionType;
                model.callback = callback;
                [[BDDebugFeedTuring sharedInstance].turing popVerifyViewWithModel:model];
            };
           model;
        })];
        
        [feeds addObject:({
            BDDebugFeedModel *model = [BDDebugFeedModel new];
            model.title = @"加载图片 3D点选验证码";
            model.navigateBlock = ^(BDDebugFeedModel *feed, UINavigationController *navigate) {
                BDTuringVerifyModel *model = [BDTuringVerifyModel pictureModelWithCode:3060];
                model.regionType = [BDDebugFeedTuring sharedInstance].config.regionType;
                model.callback = callback;
                [[BDDebugFeedTuring sharedInstance].turing popVerifyViewWithModel:model];
            };
           model;
        })];
        
        [feeds addObject:({
            BDDebugFeedModel *model = [BDDebugFeedModel new];
            model.title = @"加载问答验证码";
            model.navigateBlock = ^(BDDebugFeedModel *feed, UINavigationController *navigate) {
                BDTuringVerifyModel *model = [BDTuringQAVerifyModel new];
                model.regionType = [BDDebugFeedTuring sharedInstance].config.regionType;
                model.callback = callback;
                [[BDDebugFeedTuring sharedInstance].turing popVerifyViewWithModel:model];
            };
           model;
        })];
        
        [feeds addObject:({
            BDDebugFeedModel *model = [BDDebugFeedModel new];
            model.title = @"加载弹窗问答验证码";
            model.navigateBlock = ^(BDDebugFeedModel *feed, UINavigationController *navigate) {
                BDTuringQAVerifyModel *model = [BDTuringQAVerifyModel new];
                model.pop = YES;
                model.regionType = [BDDebugFeedTuring sharedInstance].config.regionType;
                model.callback = callback;
                [[BDDebugFeedTuring sharedInstance].turing popVerifyViewWithModel:model];
            };
           model;
        })];
        
        model.feeds = feeds;
        model;
    })];
    
    NSArray<BDDebugSectionModel *> *lynxFeed = [BDDebugFeedTuring sharedInstance].lynxFeed;
    if ([lynxFeed isKindOfClass:[NSArray class]]) {
        [sections addObjectsFromArray:lynxFeed];
    }
    
    NSArray<BDDebugSectionModel *> *h5bridgeFeed = [BDDebugFeedTuring sharedInstance].h5bridgeFeed;
    if ([h5bridgeFeed isKindOfClass:[NSArray class]]) {
        [sections addObjectsFromArray:h5bridgeFeed];
    }
    
    NSArray<BDDebugSectionModel *> *autoverifyFeed = [BDDebugFeedTuring sharedInstance].autoverifyFeed;
    if ([autoverifyFeed isKindOfClass:[NSArray class]]) {
        [sections addObjectsFromArray:autoverifyFeed];
    }
    
    NSArray<BDDebugSectionModel *> *identityFeed = [BDDebugFeedTuring sharedInstance].identityFeed;
    if ([identityFeed isKindOfClass:[NSArray class]]) {
        [sections addObjectsFromArray:identityFeed];
    }
    
    NSArray<BDDebugSectionModel *> *sealFeed = [BDDebugFeedTuring sharedInstance].sealFeed;
    if ([sealFeed isKindOfClass:[NSArray class]]) {
        [sections addObjectsFromArray:sealFeed];
    }
    
    NSArray<BDDebugSectionModel *> *themeFeed = [BDDebugFeedTuring sharedInstance].themeFeed;
    if ([themeFeed isKindOfClass:[NSArray class]]) {
        [sections addObjectsFromArray:themeFeed];
    }
    
    NSArray<BDDebugSectionModel *> *parameterFeed = [BDDebugFeedTuring sharedInstance].parameterFeed;
    if ([parameterFeed isKindOfClass:[NSArray class]]) {
        [sections addObjectsFromArray:parameterFeed];
    }
    
    
    return sections;
}

- (NSString *)deviceID {
    return [[BDDebugSettings sharedInstance] settingValueForKey:kBDTuringDebugDid];
}

- (NSString *)installID {
    return [[BDDebugSettings sharedInstance] settingValueForKey:kBDTuringDebugIID];
}

- (NSString *)userID {
    return [[BDDebugSettings sharedInstance] settingValueForKey:kBDTuringDebugUid];
}

- (NSString *)sessionID {
    return nil;
}

- (NSString *)secUserID {
    return nil;
}

@end
