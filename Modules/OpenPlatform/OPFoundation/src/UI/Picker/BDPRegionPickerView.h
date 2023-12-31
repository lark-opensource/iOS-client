//
//  BDPRegionPickerView.h
//  TTMicroApp-Example
//
//  Created by 刘相鑫 on 2019/1/16.
//  Copyright © 2019 Bytedance.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BDPRegionPickerPluginModel;
@class BDPAddressPluginModel;
@class BDPRegionPickerView;

typedef void(^BDPRegionPickerViewConfirmBlock)(BDPAddressPluginModel *address);
typedef void(^BDPRegionPickerViewCancelBlock)(void);

NS_ASSUME_NONNULL_BEGIN

@protocol BDPRegionPickerViewDelegate <NSObject>

@optional
- (void)regionPickerView:(BDPRegionPickerView *)regionPickerView didConfirmAddress:(BDPAddressPluginModel *)address;
- (void)regionPickerViewDidCancel:(BDPRegionPickerView *)regionPickerView;

@end

typedef NS_ENUM(NSInteger, BDPRegionPickerViewStyle) {
    BDPRegionPickerViewStylePicker,
    BDPRegionPickerViewStyleAlert
};

@interface BDPRegionPickerView : UIView

@property (nonatomic, strong, readonly) BDPRegionPickerPluginModel *model;

@property (nonatomic, weak, nullable) id<BDPRegionPickerViewDelegate> delegate;
@property (nonatomic, copy, nullable) BDPRegionPickerViewConfirmBlock confirmBlock;
@property (nonatomic, copy, nullable) BDPRegionPickerViewCancelBlock cancelBlock;
- (instancetype)initWithFrame:(CGRect)frame model:(BDPRegionPickerPluginModel *)model style:(BDPRegionPickerViewStyle)style;
- (instancetype)initWithFrame:(CGRect)frame model:(BDPRegionPickerPluginModel *)model;
- (void)showInView:(UIView *)view;
- (void)dismiss;
- (void)showAlertInView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
