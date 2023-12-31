//
//  BDREFunctionCommand.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "BDRECommand.h"
#import "BDREFunc.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDREFunctionCommand : BDRECommand

@property (nonatomic, strong, readonly) BDREFunc *func;
@property (nonatomic, copy, readonly) NSString *funcName;
@property (nonatomic, assign, readonly) NSUInteger argsNumber;

- (nonnull instancetype)initWithFuncName:(nonnull NSString *)funcName func:(nullable BDREFunc *)func argsLength:(NSUInteger)argsLength;

@end

NS_ASSUME_NONNULL_END
