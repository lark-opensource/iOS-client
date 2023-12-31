//
//  BDAutoVerify.m
//  BDTuring
//
//  Created by yanming.sysu on 2020/8/4.
//

#import "BDAutoVerify.h"
#import "BDTuringPiper.h"
#import "BDTuringVerifyView.h"
#import "BDTuringVerifyModel.h"
#import "BDAutoVerifyView.h"

#import "BDTuringVerifyModel+Result.h"
#import "BDTuringEventService.h"
#import "BDTuringSettings.h"
#import "BDTuringConfig.h"
#import "BDTuring.h"
#import "BDTuring+Private.h"
#import "BDAutoVerifyModel.h"
#import "BDTuringVerifyModel+View.h"
#import "WKWebView+Piper.h"
#import "BDTuringVerifyConstant.h"
#import "BDAutoVerifyConstant.h"
#import "BDAutoVerifyDataModel.h"
#import "BDAutoVerifyMaskView.h"
#import "BDTuringVerifyModel+Config.h"
#import "BDTuringSettingsKeys.h"

@interface BDAutoVerify ()

@property (nonatomic, weak) BDAutoVerifyView *autoVerifyView;
@property (nonatomic, weak) BDAutoVerifyMaskView *fullAutoVerifyMaskView;
@property (nonatomic, strong) BDTuring *turing;
@property (nonatomic, assign) BDAutoVerifyViewType type;
@property (nonatomic, strong) BDAutoVerifyModel *model;

@end

@implementation BDAutoVerify

- (instancetype)initWithTuring:(BDTuring *)turing {
    if (self = [super init]) {
        self.turing = turing;
    }
    return self;
}

- (BDAutoVerifyView *)autoVerifyViewWithModel:(BDAutoVerifyModel *)model {
    model.plugin = kBDTuringSettingsPluginAutoVerify;
    self.model = model;
    /// why call popVerifyViewWithModel ????
    [self.turing popVerifyViewWithModel:model];
    self.type = BDAutoVerifyViewWebButtonType;
    if ([self.turing.autoVerifyView isKindOfClass:[BDAutoVerifyView class]]) {
        self.autoVerifyView = (BDAutoVerifyView *)self.turing.autoVerifyView;
        self.autoVerifyView.verify = self;
        self.autoVerifyView.isShow = YES;
        return self.autoVerifyView;
    }
    return nil;
}

- (BDAutoVerifyMaskView *)autoVerifyMaskViewWithModel:(BDAutoVerifyModel *)model {
    model.plugin = kBDTuringSettingsPluginFullAutoVerify;
    BDAutoVerifyMaskView *view = [[BDAutoVerifyMaskView alloc] initWithVerify:self frame:model.frame];
    view.startTimeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
    self.fullAutoVerifyMaskView = view;
    model.frame = CGRectZero; //set zero to hide webview before load
    self.type = BDAutoVerifyViewMaskViewType;
    self.model = model;
    return view;
}

@end
