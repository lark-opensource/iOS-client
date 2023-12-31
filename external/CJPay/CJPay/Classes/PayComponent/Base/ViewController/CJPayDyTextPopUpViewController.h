//
//  CJPayDyTextPopUpViewController.h
//  Pods
//
//  Created by 孟源 on 2021/11/1.
//

#import "CJPayPopUpBaseViewController.h"
#import "CJPayDyTextPopUpModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayDyTextPopUpViewController : CJPayPopUpBaseViewController

- (instancetype)initWithPopUpModel:(CJPayDyTextPopUpModel *)model;
- (instancetype)initWithPopUpModel:(CJPayDyTextPopUpModel *)model contentView:(UIView *)contentView;

- (void)showOnTopVC:(UIViewController *)vc;

@end

NS_ASSUME_NONNULL_END
