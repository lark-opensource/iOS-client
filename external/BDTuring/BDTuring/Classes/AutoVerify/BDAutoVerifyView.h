//
//  BDAutoVerifyView.h
//  BDTuring
//
//  Created by yanming.sysu on 2020/8/4.
//

#import "BDTuringVerifyView.h"
#import "BDAutoVerifyConstant.h"
#import "BDTuringPiperConstant.h"

NS_ASSUME_NONNULL_BEGIN

@class BDTuringConfig, BDAutoVerifyMaskView, BDAutoVerify;

@interface BDAutoVerifyView : BDTuringVerifyView

@property (nonatomic, strong) BDAutoVerifyMaskView *maskView;
@property (nonatomic, assign) BDAutoVerifyViewType type;
@property (nonatomic, strong) BDAutoVerify *verify;

@property (nonatomic, assign) BDTuringPiperOnCallback callback;

- (void)uploadAutoVerifyData;

@end

NS_ASSUME_NONNULL_END
