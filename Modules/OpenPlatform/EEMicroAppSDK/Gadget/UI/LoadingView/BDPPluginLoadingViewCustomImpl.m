//
//  BDPPluginLoadingViewCustomImpl.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/11/3.
//

#import "BDPPluginLoadingViewCustomImpl.h"
#import <OPFoundation/BDPUIPluginDelegate.h>
#import "EMALoadingView.h"
#import <OPFoundation/BDPModel.h>

@interface BDPPluginLoadingViewCustomImpl() <BDPLoadingViewPluginDelegate>

@property (nonatomic, weak) EMALoadingView *loadingView;

@end

@implementation BDPPluginLoadingViewCustomImpl

+ (id<BDPBasePluginDelegate>)sharedPlugin
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

- (UIView *)bdp_getLoadingViewWithConfig:(NSDictionary *)config {
    EMALoadingView *loadingView = [[EMALoadingView alloc] init];
    self.loadingView = loadingView;
    return loadingView;
}

- (void)bdp_updateLoadingViewWithModel:(BDPModel *)appModel {
    [self.loadingView updateLoadingViewWithModel:appModel];
}

- (void)bdp_changeToFailState:(int)state withTipInfo:(NSString *)tipInfo {
    [self.loadingView changeToFailState:state withTipInfo:tipInfo];
}

- (void)hideLoadingView {
    [self.loadingView hideLoadingView];
}

@end
