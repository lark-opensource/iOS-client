//
//  BDAutoVerifyModel.m
//  BDTuring
//
//  Created by yanming.sysu on 2020/8/6.
//

#import "BDAutoVerifyModel.h"
#import "BDTuringVerifyModel+View.h"
#import "BDAutoVerifyView.h"
#import "BDTuringVerifyModel+Config.h"
#import "BDTuringVerifyViewDefine.h"
#import "BDTuringSettingsKeys.h"
#import "BDAutoVerifyConstant.h"
#import "BDTuringSettings.h"
#import "UIColor+TuringHex.h"
#import "BDAutoVerify+Private.h"
#import "BDTuringCoreConstant.h"

@implementation BDAutoVerifyModel

- (instancetype)init {
    self = [super init];
    if (self) {
        self.plugin = kBDTuringSettingsPluginAutoVerify;
        self.verifyType = BDTuringVerifyTypeSmart;
        [self createState];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super init]) {
        self.frame = frame;
        self.region = kBDTuringRegionCN;
        [self createState];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame maskView:(BOOL)useMakeView {
    self = [self initWithFrame:frame];
    if (useMakeView) {
        self.plugin = kBDTuringSettingsPluginFullAutoVerify;
    }
    return self;
}

- (BDTuringVerifyView *)createVerifyView {
    BDAutoVerifyView *view = nil;
    if (self.plugin == kBDTuringSettingsPluginFullAutoVerify) {
        view = [[BDAutoVerifyView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        view.type = BDAutoVerifyViewMaskViewType;
        view.webView.frame = CGRectMake(0, 0, _frame.size.width, _frame.size.height);
        // pre set webview's frame
    } else {
        view = [[BDAutoVerifyView alloc] initWithFrame:self.frame];
    }
    return view;
}

- (void)configVerifyView:(BDTuringVerifyView *)verifyView {
    if (self.plugin == kBDTuringSettingsPluginFullAutoVerify) {
        [super configVerifyView:verifyView];
        BDTuringSettings *settings = [BDTuringSettings settingsForAppID:self.appID];
        NSString *maskRGB = [settings settingsForPlugin:kBDTuringSettingsPluginCommon
                                                    key:kBDTuringSettingsRGB
                                           defaultValue:@"000000"];
        CGFloat maskAlpha = [[settings settingsForPlugin:kBDTuringSettingsPluginCommon
                                                     key:kBDTuringSettingsAlpha
                                            defaultValue:@(0.5)] doubleValue];
        
        verifyView.backgroundColor = [UIColor turing_colorWithRGBString:maskRGB alpha:maskAlpha];
        verifyView.webView.center = verifyView.center;

    }
}

- (void)handleResult:(BDTuringVerifyResult *)result {
    BDTuringVerifyResultCallback callback = self.callback;
    if (callback == nil) {
        return;
    }
    if (result.status == BDTuringVerifyStatusOK) {
        self.callback = nil;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        callback(result);
    });
}

@end
