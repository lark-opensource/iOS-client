//
//  BDPAppPage+TMAPullRefresh.m
//  Timor
//
//  Created by muhuai on 2018/1/18.
//  Copyright © 2018年 muhuai. All rights reserved.
//

#import "BDPAppPage+BDPPullRefresh.h"
#import "BDPTaskManager.h"
#import "BDPAppPageController.h"
#import "TMAPullToRefreshView.h"
#import <OPPluginManagerAdapter/BDPJSBridgeCenter.h>

#import <OPFoundation/OPFoundation-Swift.h>
#import <TTMicroApp/TTMicroApp-Swift.h>

@implementation BDPAppPage (BDPPullRefresh)

- (void)bdp_enablePullToRefresh
{
    if (!IsGadgetWebView(self)) {
        NSString *msg = @"please call function when self is BDPAppPage";
        NSString *finalMsg = [NSString stringWithFormat:@"%@,%@", msg, NSStringFromClass(self.class)];
        BDPLogError(finalMsg)
        NSAssert(NO, finalMsg);
        return;
    }
    WeakSelf;
    [self.scrollView addPullDownWithActionHandler:^{
        StrongSelfIfNilReturn;
        [(BDPAppPage *)self publishEvent:@"onPullDownRefresh" param:nil];
    }];
    
    TMAPullToRefreshView *refreshView = [[TMAPullToRefreshView alloc] initWithFrame:self.scrollView.tmaRefreshView.bounds];
    BDPWindowConfig *windowConfig = self.bap_pageConfig.window;
    WeakObject(refreshView);
    [refreshView opSetDynamicWithHandler:^(UITraitCollection * _Nonnull traitCollection) {
        StrongObject(refreshView);
        refreshView.backgroundTextStyle = windowConfig.backgroundTextStyle;
    }];
    [self.scrollView.tmaRefreshView reConfigureWithRefreshAnimateView:refreshView WithConfigureSuccessCompletion:nil];
}

- (void)bap_registerPullToRefreshWithUniqueID:(OPAppUniqueID *)uniqueID
{
    WeakSelf;
    id<OPMicroAppJSRuntimeProtocol> context = [[BDPTaskManager sharedManager] getTaskWithUniqueID:uniqueID].context;
    
    // startPullDownRefresh
    [BDPJSBridgeCenter registerContextMethod:@"startPullDownRefresh" isSynchronize:NO isOnMainThread:YES engine:context type:BDPJSBridgeMethodTypeNativeApp handler:^(NSDictionary *params, BDPJSBridgeCallback callback) {
        StrongSelfIfNilReturn;
        [self.scrollView tmaTriggerPullDown];
        BDP_CALLBACK_SUCCESS
    }];
    
    // stopPullDownRefresh
    [BDPJSBridgeCenter registerContextMethod:@"stopPullDownRefresh" isSynchronize:NO isOnMainThread:YES engine:context type:BDPJSBridgeMethodTypeNativeApp handler:^(NSDictionary *params, BDPJSBridgeCallback callback) {
        StrongSelfIfNilReturn;
        [self.scrollView tmaFinishPullDownWithSuccess:YES];
        BDP_CALLBACK_SUCCESS
    }];
}

@end
