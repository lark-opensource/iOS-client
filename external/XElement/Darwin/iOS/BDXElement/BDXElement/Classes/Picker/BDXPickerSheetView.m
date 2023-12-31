//
//  BDXPickerSheetView.m
//  AWEAppConfigurations
//
//  Created by annidy on 2020/5/8.
//

#import "BDXPickerSheetView.h"
#import "BDXElementResourceManager.h"
#import <ByteDanceKit/ByteDanceKit.h>

@interface BDXPickerSheetView()<UIPickerViewDelegate, UIPickerViewDataSource>
@property (nonatomic, strong) UIView *background;
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, strong) UIDatePicker *datePicker;

@end

static NSDictionary* EventDetail(NSDictionary *content)
{
    return content;
}

@implementation BDXPickerSheetView

- (void)setupViews
{
    if (!_background) {
        _background = [[UIView alloc] initWithFrame:self.bounds];
        _background.backgroundColor = [UIColor blackColor];
        _background.alpha = 0.f;
        UITapGestureRecognizer * backgroundGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundOnClick:)];
        [_background addGestureRecognizer:backgroundGesture];
        [self addSubview:self.background];
    }
    if (!_toolbar) {
        UIBarButtonItem* cancelButton = [[UIBarButtonItem alloc] initWithTitle:_dataSource.cancelString style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonOnClick:)];
        if (_dataSource.cancelColor) {
            cancelButton.tintColor = _dataSource.cancelColor;
        }
        
        UIBarButtonItem* flexibleSpaceButton0 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

        UIBarButtonItem* titleButton = [[UIBarButtonItem alloc] initWithTitle:_dataSource.title style:UIBarButtonItemStylePlain target:nil action:nil];
        if (_dataSource.titleColor) {
            titleButton.tintColor = _dataSource.titleColor;
        }
        [titleButton setTitleTextAttributes:@{
            NSFontAttributeName: [UIFont boldSystemFontOfSize:_dataSource.titleFontSize]}
                                              forState: UIControlStateNormal];

        UIBarButtonItem* flexibleSpaceButton1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        UIBarButtonItem* confirmButton = [[UIBarButtonItem alloc] initWithTitle:_dataSource.confirmString style:UIBarButtonItemStylePlain target:self action:@selector(confirmButtonOnClick:)];
        if (_dataSource.confirmColor) {
            confirmButton.tintColor = _dataSource.confirmColor;
        }
        
        _toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.btd_bottom, self.btd_width, 40)];
        _toolbar.backgroundColor = [UIColor whiteColor];
        [_toolbar setItems:@[cancelButton, flexibleSpaceButton0, titleButton, flexibleSpaceButton1, confirmButton]];
        [self addSubview:self.toolbar];
    }
    
    UIView *picker = self.pickerView ?: self.datePicker;
    
    if (@available(iOS 13.0, *)) {
      picker.backgroundColor = [UIColor systemGroupedBackgroundColor];
    }
    picker.btd_top = self.btd_bottom;
    picker.btd_width = self.btd_width;
    
    [self addSubview:picker];
}



- (void)cancelButtonOnClick:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(onPickerSheetCancel:withResult:)]) {
        [self.delegate onPickerSheetCancel:self withResult:@{@"cancelby": @"btn"}];
    }
    [self dismiss];
}

- (void)backgroundOnClick:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(onPickerSheetCancel:withResult:)]) {
        [self.delegate onPickerSheetCancel:self withResult:@{@"cancelby": @"outside"}];
    }
    [self dismiss];
}

- (void)confirmButtonOnClick:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(onPickerSheetConfirm:withResult:)]) {
        [self.delegate onPickerSheetConfirm:self withResult:[self result]];
    }
    [self dismiss];
}

- (void)showInView:(UIView *)view
{
    UIViewController *vc = [BTDResponder topViewControllerForView:view];
    if (self.showInWindow) {
        vc = nil;
    }
    if (vc) {
        [vc.view addSubview:self];
        self.frame = vc.view.bounds;
    } else {
        [[UIApplication sharedApplication].keyWindow.rootViewController.view addSubview:self];
        self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    }
    [self setupViews];
    [UIView animateWithDuration:0.25f animations:^{
        self.background.alpha = 0.5;
        UIView *picker = self.pickerView ?: self.datePicker;
        picker.btd_bottom = self.btd_bottom;
        self.toolbar.btd_bottom = picker.btd_top;
    }];
}

- (void)dismiss
{
    [UIView animateWithDuration:0.25f animations:^{
        self.background.alpha = 0.f;
        self.toolbar.btd_top = self.btd_bottom;
        UIView *picker = self.pickerView ?: self.datePicker;
        picker.btd_top = self.toolbar.btd_bottom;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (NSArray<NSNumber *> *)selectedIndexs
{
    NSInteger components = [self.pickerView numberOfComponents];
    NSMutableArray *indexs = [[NSMutableArray alloc] initWithCapacity:components];
    
    for (NSInteger i = 0; i < components; i++) {
        [indexs addObject:@([self.pickerView selectedRowInComponent:i])];
    }
    
    return [indexs copy];
}

- (NSDictionary *)result
{
    if (self.pickerView) {
        if ([self.dataSource.mode isEqualToString:kBDXPickerSourceModeSelector] || [self.dataSource.mode isEqualToString:kBDXPickerSourceModeSelectorLegacy]) {
            return EventDetail(@{@"value":@([self.pickerView selectedRowInComponent:0])});
        }
        if ([self.dataSource.mode isEqualToString:kBDXPickerSourceModeMultiSelector] || [self.dataSource.mode isEqualToString:kBDXPickerSourceModeMultiSelectorLegacy]) {
            NSInteger components = [self.pickerView numberOfComponents];
            NSMutableArray *indexs = [[NSMutableArray alloc] initWithCapacity:components];
            
            for (NSInteger i = 0; i < components; i++) {
                [indexs addObject:@([self.pickerView selectedRowInComponent:i])];
            }
            return EventDetail(@{@"value":indexs});
        }
        if ([self.dataSource.mode isEqualToString:kBDXPickerSourceModeDate] || [self.dataSource.mode isEqualToString:kBDXPickerSourceModeDateLegacy]) {
            NSString *fields = [(BDXPickerDateTimeSource *)self.dataSource fields];
            if ([fields isEqualToString:@"month"]) {
                NSInteger i = [self.pickerView selectedRowInComponent:0];
                NSString *year = [self.dataSource stringValueForRow:i forComponent:0];
                
                NSInteger j = [self.pickerView selectedRowInComponent:1];
                NSString *month = [self.dataSource stringValueForRow:j forComponent:1];
                
                NSScanner *scan = [NSScanner scannerWithString:year];
                int nyear = 0;
                int nmonth = 0;
                
                [scan scanInt:&nyear];
                scan = [NSScanner scannerWithString:month];
                [scan scanInt:&nmonth];

                BDXPickerDateTimeSource *source = (BDXPickerDateTimeSource *)self.dataSource;
                NSString *separator = source.separator?:@"-";
                NSString *dateStr = [NSString stringWithFormat:@"%04d%@%02d", nyear, separator, nmonth];
                return EventDetail(@{@"value": dateStr});
            }
            if ([fields isEqualToString:@"year"]) {
                NSInteger i = [self.pickerView selectedRowInComponent:0];
                NSString *year = [self.dataSource stringValueForRow:i forComponent:0];
                NSScanner *scan = [NSScanner scannerWithString:year];
                int nyear = 0;
                [scan scanInt:&nyear];
                return EventDetail(@{@"value":[NSString stringWithFormat:@"%04d", nyear]});
            }
        }
    } else if (self.datePicker) {
        NSDate *date = self.datePicker.date;
        NSString *fields = [(BDXPickerDateTimeSource *)self.dataSource fields];
        if ([self.dataSource.mode isEqualToString:kBDXPickerSourceModeTime] || [self.dataSource.mode isEqualToString:kBDXPickerSourceModeTimeLegacy]) {
            BDXPickerDateTimeSource *source = (BDXPickerDateTimeSource *)self.dataSource;
            NSString *separator = source.separator?:@":";
            return EventDetail(@{@"value":[NSString stringWithFormat:@"%02d%@%02d", (int)date.btd_hour, separator,  (int)date.btd_minute]});
        }
        if ([fields isEqualToString:@"day"]) {
            
            BDXPickerDateTimeSource *source = (BDXPickerDateTimeSource *)self.dataSource;
            NSString *separator = source.separator?:@"-";
            NSString *dateStr = [NSString stringWithFormat:@"%04d%@%02d%@%02d", (int)date.btd_year, separator, (int)date.btd_month, separator,(int)date.btd_day];
            return EventDetail(@{@"value": dateStr});
        }
    }
    return @{};
}

- (void)setDataSource:(BDXPickerSource * _Nonnull)dataSource
{
    _dataSource = dataSource;
    UIView *view;
    if ([dataSource isKindOfClass:[BDXPickerDateTimeSource class]] &&
        !([(BDXPickerDateTimeSource *)dataSource isYearAndMonth])) {
        
        _datePicker = [[UIDatePicker alloc] initWithFrame:CGRectZero];
        _datePicker.minimumDate = self.dataSource.startDate;
        _datePicker.maximumDate = self.dataSource.endDate;
        NSDate *valueDate = nil;
        if ((valueDate = self.dataSource.valueDate)) {
            _datePicker.date = valueDate;
        }
        if ([dataSource.mode isEqualToString:kBDXPickerSourceModeTime] || [dataSource.mode isEqualToString:kBDXPickerSourceModeTimeLegacy]) {
            _datePicker.datePickerMode = UIDatePickerModeTime;
        } else {
            _datePicker.datePickerMode = UIDatePickerModeDate;
        }
        if (@available(iOS 13.4, *)) {
            _datePicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
        }
        [self.pickerView removeFromSuperview];
        self.pickerView = nil;
        view = _datePicker;
    } else {
        _pickerView = [[UIPickerView alloc] initWithFrame:CGRectZero];
        _pickerView.delegate = self;
        _pickerView.dataSource = self;
        
        [self.datePicker removeFromSuperview];
        self.datePicker = nil;
        view = _pickerView;
        
        // default
        NSArray *values = [dataSource valuesRow];
        for (int i = 0; i < values.count; i++) {
            NSInteger row = [values[i] integerValue];
            [_pickerView selectRow:row inComponent:i animated:NO];
        }
    }
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    view.backgroundColor = [UIColor btd_colorWithHexString:@"#F4F5F6"];
    [view sizeToFit];
}


#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return self.dataSource.numberOfComponents;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.dataSource numberOfRowsInComponent:component];
}

#pragma mark - UIPickerViewDelegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if ([self.delegate respondsToSelector:@selector(onPickerSheetChanged:withResult:)]) {
        [self.delegate onPickerSheetChanged:self withResult:EventDetail(@{@"column":@(component),
                                                                          @"value": @(row)})];
    }
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *fontLabel;
    if (!view) {
        fontLabel = [UILabel new];
        fontLabel.backgroundColor = [UIColor clearColor];
        fontLabel.textAlignment = NSTextAlignmentCenter;
    } else {
        fontLabel = (UILabel*)view;
    }
    
    UIFont *font = [UIFont systemFontOfSize:18.f];
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
    NSAttributedString *attributesString = [[NSAttributedString alloc] initWithString:[self.dataSource stringValueForRow:row forComponent:component]
                                                                           attributes:attributesDictionary];
    fontLabel.attributedText = attributesString;
    [fontLabel sizeToFit];
    fontLabel.frame = CGRectMake(0, 0, self.componentWidth, fontLabel.btd_height);
    return fontLabel;
}

-(CGFloat)componentWidth
{
    NSInteger count = self.dataSource.numberOfComponents;
    if (count == 1) {
        return self.btd_width - 50 * 2;
    }
    else if (count == 2) {
        return (self.btd_width - 25 * 4 ) / 2;
    }
    else if (count == 3) {
        return (self.btd_width - 12 * 6) / 3;
    }
    else {
        if (count > 0)
            return self.btd_width / count;
    }
    return 0;
}
@end
