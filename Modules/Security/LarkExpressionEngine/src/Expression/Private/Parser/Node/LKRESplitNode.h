//
//  LKRESplitNode.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "LKREBaseNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface LKRESplitNode : LKREBaseNode

- (instancetype)initAsSplitNode:(NSString *)originValue index:(NSUInteger)index;

@end

@interface LKRELeftSplitNode : LKRESplitNode

@property (nonatomic, assign) BOOL isFunctionStart;

@end

@interface LKRERightSplitNode : LKRESplitNode

@end

@interface LKRECenterSplitNode : LKRESplitNode

@end

NS_ASSUME_NONNULL_END
