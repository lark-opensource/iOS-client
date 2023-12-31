//
//  WKWebView+BDOffline.h
//  BDWebKit
//
//  Created by wealong on 2019/12/5.
//

#import <WebKit/WebKit.h>
#import "NSObject+BDWRuntime.h"
#import "BDWebKitDefine.h"
#import <BDWebKit/IESAdSplashChannelInterceptor.h>

@interface WKWebView(BDOffline)

@property (nonatomic) BOOL bdw_hitPreload;

@property (nonatomic, strong) IESAdSplashChannelInterceptor *bdw_channelInterceptor;//针对三方落地页，指定拦截文件目录

@property (nonatomic, copy) NSArray <IESFalconCustomInterceptor> *channelInterceptorList;

@property (nonatomic, assign) BOOL didFinishOrFail;

@end

