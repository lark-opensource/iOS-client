//
//  BDPDatePickerView.m
//  TTMicroAppImpl
//
//  Created by MacPu on 2019/1/6.
//

#import "BDPDatePickerView.h"
#import <OPFoundation/UIView+BDPExtension.h>
#import <OPFoundation/BDPI18n.h>
#import <OPFoundation/UIColor+EMA.h>
#import <OPFoundation/BDPUtils.h>
#import <Masonry/Masonry.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>
#import <OPFoundation/BDPDatePickerPluginModel.h>

static const NSInteger kStartYear = 1900;
static const NSInteger kEndYear = 2100;
static const NSInteger kStartMonth = 1;

#define YEAR_TO_COMPONENT_ROW(YEAR) YEAR - kStartYear
#define MONTH_TO_COMPONENT_ROW(MONTH) MONTH - kStartMonth

#define IS_YEAR_MONTH_FIELD [self.model.fields isEqualToString:@"month"]
#define IS_YEAR_MONTH_DAY_FIELD [self.model.fields isEqualToString:@"day"]

@interface BDPDatePickerView() <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, strong) BDPDatePickerPluginModel *model;
@property (nonatomic, strong) UIView *background;
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UIDatePicker *picker;
@property (nonatomic, strong) UIPickerView *yearMonthPicker;
@property (nonatomic, strong) NSArray<NSArray<NSString *> *> *items;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSLocale *locale;
@property (nonatomic, strong) NSCalendar *calendar;
@property (nonatomic, assign, readwrite) BDPDatePickerViewStyle style;

@end

@implementation BDPDatePickerView

- (instancetype)initWithFrame:(CGRect)frame model:(BDPDatePickerPluginModel *)model
{
    return [self initWithFrame:frame model:model style:BDPDatePickerViewStylePicker];
}

- (instancetype)initWithFrame:(CGRect)frame model:(BDPDatePickerPluginModel *)model style:(BDPDatePickerViewStyle)style
{
    self = [super initWithFrame:frame];
    if (self) {
        _style = style;
        [self setupDate];
        [self setupViews];
        [self updateWithModel:model];
    }
    return self;
}

- (void)setupDate {
    self.locale = BDPI18n.currentLocale;
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.locale = self.locale;
    self.calendar = [NSCalendar currentCalendar];
}

- (void)setupViews
{
    _background = [[UIView alloc] initWithFrame:self.bounds];
    _background.backgroundColor = UDOCColor.bgMask;
    _background.alpha = 0.f;
    UITapGestureRecognizer * backgroundGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(cancelBtnClicked:)];
    [_background addGestureRecognizer:backgroundGesture];

    _toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.bdp_bottom, self.bdp_width, 40)];
    _toolbar.translucent = NO;
    _toolbar.barTintColor = UDOCColor.bgBody;
    UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithTitle:BDPI18n.cancel style:UIBarButtonItemStylePlain target:self action:@selector(cancelBtnClicked:)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithTitle:BDPI18n.confirm style:UIBarButtonItemStylePlain target:self action:@selector(confirmBtnClicked:)];
    [left setTintColor:UDOCColor.primaryPri500];
    [right setTintColor:UDOCColor.primaryPri500];
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 20;
    if (_style == BDPDatePickerViewStyleAlert) {
        [_toolbar setItems:@[fixedSpace,
                             left,
                             space,
                             right,
                             fixedSpace]];


    } else {

        [_toolbar setItems:@[left,
                             space,
                             right]];

    }
    [self addSubview:self.background];
    [self addSubview:self.toolbar];
    [_background mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self);
    }];
}

- (void)showInView:(UIView *)view {
    self.style = BDPDatePickerViewStylePicker;
    [view addSubview:self];
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(view);
    }];
    [UIView animateWithDuration:0.3f animations:^{
        self.background.alpha = 1;
        // 此处逻辑由原始frame布局迁移为autolayout, 布局遵循原始frame布局不变
        [_toolbar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.width.mas_equalTo(self);
            make.height.mas_equalTo(40.0);
        }];
        [_picker mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.mas_equalTo(self);
            make.width.centerX.mas_equalTo(self);
            make.top.mas_equalTo(_toolbar.mas_bottom);
        }];
        [_yearMonthPicker mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.mas_equalTo(self);
            make.width.centerX.mas_equalTo(self);
            make.top.mas_equalTo(_toolbar.mas_bottom);
        }];
        // 改用autolayout后，需要调用一次layoutIfNeeded以在动画过程中立即生效
        [self layoutIfNeeded];
    }];
}

- (void)showAlertInView:(UIView *)view {
    self.style = BDPDatePickerViewStyleAlert;

    [_toolbar mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.width.mas_equalTo(self);
        make.height.mas_equalTo(40.0);
    }];

    [_picker mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self).offset(20);
        make.width.centerX.mas_equalTo(self);
        make.top.mas_equalTo(_toolbar.mas_bottom);
    }];
    [_yearMonthPicker mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self).offset(20);
        make.width.centerX.mas_equalTo(self);
        make.top.mas_equalTo(_toolbar.mas_bottom);
    }];
    [self layoutIfNeeded];
}

- (void)dismiss {
    if (self.style == BDPDatePickerViewStyleAlert) {
        [self removeFromSuperview];
        return;
    }
    [UIView animateWithDuration:0.25f animations:^{
        self.background.alpha = 0.f;
        // 此处逻辑由原始frame布局迁移为autolayout, 布局遵循原始frame布局不变
        [_toolbar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.width.mas_equalTo(self);
            make.height.mas_equalTo(40.0);
            make.top.mas_equalTo(self.mas_bottom);
        }];
        [_picker mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(_toolbar.mas_bottom);
            make.width.centerX.mas_equalTo(self);
        }];
        [_yearMonthPicker mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(_toolbar.mas_bottom);
            make.width.centerX.mas_equalTo(self);
        }];
        // 改用autolayout后，需要调用一次layoutIfNeeded以在动画过程中立即生效
        [self layoutIfNeeded];

    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}


- (void)updateWithModel:(BDPDatePickerPluginModel *)model
{
    self.model = model;
    if ([model.mode isEqualToString:@"time"] || [model.fields isEqualToString:@"day"]) {
        [self setupTimePicker];
    } else if ([model.mode isEqualToString:@"date"]) {
        [self setupYearMonthPicker];
    }
}

- (void)setupTimePicker
{
    [self.picker removeFromSuperview];
    self.picker = [[UIDatePicker alloc] initWithFrame:self.model.frame];
    self.picker.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.picker.backgroundColor = UDOCColor.bgBody;

    self.picker.minimumDate = self.model.startDate;
    self.picker.maximumDate = self.model.endDate;
    self.picker.date = self.model.currentDate;

    /// 从 iOS 13.4 开始支持设置 style，iOS 14 下默认会变成 compact 模式
    if (@available(iOS 13.4, *)) {
        self.picker.preferredDatePickerStyle = UIDatePickerStyleWheels;

        /// iOS 14 下，初次设置不会生效，下一个 runloop 后再次设置
        dispatch_async(dispatch_get_main_queue(), ^(void){
            self.picker.backgroundColor = UDOCColor.bgBody;
        });
    }
    [self.picker sizeToFit];
    self.picker.bdp_width = self.bdp_width;
    self.picker.bdp_left = 0;
    self.picker.bdp_top = self.bdp_bottom;
    self.picker.locale = self.locale;

    if ([self.model.mode isEqualToString:@"time"]) {
        // 修改为24小时制
        NSString *locale = self.picker.locale.localeIdentifier;
        NSArray *locale_arr = [locale componentsSeparatedByString:@"-"];
        if (!BDPIsEmptyArray(locale_arr)) {
            locale = [locale_arr[0] stringByAppendingString:@"-GB"];
        }
        self.picker.locale = [NSLocale localeWithLocaleIdentifier: locale];
        self.picker.datePickerMode = UIDatePickerModeTime;
    } else {
        self.picker.datePickerMode = UIDatePickerModeDate;
    }

    [self addSubview:self.picker];
}

- (void)setupYearMonthPicker
{
    [self.yearMonthPicker removeFromSuperview];
    self.yearMonthPicker = [[UIPickerView alloc] initWithFrame:CGRectZero];
    self.yearMonthPicker.backgroundColor = UDOCColor.bgBody;
    self.yearMonthPicker.delegate = self;
    self.yearMonthPicker.dataSource = self;
    [self.yearMonthPicker sizeToFit];
    self.yearMonthPicker.bdp_width = self.bdp_width;
    self.yearMonthPicker.bdp_top = self.bdp_bottom;

    [self setupItems];
    [self addSubview:self.yearMonthPicker];
}

- (void)setupItems
{
    NSArray *arrays;

    // Form list of years
    // 不同国家的年月日显示顺序和yyyy等日期组合字符串格式参考：https://en.wikipedia.org/wiki/Date_format_by_country
    // 技术方案详见：https://bytedance.feishu.cn/space/doc/doccnRpyu0hcMs517aEmqK#
    // 获取国际化后的年份字符串，例如中文环境：「2019年」，英文环境：「2019」
    [self.dateFormatter setLocalizedDateFormatFromTemplate:@"yyyy"];
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    NSMutableArray *years = [[NSMutableArray alloc] init];
    for(NSInteger year = kStartYear; year <= kEndYear; year++) {
        comps.year = year;
        NSDate *yearDate = [self.calendar dateFromComponents:comps];
        NSString *yearStr = [self.dateFormatter stringFromDate:yearDate];
        [years addObject:yearStr];
    }

    if ([self.model.fields isEqualToString:@"month"]) {
        // 获取国际化后的月份字符串，例如中文环境：「5月」，英文环境：「May」
        NSArray *months = self.dateFormatter.monthSymbols;
        // 根据不同国家的习惯，显示年月顺序，例如中文环境：「2019年5月」，英文环境：「May 2019」
        if ([self isYearFirstInYearMonthString]) {
            arrays = @[[years copy], [months copy]];
        } else {
            arrays = @[[months copy], [years copy]];
        }
    } else {
        arrays = @[[years copy]];
    }

    self.items = [arrays copy];

    // 根据不同国家的习惯，年月在日期组件中的显示索引会有变化
    NSUInteger indexForYear = [self indexForYearInYearMonthArray];
    NSUInteger indexForMonth = [self indexForMonthInYearMonthArray];
    
    if (self.model.currentDate) {
        NSCalendarUnit unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
        NSDateComponents *comps = [self.calendar components:unitFlags fromDate:self.model.currentDate];
        NSInteger year = [comps year];
        NSInteger yearIndex = year - kStartYear;
        if (yearIndex > 0 && yearIndex < [years count]) {
            [self.yearMonthPicker selectRow:yearIndex inComponent:indexForYear animated:NO];
        }
        if ([arrays count] == 2) {
            NSMutableArray *months = [arrays objectAtIndex:indexForMonth];
            NSInteger month = [comps month];
            NSInteger monthIndex = month - 1;
            if (monthIndex > 0 && monthIndex < [months count]) {
                [self.yearMonthPicker selectRow:monthIndex inComponent:indexForMonth animated:NO];
            }
        }
    }

}

- (void)selectDate:(NSDate *)date animated:(BOOL)animated
{
    if (!self.yearMonthPicker) {
        return;
    }
    
    NSCalendarUnit unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth;
    NSDateComponents *components = [self.calendar components:unitFlags fromDate:date];
    NSInteger year = YEAR_TO_COMPONENT_ROW(components.year);
    [self.yearMonthPicker selectRow:year inComponent:[self indexForYearInYearMonthArray] animated:animated];
    
    if (IS_YEAR_MONTH_FIELD) {
        NSInteger month = MONTH_TO_COMPONENT_ROW(components.month);
        [self.yearMonthPicker selectRow:month inComponent:[self indexForMonthInYearMonthArray] animated:animated];
    }
}

/// 返回年+月日期国际化字符串中年的顺序是否在最前面
- (BOOL)isYearFirstInYearMonthString {
    NSDate *now = NSDate.date;
    [self.dateFormatter setLocalizedDateFormatFromTemplate:@"yyyy"];
    NSString *yearStr = [self.dateFormatter stringFromDate:now];

    [self.dateFormatter setLocalizedDateFormatFromTemplate:@"yyyyMMMM"];
    NSString *yearMonthStr = [self.dateFormatter stringFromDate:now];

    BOOL isYearFirst = [yearMonthStr hasPrefix:yearStr];

    return isYearFirst;
}

/// 返回年在日期组件中的索引
- (NSUInteger)indexForYearInYearMonthArray {
    if (self.items.count == 1) {
        return 0;
    }
    return [self isYearFirstInYearMonthString] ? 0 : 1;
}

/// 返回月在日期组件中的索引
- (NSUInteger)indexForMonthInYearMonthArray {
    return (![self isYearFirstInYearMonthString]) ? 0 : 1;
}
- (void)cancelBtnClicked:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didCancelDatePicker:)]) {
        [self.delegate didCancelDatePicker:self];
    }
    [self dismiss];
}

- (void)confirmBtnClicked:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(datePicker:didSelectedDate:)]) {
        [self.delegate datePicker:self didSelectedDate:[self currentDate]];
    }
    [self dismiss];
}

- (NSDate *)currentDate
{
    NSDate *time;
    NSUInteger indexForYear = [self indexForYearInYearMonthArray];
    NSUInteger indexForMonth = [self indexForMonthInYearMonthArray];
    if (self.yearMonthPicker) {
        NSCalendarUnit unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth;
        NSDateComponents *components = [self.calendar components:unitFlags fromDate:[NSDate date]];
        NSInteger year = [self.yearMonthPicker selectedRowInComponent:indexForYear] + kStartYear;
        if ([self.model.fields isEqualToString:@"year"]) {
            components.year = year;
            time = [self.calendar dateFromComponents:components];
        } else if ([self.model.fields isEqualToString:@"month"]) {
            NSInteger month = [self.yearMonthPicker selectedRowInComponent:indexForMonth] + 1;
            components.year = year;
            components.month = month;
            time = [self.calendar dateFromComponents:components];
        }
    } else {
        time = self.picker.date;
    }
    
    return time;
}

-(CGFloat)componentWidthWithCount:(NSUInteger)count{
    if (self.items.count == 1) {
        return self.bdp_width - 50 * 2;
    }
    else if (self.items.count == 2) {
        return (self.bdp_width - 25 * 4 ) / 2;
    }
    else if (self.items.count == 3) {
        return (self.bdp_width - 12 * 6) / 3;
    }
    else{
        return self.bdp_width / self.items.count;
    }
}

#pragma mark - UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return self.items.count;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.items[component].count;
}
#pragma mark - UIPickerViewDelegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (!self.yearMonthPicker) {
        return;
    }
    
    NSDate *currentDate = [self currentDate];
    NSComparisonResult cmpRes = [currentDate compare:self.model.startDate];
    BOOL earlierThanStartDate = cmpRes == NSOrderedAscending;
    if (earlierThanStartDate) {
        [self selectDate:self.model.startDate animated:YES];
        return;
    }
    
    cmpRes = [currentDate compare:self.model.endDate];
    BOOL laterThanEndDate = cmpRes == NSOrderedDescending;
    if (laterThanEndDate) {
        [self selectDate:self.model.endDate animated:YES];
        return;
    }
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UILabel *fontLabel;
    if (!view) {
        fontLabel = [UILabel new];
        fontLabel.backgroundColor = [UIColor clearColor];
        fontLabel.textAlignment = NSTextAlignmentCenter;
    } else {
        fontLabel = (UILabel*)view;
    }
    fontLabel.textColor = UDOCColor.textTitle;

    /// 日期组件（field: year / month）中字体与UIDatePicker中的字体大小一致
    UIFont *font = [UIFont systemFontOfSize:18.f];
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
    NSAttributedString *attributesString = [[NSAttributedString alloc] initWithString:self.items[component][row] attributes:attributesDictionary];
    fontLabel.attributedText = attributesString;
    CGFloat width = [self componentWidthWithCount:self.items.count];
    fontLabel.frame = CGRectMake(0, 0, width, fontLabel.bdp_height);
    [fontLabel sizeToFit];
    return fontLabel;
}

@end
