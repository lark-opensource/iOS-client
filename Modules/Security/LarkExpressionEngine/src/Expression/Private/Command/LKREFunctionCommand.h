//
//  LKREFunctionCommand.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "LKRECommand.h"
#import "LKREFunc.h"

NS_ASSUME_NONNULL_BEGIN

@interface LKREFunctionCommand : LKRECommand

@property (nonatomic, assign, readonly) NSUInteger argsNumber;

- (LKREFunctionCommand *)initWithFunc:(LKREFunc *)func argsLength:(NSUInteger)argsLength;

@end

NS_ASSUME_NONNULL_END
