//
//  NLEBundleDataSource.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/2/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class NLEResourceNode_OC;

@protocol NLEBundleDataSource <NSObject>

- (NSString *)resourcePathForNode:(NLEResourceNode_OC *)resourceNode;

@end

NS_ASSUME_NONNULL_END
