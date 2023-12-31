//
//  BDREValueCommand.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "BDRECommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDREValueCommand : BDRECommand

@property (nonatomic, strong, readonly) id value;

- (BDREValueCommand *)initWithValue:(id)value;

@end

NS_ASSUME_NONNULL_END
