//
//  BDAccountSealView.h
//  BDTuring
//
//  Created by bob on 2020/2/27.
//

#import "BDTuringWebView.h"
#import "BDAccountSealDefine.h"

NS_ASSUME_NONNULL_BEGIN

@class BDTuringConfig, BDAccountSealModel;

@interface BDAccountSealView : BDTuringWebView

@property (nonatomic, strong) BDAccountSealModel *model;
@property (nonatomic, strong) BDTuringConfig *config;

- (void)loadSealView;

@end

NS_ASSUME_NONNULL_END
