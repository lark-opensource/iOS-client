//
//  BDWebPrefetchPluginObject.h
//  BDWebKit
//
//  Created by li keliang on 2020/5/12.
//

#import <Foundation/Foundation.h>
#import <BDWebCore/IWKPluginObject.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKWebView (BDWKPrefetch)

@property (nonatomic, copy) NSString *bdw_prefetchBusiness;

//view 级别的 prefetch 控制开关，默认为 NO
@property (nonatomic, assign) BOOL bdw_disablePrefetch;

@end

@interface BDWebPrefetchPluginObject : IWKPluginObject<IWKClassPlugin>

+ (void)enablePrefetch;

@end

NS_ASSUME_NONNULL_END
