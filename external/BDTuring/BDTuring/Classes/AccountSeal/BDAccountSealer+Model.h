//
//  BDAccountSealer+Model.h
//  BDTuring
//
//  Created by bob on 2020/7/15.
//

#import "BDAccountSealer.h"

NS_ASSUME_NONNULL_BEGIN

@class BDAccountSealEvent, BDAccountSealModel, BDTuringConfig;

@interface BDAccountSealer (Model)

@property (nonatomic, assign) long long startLoadTime;
@property (nonatomic, assign) BOOL isShowSealView;
@property (nonatomic, strong) BDTuringConfig *config;
@property (nonatomic, strong, nullable) BDAccountSealModel *model;

- (void)popWithModel:(BDAccountSealModel *)model;

@end

NS_ASSUME_NONNULL_END
