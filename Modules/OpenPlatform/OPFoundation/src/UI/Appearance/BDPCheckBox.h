//
//  BDPCheckBox.h
//  Timor
//
//  Created by liuxiangxin on 2019/6/18.
//

#import <UIKit/UIKit.h>
#import "BDPAppearance.h"

typedef NS_ENUM(NSInteger, BDPCheckBoxStatus) {
    BDPCheckBoxStatusUnselected = 0,
    BDPCheckBoxStatusSelected = 1,
    BDPCheckBoxStatusDisable
};

NS_ASSUME_NONNULL_BEGIN

@interface BDPCheckBox : UIControl <BDPAppearance>

@property (nonatomic, assign) BDPCheckBoxStatus status;

- (UIColor *)tintColorForStatus:(BDPCheckBoxStatus)status;

- (void)setTintColor:(UIColor *)color forStatus:(BDPCheckBoxStatus)status;

@end

NS_ASSUME_NONNULL_END
