//
//  BDAutoVerify.h
//  BDTuring
//
//  Created by yanming.sysu on 2020/8/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BDTuring, BDAutoVerifyModel;

@interface BDAutoVerify : NSObject

- (instancetype)initWithTuring:(BDTuring *)turing;

- (nullable UIView *)autoVerifyViewWithModel:(BDAutoVerifyModel *)model;
- (UIView *)autoVerifyMaskViewWithModel:(BDAutoVerifyModel *)model;

@end

NS_ASSUME_NONNULL_END
