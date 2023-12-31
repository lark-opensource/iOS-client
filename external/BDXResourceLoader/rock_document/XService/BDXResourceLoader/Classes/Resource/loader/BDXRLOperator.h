//
//  BDXResourceLoaderAdvancedOperator.h
//  BDXResourceLoader
//
//  Created by David on 2021/3/16.
//

#import "BDXResourceLoader.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXRLOperator : NSObject <BDXResourceLoaderAdvancedOperatorProtocol>

@property(nonatomic, weak) BDXResourceLoader *resourceLoader;
@property(nonatomic, strong, readonly) NSMutableDictionary *falconPrefixList;

@end

NS_ASSUME_NONNULL_END
