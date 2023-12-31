//
//  LVDependencyInjector.h
//  VideoTemplate
//
//  Created by zenglifeng on 2020/3/27.
//

#import <Foundation/Foundation.h>
#import "LVBundleDataSource.h"

extern Class<LVBundleDataSource> _Nullable bundleDataSourceProvider;

NS_ASSUME_NONNULL_BEGIN

@interface LVDependencyInjector : NSObject

+ (void)setBundleDataSource:(nullable Class<LVBundleDataSource>)BundleDataSource;

@end

NS_ASSUME_NONNULL_END
