//
//  LKREFuncNode.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "LKREBaseNode.h"
#import "LKREFuncManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface LKREFuncNode : LKREBaseNode

- (instancetype)initWithFuncValue:(LKREFunc *)func originValue:(NSString *)originValue index:(NSUInteger)index;
- (LKREFunc *)getFunc;

@end

NS_ASSUME_NONNULL_END
