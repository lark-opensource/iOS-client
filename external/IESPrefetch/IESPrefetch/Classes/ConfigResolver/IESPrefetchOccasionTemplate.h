//
//  IESPrefetchOccasionTemplate.h
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/2.
//

#import <Foundation/Foundation.h>
#import "IESPrefetchConfigTemplate.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESPrefetchOccasionNode : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSArray<NSString *> *rules;

@end

/// 配置中的Occasion模板结构
@interface IESPrefetchOccasionTemplate : NSObject<IESPrefetchConfigTemplate>

- (void)addOccasionNode:(IESPrefetchOccasionNode *)node;
- (IESPrefetchOccasionNode *)nodeForName:(NSString *)name;
- (NSUInteger)countOfNodes;

@end

NS_ASSUME_NONNULL_END
