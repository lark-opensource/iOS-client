//
//  BDTuringPictureVerifyModel.m
//  BDTuring
//
//  Created by bob on 2020/7/13.
//

#import "BDTuringPictureVerifyModel.h"
#import "BDTuringVerifyModel+Config.h"
#import "BDTuringVerifyModel+View.h"

#import "BDTuringCoreConstant.h"
#import "BDTuringVerifyState.h"
#import "BDTuringSettingsKeys.h"
#import "BDTuringVerifyViewDefine.h"
#import "BDTuringPictureVerifyView.h"
#import "BDTuringSettings.h"
#import "UIColor+TuringHex.h"
#import "BDTuringUIHelper.h"
#import "BDTuringMacro.h"
#import "BDTuringConfig.h"

@interface BDTuringPictureVerifyModel ()

@property (nonatomic, assign) NSInteger challengeCode;

@end

@implementation BDTuringPictureVerifyModel

- (instancetype)init {
    self = [super init];
    if (self) {
        self.supportLandscape = YES;
        self.plugin = kBDTuringSettingsPluginPicture;
        self.verifyType = BDTuringVerifyTypePicture;
        self.challengeCode = -1;
        self.defaultWidth = 300;
        self.defaultHeight = 303;
        [self createState];
    }
    
    return self;
}

+ (instancetype)modelWithCode:(NSInteger)challengeCode {
    BDTuringPictureVerifyModel *result = [self new];
    result.challengeCode = challengeCode;
    
    return result;
}

- (void)appendKVToQueryParameters:(NSMutableDictionary *)paramters {
    [super appendKVToQueryParameters:paramters];
    NSInteger challengeCode = self.challengeCode;
    if (challengeCode > 0) {
        [paramters setValue:@(challengeCode) forKey:kBDTuringChallengeCode];
    }
}

- (void)appendKVToEventParameters:(NSMutableDictionary *)paramters {
    [super appendKVToQueryParameters:paramters];
    NSInteger challengeCode = self.challengeCode;
    if (challengeCode > 0) {
        [paramters setValue:@(challengeCode) forKey:kBDTuringChallengeCode];
    }
}

- (BDTuringVerifyView *)createVerifyView {
    CGRect bounds = [UIScreen mainScreen].bounds;
    return [[BDTuringPictureVerifyView alloc] initWithFrame:bounds];
}

- (void)configVerifyView:(BDTuringVerifyView *)verifyView {
    [super configVerifyView:verifyView];
    BDTuringSettings *settings = [BDTuringSettings settingsForAppID:self.appID];
    NSString *plugin = self.plugin;
    NSString *maskRGB = [settings settingsForPlugin:kBDTuringSettingsPluginCommon
                                                key:kBDTuringSettingsRGB
                                       defaultValue:@"000000"];
    CGFloat maskAlpha = [[settings settingsForPlugin:kBDTuringSettingsPluginCommon
                                                 key:kBDTuringSettingsAlpha
                                        defaultValue:@(0.5)] doubleValue];
    CGFloat width = [[settings settingsForPlugin:plugin
                                             key:kBDTuringSettingsWidth
                                    defaultValue:@(self.defaultWidth)] doubleValue];
    width = MAX(width, self.defaultWidth);
    CGFloat height = [[settings settingsForPlugin:plugin
                                              key:kBDTuringSettingsHeight
                                     defaultValue:@(self.defaultHeight)] doubleValue];
    height = MAX(height, self.defaultHeight);
    
    verifyView.backgroundColor = [UIColor turing_colorWithRGBString:maskRGB alpha:maskAlpha];
    /// set default size
    verifyView.webView.frame = CGRectMake(0, 0, width, height);
    verifyView.webView.center = [verifyView subViewCenter];
}

@end
