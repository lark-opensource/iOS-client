//
//  BDPDatePickerView.h
//  TTMicroAppImpl
//
//  Created by MacPu on 2019/1/6.
//

#import <UIKit/UIKit.h>

@class BDPDatePickerView, BDPDatePickerPluginModel;

@protocol BDPDatePickerViewDelegate <NSObject>

- (void)didCancelDatePicker:(BDPDatePickerView *)picker;

- (void)datePicker:(BDPDatePickerView *)picker didSelectedDate:(NSDate *)time;

@end

typedef NS_ENUM(NSInteger, BDPDatePickerViewStyle) {
    BDPDatePickerViewStylePicker,
    BDPDatePickerViewStyleAlert
};

@interface BDPDatePickerView : UIView

@property (nonatomic, weak) id<BDPDatePickerViewDelegate> delegate;
- (instancetype)initWithFrame:(CGRect)frame model:(BDPDatePickerPluginModel *)model style:(BDPDatePickerViewStyle)style;
- (instancetype)initWithFrame:(CGRect)frame model:(BDPDatePickerPluginModel *)model;
- (void)updateWithModel:(BDPDatePickerPluginModel *)model;
- (void)showInView:(UIView *)view;
- (void)showAlertInView:(UIView *)view;

@end

