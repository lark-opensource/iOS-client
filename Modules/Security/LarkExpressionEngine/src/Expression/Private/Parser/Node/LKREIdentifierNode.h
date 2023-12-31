//
//  LKREIdentifierNode.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "LKREBaseNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface LKREIdentifierNode : LKREBaseNode

@property (nonatomic, strong) NSString *identifier;

- (instancetype)initWithIdentifierValue:(id)identifier originValue:(NSString *)originValue index:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
