//
//  BDAutoVerifyModel.h
//  BDTuring
//
//  Created by yanming.sysu on 2020/8/6.
//

#import "BDTuringVerifyModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoVerifyModel : BDTuringVerifyModel

@property (nonatomic, assign) CGRect frame;

- (instancetype)initWithFrame:(CGRect)frame;

- (instancetype)initWithFrame:(CGRect)frame maskView:(BOOL)useMakeView;

- (void)handleResult:(BDTuringVerifyResult *)result;

@end

NS_ASSUME_NONNULL_END
