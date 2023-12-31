//
//  BDSCCFilter.h
//  dscc
//
//  Created by ByteDance on 2022/9/5.
//
//TODO: remove this file(.h and .m) when doudian remove.
#ifndef BDSCCFilter_h
#define BDSCCFilter_h


#endif /* BDSCCFilter_h */

#import "BDWebRequestFilter.h"
#import "NSObject+BDWRuntime.h"
#import <BDWebCore/WKWebView+Plugins.h>



@protocol SCCFilterProtocol <NSObject>

@optional

- (void)reportEvent:(NSDictionary * _Nullable) status webView:(WKWebView * _Nonnull)webView;

@end

@interface BDSCCFilter:NSObject<BDWebRequestFilter>

@property (nullable, nonatomic, strong) NSMutableArray<NSString *> *whiteListArray;

@property (nullable, nonatomic, strong) NSNumber * switchFilter;

@property (nullable, atomic, strong) id<SCCFilterProtocol> handleReport;

@property (nullable, atomic, weak) WKWebView *webView;

- (BOOL)bdw_willBlockRequest:(NSURLRequest *_Nullable) request;

@end

