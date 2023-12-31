//
//  BDDebugFeedSeal.m
//  BDTuring
//
//  Created by bob on 2020/6/2.
//

#import "BDDebugFeedSeal.h"
#import "BDDebugFeedTuring.h"
#import "BDTuring+Private.h"
#import "BDTuring+InHouse.h"
#import "BDTuringConfig.h"
#import "BDTuringConfig+Debug.h"
#import "BDAccountSealer.h"
#import "BDDebugSealNavigatePage.h"
#import "BDAccountSealer+Theme.h"

#import "BDAccountSealModel.h"
#import "BDAccountSealResult.h"

#import <BDDebugTool/UIViewController+BDDebugAlert.h>
#import <BDDebugTool/BDDebugSettingModel.h>
#import <BDDebugTool/BDDebugSettings.h>

static NSString *const kBDTuringBOESealHost     = @"kBDTuringBOESealHost";
static NSString *const kDebugSealURL        = @"kDebugSealURL";
static NSString *const kDebugSealTheme        = @"kDebugSealTheme";

BDAppDebugSettingRegisterFunction () {
    BDDebugSettings *settings = [BDDebugSettings sharedInstance];
    [settings setSettingValue:BDTuringBOEURLSeal forKey:kDebugSealURL];
}

@interface BDDebugFeedSeal ()

@property (nonatomic, strong) BDAccountSealer *sealer;

+ (NSArray<BDDebugSectionModel *> *)feeds;

@end

BDAppAddDebugFeedFunction() {
    [BDDebugFeedSeal sharedInstance];
    [BDDebugFeedTuring sharedInstance].sealFeed = [BDDebugFeedSeal feeds];
    [[BDDebugFeedTuring sharedInstance] updateSettings];
}

@implementation BDDebugFeedSeal

+ (instancetype)sharedInstance {
    static BDDebugFeedSeal *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[BDDebugFeedTuring sharedInstance].config setSealURL:BDTuringBOEURLSeal];
        self.sealer = [[BDAccountSealer alloc] initWithConfig:[BDDebugFeedTuring sharedInstance].config];
        BDDebugSettings *settings = [BDDebugSettings sharedInstance];
        [self addTheme:[[settings settingValueForKey:kDebugSealTheme] boolValue]];
    }
    
    return self;
}

- (void)addTheme:(BOOL)custom {
    if (custom) {
        [BDAccountSealer setCustomTheme:[BDTuring inhouseCustomValueForKey:@"seal_theme"]];
        [BDAccountSealer setCustomText:[BDTuring inhouseCustomValueForKey:@"seal_text"]];
    } else {
        [BDAccountSealer setCustomTheme:nil];
        [BDAccountSealer setCustomText:nil];
    }
}

+ (NSArray<BDDebugSectionModel *> *)feeds {
    NSMutableArray<BDDebugSectionModel *> *sections = [NSMutableArray new];
    
    [sections addObject:({
        BDDebugSectionModel *model = [BDDebugSectionModel new];
        model.title = @"自助解封示例";
        NSMutableArray<BDDebugFeedModel *> *feeds = [NSMutableArray new];
        
        [feeds addObject:({
            BDDebugSettingModel *setting = [BDDebugSettingModel new];
            setting.title = @"修改自助解封测试URL";
            setting.feedType = BDDebugFeedModelTypeInput;
            setting.settingKey = kDebugSealURL;
            setting.inputBlock = ^(BDDebugFeedModel *feed, NSString *input) {
                [[BDDebugFeedTuring sharedInstance].config setSealURL:input];
                [[BDDebugFeedTuring sharedInstance] updateSettings];
            };
            setting;
        })];
        
        [feeds addObject:({
            BDDebugSettingModel *setting = [BDDebugSettingModel new];
            setting.title = @"加载自定义主题开关";
            setting.feedType = BDDebugFeedModelTypeSwitch;
            setting.settingKey = kDebugSealTheme;
            setting.switchBlock = ^(BDDebugFeedModel *feed, BOOL on) {
                [[BDDebugFeedSeal sharedInstance] addTheme:on];
            };
           setting;
        })];
        
        
        [feeds addObject:({
            BDDebugFeedModel *model = [BDDebugFeedModel new];
             model.title = @"自助解封";
             model.navigateBlock = ^(BDDebugFeedModel *feed, UINavigationController *navigate) {
                 BDTuringVerifyResultCallback callback = ^(BDTuringVerifyResult *response) {
                     BDAccountSealResult *result = (BDAccountSealResult *)response;
                     [navigate bdd_showAlertWithMessage:[NSString stringWithFormat:@"自助解封结果Code(%zd)", result.resultCode]];
                 } ;
                 
                 BDAccountSealModel *model = [BDAccountSealModel new];
                 model.regionType = [BDDebugFeedTuring sharedInstance].turing.config.regionType;
                 model.callback = callback;
                 model.navigate = ^(BDAccountSealNavigatePage page, NSString *pageType, UINavigationController * navigationController) {
                        BDDebugSealNavigatePage *vc = [BDDebugSealNavigatePage new];
                        vc.title = page == BDAccountSealNavigatePagePolicy ? @"用户协议" : @"社区规范";
                        [navigationController pushViewController:vc animated:YES];
                 };
                 [[BDDebugFeedSeal sharedInstance].sealer popVerifyViewWithModel:model];
             };
            model;
        })];
        
        model.feeds = feeds;
        model;
    })];
    
    return sections;
}

@end
