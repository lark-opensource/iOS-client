//
//  NLEResourceFinderProtocol.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/2/16.
//

#import <Foundation/Foundation.h>
#import "NLEResourceNode.h"

NS_ASSUME_NONNULL_BEGIN

@protocol NLEResourceFinderProtocol <NSObject>

/// 还原 NLEResourceNode.ResourceFile 为指定目录下的绝对路径
/// @discussion 如果 ResourceFile 本身存储一个绝对路径，会忽略 folder 参数直接返回该绝对路径
/// @param resourceNode NLEResourceNode
- (nullable NSString *)resourcePathForNode:(const std::shared_ptr<const cut::model::NLEResourceNode>)resourceNode;

- (nullable NSString *)resourcePathForFilePath:(NSString *)filepath;

@end

NS_ASSUME_NONNULL_END
