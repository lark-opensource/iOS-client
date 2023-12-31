//
//  BDPRegionPickerDelegate.h
//  TTMicroApp-Example
//
//  Created by 刘相鑫 on 2019/1/16.
//  Copyright © 2019 Bytedance.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BDPRegionPickerPluginModel;
@class BDPPickerView;
@class BDPAddressPluginModel;

NS_ASSUME_NONNULL_BEGIN

@interface BDPRegionPickerDelegate : NSObject <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, weak) UIPickerView *pickerView;

- (instancetype)initWithModel:(BDPRegionPickerPluginModel *)model pickerView:(UIPickerView *)pickerView;

- (BDPAddressPluginModel *)currentAddress;
- (void)selectCurrent;

@end

NS_ASSUME_NONNULL_END
