//
//  BDRECommandTreeBuildUtil.h
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/12.
//

#import <Foundation/Foundation.h>
#import "BDRETreeNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDRECommandTreeBuildUtil : NSObject

+ (nullable BDRETreeNode *)generateWithCommands:(NSArray<BDRECommand *> *)commands;

@end

NS_ASSUME_NONNULL_END
