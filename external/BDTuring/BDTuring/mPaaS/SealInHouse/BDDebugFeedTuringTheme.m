//
//  BDDebugFeedTuringTheme.m
//  BDTuring
//
//  Created by bob on 2020/7/14.
//

#import "BDDebugFeedTuringTheme.h"
#import "BDTuring+UserInterface.h"
#import "BDAccountSealer+Theme.h"
#import "BDDebugFeedTuring.h"
#import <BDDebugTool/BDDebugSettingModel.h>
#import <BDDebugTool/BDDebugSettings.h>

static NSString *const kDebugTheme        = @"BDDebugFeedTuringTheme";

BDAppDebugSettingRegisterFunction () {
    BDDebugSettings *settings = [BDDebugSettings sharedInstance];
    [settings setSettingValue:@(NO) forKey:kDebugTheme];
}


@interface BDDebugFeedTuringTheme ()

@property (nonatomic, strong) NSMutableDictionary *theme;
@property (nonatomic, copy) NSString *themeKey;
@property (nonatomic, copy) NSString *themeValue;

@property (nonatomic, strong) NSMutableDictionary *smsText;
@property (nonatomic, copy) NSString *smsTextKey;
@property (nonatomic, copy) NSString *smsTextValue;

@property (nonatomic, strong) NSMutableDictionary *qaText;
@property (nonatomic, copy) NSString *qaTextKey;
@property (nonatomic, copy) NSString *qaTextValue;

@property (nonatomic, strong) NSMutableDictionary *sealTheme;
@property (nonatomic, copy) NSString *sealThemeKey;
@property (nonatomic, copy) NSString *sealThemeValue;

@property (nonatomic, strong) NSMutableDictionary *sealText;
@property (nonatomic, copy) NSString *sealTextKey;
@property (nonatomic, copy) NSString *sealTextValue;
+ (NSArray<BDDebugSectionModel *> *)feeds;

@end

BDAppAddDebugFeedFunction() {
    [BDDebugFeedTuring sharedInstance].themeFeed = [BDDebugFeedTuringTheme feeds];
}

@implementation BDDebugFeedTuringTheme

+ (instancetype)sharedInstance {
    static BDDebugFeedTuringTheme *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        self.themeKey = @"titleColor";
        self.themeValue = @"#222";
        self.smsTextKey = @"title";
        self.smsTextValue = @"123";
        self.qaTextKey = @"title";
        self.qaTextValue = @"456";
        self.sealThemeKey = @"appBgColor";
        self.sealThemeValue = @"#FFFFFF";
        self.sealTextKey = @"appTitle";
        self.sealTextValue = @"自定义自助解封标题";
        [self clearTheme];
    }
    
    return self;
}

- (void)clearTheme {
    self.theme = [NSMutableDictionary new];
    self.smsText = [NSMutableDictionary new];
    self.qaText = [NSMutableDictionary new];
    self.sealTheme = [NSMutableDictionary new];
    self.sealText = [NSMutableDictionary new];
}

- (void)addTheme:(BOOL)on {
    if (on) {
        [self.theme setValue:self.themeValue forKey:self.themeKey];
        [BDTuring setVerifyTheme:self.theme.copy];
        [BDTuring setSMSTheme:self.theme.copy];
        [BDTuring setQATheme:self.theme.copy];
        [self.qaText setValue:self.qaTextValue forKey:self.qaTextKey];
        [BDTuring setQAText:self.qaText.copy];
        [self.smsText setValue:self.smsTextValue forKey:self.smsTextKey];
        [BDTuring setSMSText:self.smsText.copy];
        [self.sealTheme setValue:self.sealThemeValue forKey:self.sealThemeKey];
        [self.sealText setValue:self.sealTextValue forKey:self.sealTextKey];
        [BDAccountSealer setCustomText:self.sealText.copy];
        [BDAccountSealer setCustomTheme:self.sealTheme.copy];
    } else {
        [BDTuring setVerifyTheme:nil];
        [BDTuring setSMSTheme:nil];
        [BDTuring setQATheme:nil];
        [BDTuring setQAText:nil];
        [BDTuring setSMSText:nil];
        [BDAccountSealer setCustomText:nil];
        [BDAccountSealer setCustomTheme:nil];
    }
}

+ (NSArray<BDDebugSectionModel *> *)feeds {
    NSMutableArray<BDDebugSectionModel *> *sections = [NSMutableArray new];
    
    [sections addObject:({
        BDDebugSectionModel *model = [BDDebugSectionModel new];
        model.title = @"单独自定义主题KV设置";
        NSMutableArray<BDDebugFeedModel *> *feeds = [NSMutableArray new];
        
        [feeds addObject:({
            BDDebugSettingModel *setting = [BDDebugSettingModel new];
            setting.title = @"开关（输入完成后回车，再切开关）";
            setting.feedType = BDDebugFeedModelTypeSwitch;
            setting.settingKey = kDebugTheme;
            setting.switchBlock = ^(BDDebugFeedModel *feed, BOOL on) {
                [[BDDebugFeedTuringTheme sharedInstance] addTheme:on];
            };
           setting;
        })];
        
        [feeds addObject:({
            BDDebugFeedModel *setting = [BDDebugFeedModel new];
            setting.title = @"清空所有自定义设置";
            setting.navigateBlock = ^(BDDebugFeedModel *feed, UINavigationController *navigate) {
                [[BDDebugFeedTuringTheme sharedInstance] addTheme:NO];
                [[BDDebugFeedTuringTheme sharedInstance] clearTheme];
            };
           setting;
        })];
        
        [feeds addObject:({
            BDDebugFeedModel *setting = [BDDebugFeedModel new];
            setting.title = @"验证码主题key";
            setting.feedType = BDDebugFeedModelTypeInput;
            setting.state = @"titleColor";
            setting.inputBlock = ^(BDDebugFeedModel *feed, NSString *input) {
                [BDDebugFeedTuringTheme sharedInstance].themeKey = input;
            };
            setting;
        })];
        
        [feeds addObject:({
            BDDebugFeedModel *setting = [BDDebugFeedModel new];
            setting.title = @"验证码主题value";
            setting.feedType = BDDebugFeedModelTypeInput;
            setting.state = @"#222";
            setting.inputBlock = ^(BDDebugFeedModel *feed, NSString *input) {
                [BDDebugFeedTuringTheme sharedInstance].themeValue = input;
            };
            setting;
        })];
        
        [feeds addObject:({
            BDDebugFeedModel *setting = [BDDebugFeedModel new];
            setting.title = @"短信文案key";
            setting.feedType = BDDebugFeedModelTypeInput;
            setting.state = @"title";
            setting.inputBlock = ^(BDDebugFeedModel *feed, NSString *input) {
                [BDDebugFeedTuringTheme sharedInstance].smsTextKey = input;
            };
            setting;
        })];

        
        [feeds addObject:({
            BDDebugFeedModel *setting = [BDDebugFeedModel new];
            setting.title = @"短信文案Value";
            setting.feedType = BDDebugFeedModelTypeInput;
            setting.state = @"title";
            setting.inputBlock = ^(BDDebugFeedModel *feed, NSString *input) {
                [BDDebugFeedTuringTheme sharedInstance].smsTextValue = input;
            };
            setting;
        })];

        [feeds addObject:({
            BDDebugFeedModel *setting = [BDDebugFeedModel new];
            setting.title = @"问答文案key";
            setting.feedType = BDDebugFeedModelTypeInput;
            setting.state = @"title";
            setting.inputBlock = ^(BDDebugFeedModel *feed, NSString *input) {
                [BDDebugFeedTuringTheme sharedInstance].qaTextKey = input;
            };
            setting;
        })];

        
        [feeds addObject:({
            BDDebugFeedModel *setting = [BDDebugFeedModel new];
            setting.title = @"问答文案Value";
            setting.feedType = BDDebugFeedModelTypeInput;
            setting.state = @"title";
            setting.inputBlock = ^(BDDebugFeedModel *feed, NSString *input) {
                [BDDebugFeedTuringTheme sharedInstance].qaTextValue = input;
            };
            setting;
        })];
        
        [feeds addObject:({
            BDDebugFeedModel *setting = [BDDebugFeedModel new];
            setting.title = @"自助解封主题key";
            setting.feedType = BDDebugFeedModelTypeInput;
            setting.state = @"appBgColor";
            setting.inputBlock = ^(BDDebugFeedModel *feed, NSString *input) {
                [BDDebugFeedTuringTheme sharedInstance].sealThemeKey = input;
            };
            setting;
        })];
        
        [feeds addObject:({
            BDDebugFeedModel *setting = [BDDebugFeedModel new];
            setting.title = @"自助解封主题value";
            setting.state = @"#FFFFFF";
            setting.feedType = BDDebugFeedModelTypeInput;
            setting.inputBlock = ^(BDDebugFeedModel *feed, NSString *input) {
                [BDDebugFeedTuringTheme sharedInstance].sealThemeValue = input;
            };
            setting;
        })];
        
        [feeds addObject:({
            BDDebugFeedModel *setting = [BDDebugFeedModel new];
            setting.title = @"自助解封文案key";
            setting.feedType = BDDebugFeedModelTypeInput;
            setting.state = @"appTitle";
            setting.inputBlock = ^(BDDebugFeedModel *feed, NSString *input) {
                [BDDebugFeedTuringTheme sharedInstance].sealTextKey = input;
            };
            setting;
        })];
        
        [feeds addObject:({
            BDDebugFeedModel *setting = [BDDebugFeedModel new];
            setting.title = @"自助解封文案value";
            setting.state = @"自定义自助解封标题";
            setting.feedType = BDDebugFeedModelTypeInput;
            setting.inputBlock = ^(BDDebugFeedModel *feed, NSString *input) {
                [BDDebugFeedTuringTheme sharedInstance].sealTextValue = input;
            };
            setting;
        })];

        
        model.feeds = feeds;
        model;
    })];
    
    return sections;
}

@end
