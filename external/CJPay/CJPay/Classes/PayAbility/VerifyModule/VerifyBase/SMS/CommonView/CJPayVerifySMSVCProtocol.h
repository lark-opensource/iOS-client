//
// Created by liyu on 2020/3/30.
//

#import <Foundation/Foundation.h>

#import "CJPayStateView.h"
#import "CJPayLoadingManager.h"
#import "CJPayTrackerProtocol.h"

@class CJPayVerifySMSHelpModel;
@class CJPayBDCreateOrderResponse;
@class CJPayDefaultChannelShowConfig;

@protocol CJPayVerifySMSVCProtocol <CJPayBaseLoadingProtocol>

@property (nonatomic, weak) id<CJPayTrackerProtocol> trackDelegate; // 埋点上报代理
@property (nonatomic, assign) BOOL needSendSMSWhenViewDidLoad;

@property (nonatomic, strong) CJPayVerifySMSHelpModel *helpModel;
@property (nonatomic, strong) CJPayBDCreateOrderResponse *orderResponse;
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *defaultConfig;
@property (nonatomic, copy) void(^completeBlock)(BOOL success, NSString *content);

- (void)reset;

- (void)clearInput;

- (void)updateTips:(NSString *)tip;

- (void)updateErrorText:(NSString *)text;

- (void)becomeFirstResponder;

- (void)resignFirstResponder;


@end
