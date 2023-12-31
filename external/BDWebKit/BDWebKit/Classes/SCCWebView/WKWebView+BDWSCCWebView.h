//
//  WKWebView+BDWSCCWebView.h
//  AWELazyRegister
//
//  Created by bytedance on 6/20/22.
//
#import "BDSCCURLObserver.h"
#import "BDWSCCWebViewCustomHandler.h"
#import <WebKit/WebKit.h>
#import <BDWebCore/IWKPluginObject.h>

//TODO:remove this when doudian remove.
#import "BDSCCFilter.h"

NS_ASSUME_NONNULL_BEGIN


@interface WKWebView (BDWSCCWebView)

@property (atomic, strong) BDWSCCURLObserver *bdw_sccURLObserver;

- (void)bdw_EnableSCCCheckWithHandler:(id<BDWSCCWebViewCustomHandler>)customHandler;

- (void)bdw_DisableSCCCheck;

- (BOOL)disableJumpToOthersAPP:(NSURL * _Nonnull)url;

//TODO:remove this when doudian remove.
@property (nonatomic, assign) BOOL  switchSCCFilter;
@property (nullable, atomic, weak) id<SCCFilterProtocol> handleReport;
@property (nullable, atomic, strong) BDSCCFilter * filter;

@end

NS_ASSUME_NONNULL_END
