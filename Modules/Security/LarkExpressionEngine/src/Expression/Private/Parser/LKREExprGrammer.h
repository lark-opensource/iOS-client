//
//  LKREExprGrammer.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import <Foundation/Foundation.h>
#import "LKRECommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface LKREExprGrammer : NSObject

+ (NSArray *)parseNodesToCommands:(NSArray *)nodes error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
