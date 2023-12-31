//
//  BDTuringQAVerifyModel.m
//  BDTuring
//
//  Created by bob on 2020/7/13.
//

#import "BDTuringQAVerifyModel.h"
#import "BDTuringVerifyModel+Config.h"
#import "BDTuringVerifyModel+View.h"

#import "BDTuringVerifyState.h"
#import "BDTuringSettingsKeys.h"
#import "BDTuringVerifyViewDefine.h"
#import "BDTuringQAVerifyView.h"
#import "BDTuringSettings.h"
#import "UIColor+TuringHex.h"
#import "BDTuringConfig.h"
#import "BDTuringUIHelper.h"
#import "BDTuringMacro.h"
#import "BDTuringConfig.h"


@interface BDTuringQAVerifyModel ()

@end

@implementation BDTuringQAVerifyModel

- (BOOL)supportLandscape {
    return self.pop && [super supportLandscape];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.supportLandscape = YES;
        self.plugin = kBDTuringSettingsPluginQA;
        self.verifyType = BDTuringVerifyTypeQA;
        [self createState];
    }
    
    return self;
}

- (void)appendKVToQueryParameters:(NSMutableDictionary *)paramters {
    [super appendKVToQueryParameters:paramters];
    BOOL pop = self.pop;
    if (pop) {
        [paramters setValue:@"1" forKey:@"isPop"];
    }
}

- (BDTuringVerifyView *)createVerifyView {
    CGRect bounds = [UIScreen mainScreen].bounds;
    BDTuringQAVerifyView *qa = [[BDTuringQAVerifyView alloc] initWithFrame:bounds];
    qa.pop = self.pop;
    return qa;
}

- (void)configVerifyView:(BDTuringVerifyView *)verifyView {
    [super configVerifyView:verifyView];
    if (!self.pop) {
        return;
    }
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
                                    defaultValue:@(300)] doubleValue];
    CGFloat height = [[settings settingsForPlugin:plugin
                                              key:kBDTuringSettingsHeight
                                     defaultValue:@(319)] doubleValue];
    
    verifyView.backgroundColor = [UIColor turing_colorWithRGBString:maskRGB alpha:maskAlpha];
    /// set default size
    verifyView.webView.frame = CGRectMake(0, 0, width, height);
    verifyView.webView.center = [verifyView subViewCenter];
}

@end
