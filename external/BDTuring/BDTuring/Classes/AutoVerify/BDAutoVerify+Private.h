//
//  BDAutoVerify+Private.h
//  BDTuring
//
//  Created by yanming.sysu on 2020/9/6.
//

#import "BDAutoVerify.h"
#import "BDAutoVerifyConstant.h"

NS_ASSUME_NONNULL_BEGIN

@class BDAutoVerifyView, BDAutoVerifyMaskView, BDTuring, BDAutoVerifyModel;

@interface BDAutoVerify (Private)

@property (nonatomic, weak) BDAutoVerifyView *autoVerifyView;
@property (nonatomic, weak) BDAutoVerifyMaskView *fullAutoVerifyMaskView;
@property (nonatomic, strong) BDTuring *turing;
@property (nonatomic, assign) BDAutoVerifyViewType type;
@property (nonatomic, strong) BDAutoVerifyModel *model;

- (void)startAutoVerify;

@end

NS_ASSUME_NONNULL_END
