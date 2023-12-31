//
//  BDResourceLoaderPluginObject.h
//  Indexer
//
//  Created by pc on 2022/3/22.
//

#import <BDWebCore/IWKPluginObject.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKWebViewConfiguration (BDResouceLoaderPlugin)

/// use ResourceLoader for offline resource when use TTNet scheme handler (BDWebViewSchemeTaskHandler).
@property (nonatomic, assign) BOOL bdw_enableResourceLoaderWithTTNet API_AVAILABLE(ios(12.0));

/// use ResourceLoader for offline resource when use Falcon
@property (nonatomic, assign) BOOL bdw_enableResourceLoaderWithFalcon;

/// It shoulrd enable ttnet scheme handler or ttnet falcon first.
@property (nonatomic, assign) BOOL bdw_addCommonParamsWithGeckoResourceURL;

@end

@class BDXResourceLoaderTaskConfig;
typedef void (^BDResouceLoaderPluginTaskBuilder)(BDXResourceLoaderTaskConfig * taskConfig);

@interface WKWebView (BDResouceLoaderPlugin)

@property (nonatomic, copy) BDResouceLoaderPluginTaskBuilder bdwrl_taskBuilder;

@end

@interface BDResourceLoaderPluginObject : IWKPluginObject <IWKClassPlugin>

+ (void)setup;

@end



NS_ASSUME_NONNULL_END
