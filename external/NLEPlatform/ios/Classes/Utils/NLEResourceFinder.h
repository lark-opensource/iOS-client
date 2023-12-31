//
//  NLEResourceFinder.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/2/16.
//

#import <Foundation/Foundation.h>
#import "NLEBundleDataSource.h"
#import "NLEResourceFinderProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLEResourceFinder : NSObject<NLEResourceFinderProtocol>

@property (nonatomic, strong, nullable) id<NLEBundleDataSource> bundleDataSource;
@property (nonatomic, copy) NSString *rootPath;

- (instancetype)initWithRootPath:(NSString *)rootPath
                bundleDataSource:(id<NLEBundleDataSource>)bundleDataSource;

- (instancetype)initWithBundleDataSource:(id<NLEBundleDataSource>)bundleDataSource;

@end

NS_ASSUME_NONNULL_END
