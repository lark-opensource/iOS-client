//
//  BDXResourceLoaderGurdProcessor.h
//  BDXResourceLoader
//
//  Created by David on 2021/3/16.
//

#import "BDXRLProcessor.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXRLGurdProcessor : BDXRLBaseProcessor

+ (void)deleteGurdCacheForResource:(id<BDXResourceProtocol>)resource;

@end

NS_ASSUME_NONNULL_END
