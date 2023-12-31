//
//  EMALoadingView.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/11/3.
//

#import <UIKit/UIKit.h>
#import <OPFoundation/BDPModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface EMALoadingView : UIView

- (void)updateLoadingViewWithModel:(BDPModel *)appModel;

- (void)hideLoadingView;

- (void)changeToFailState:(int)state withTipInfo:(NSString *)tipInfo;

@end

NS_ASSUME_NONNULL_END
