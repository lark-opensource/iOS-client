//
//  BDREExprGrammer.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import <Foundation/Foundation.h>
#import "BDRECommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDREExprGrammer : NSObject

+ (NSArray *)parseNodesToCommands:(NSArray *)nodes error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
