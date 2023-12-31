//
//  LKREConstNode.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "LKREBaseNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface LKREConstNode : LKREBaseNode

- (instancetype)initWithConstValue:(id)constValue originValue:(NSString *)originValue index:(NSUInteger)index;
- (id)getValue;

@end

NS_ASSUME_NONNULL_END
