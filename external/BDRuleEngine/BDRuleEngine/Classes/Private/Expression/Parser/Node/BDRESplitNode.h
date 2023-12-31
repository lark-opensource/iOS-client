//
//  BDRESplitNode.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "BDREBaseNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDRESplitNode : BDREBaseNode

- (instancetype)initAsSplitNode:(NSString *)originValue index:(NSUInteger)index;

@end

@interface BDRELeftSplitNode : BDRESplitNode

@property (nonatomic, assign) BOOL isFunctionStart;

@end

@interface BDRERightSplitNode : BDRESplitNode

@end

@interface BDRECenterSplitNode : BDRESplitNode

@end

NS_ASSUME_NONNULL_END
