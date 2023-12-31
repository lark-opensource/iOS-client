//
//  BDREIdentifierCommand.h
//  expr_ios_demo
//
//  Created by bytedance on 2021/12/10.
//

#import "BDRECommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDREIdentifierCommand : BDRECommand

@property (nonatomic, copy, readonly) NSString *identifier;

- (BDREIdentifierCommand *)initWithIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
