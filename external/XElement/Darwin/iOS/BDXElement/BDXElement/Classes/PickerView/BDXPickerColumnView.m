//
//  BDXPickerColumnView.m
//  BDXElement-Pods-Aweme
//
//  Created by 林茂森 on 2020/8/11.
//

#import "BDXPickerColumnView.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>
#import "LynxUI+BDXLynx.h"
#import <Lynx/LynxLayoutStyle.h>
#import <Lynx/LynxView.h>
#import <Lynx/LynxUnitUtils.h>
#import <ByteDanceKit/ByteDanceKit.h>

@interface BDXPickerColumnView() <UIPickerViewDelegate, UIPickerViewDataSource>

@end

@implementation BDXPickerColumnView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initData];
    }
    return self;
}

- (void)initData
{
    self.pickerView.backgroundColor = [UIColor btd_colorWithHexString:@"#ffffff"];
    [self addSubview:_pickerView];
}

// BackgroundColor should be set to real displayed pickerView instead of self.
- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    self.pickerView.backgroundColor = backgroundColor;
}

#pragma mark - lazy load

- (UIPickerView *)pickerView
{
    if(!_pickerView){
        _pickerView = [[UIPickerView alloc] initWithFrame:self.bounds];
        _pickerView.delegate = self;
        _pickerView.dataSource = self;
    }
    return _pickerView;
}

#pragma mark - dataSource

// column
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    if (self.columnValue == nil || [self.columnValue isEqual:[NSNull null]]) {
        return 0;
    }
    return self.columnValue.count;
}

// row
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (self.columnValue == nil || [self.columnValue isEqual:[NSNull null]] || component < 0 || self.columnValue.count <= component) {
        return 0;
    }
    return [self.columnValue[component] isEqual:[NSNull null]] ? 0 : [self.columnValue[component] count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (component < 0 || self.columnValue.count <= component) {
        return @"";
    }
    id str = self.columnValue[component][row];
    if ([str isKindOfClass:[NSDictionary class]] && self.key) {
        return [(NSDictionary *)str btd_stringValueForKey:self.key];
    } else if ([str isKindOfClass:[NSString class]]) {
        return (NSString *)str;
    }
    return @"";
}

#pragma mark - delegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if ([self.delegate respondsToSelector:@selector(onPickerColumnChangedWithResult:)]) {
        [self.delegate onPickerColumnChangedWithResult:@{@"value": @(row)}];
    }
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *pickerLabel = (UILabel *)view;
    if(!pickerLabel)
    {
        pickerLabel = [[UILabel alloc] init];
        pickerLabel.adjustsFontSizeToFitWidth = YES;
        pickerLabel.textAlignment = NSTextAlignmentCenter;
    }

    pickerLabel.attributedText = [self pickerView:pickerView attributedTitleForRow:row forComponent:component];
    
    if (self.needUpdate) {
        if (@available(iOS 14.0, *)) {
            if (pickerView.subviews.count >= 1) {
                UIView *preView = [pickerView.subviews objectAtIndex:1];
                preView.clipsToBounds = NO;
                preView.bounds = CGRectMake(0, 0, pickerView.frame.size.width, preView.frame.size.height);
                preView.backgroundColor = [UIColor clearColor];
                UIView *lineViewTop = [[UIView alloc] initWithFrame:CGRectMake(0, preView.frame.origin.y - self.borderWidth, pickerView.frame.size.width, self.borderWidth)];
                lineViewTop.backgroundColor = self.borderColor;
                UIView *lineViewBottom = [[UIView alloc] initWithFrame:CGRectMake(0, preView.frame.origin.y + self.height, pickerView.frame.size.width, [self roundToPhysicalPixel:self.borderWidth])];
                lineViewBottom.backgroundColor = self.borderColor;
                [pickerView addSubview:lineViewTop];
                [pickerView addSubview:lineViewBottom];
                self.needUpdate = NO;
            }
        } else {
            ((UIView *)[pickerView.subviews objectAtIndex:1]).backgroundColor = self.borderColor;
            ((UIView *)[pickerView.subviews objectAtIndex:1]).bounds = CGRectMake(0, 0, pickerView.frame.size.width, self.borderWidth);
            
            ((UIView *)[pickerView.subviews objectAtIndex:2]).backgroundColor = self.borderColor;
            ((UIView *)[pickerView.subviews objectAtIndex:2]).bounds = CGRectMake(0, 0, pickerView.frame.size.width, self.borderWidth);
            self.needUpdate = NO;
        }
    }
    
    return pickerLabel;
}

// Or render pixel may be vary in 3x and 2x screens.
- (CGFloat)roundToPhysicalPixel:(CGFloat)number {
  CGFloat scale = [UIScreen mainScreen].scale;
  number = round(number * scale) / scale;
  return number;
}

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *titleString = [self pickerView:pickerView titleForRow:row forComponent:component];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]initWithString:titleString];
       NSRange range = [titleString rangeOfString:titleString];
       [attributedString addAttribute:NSForegroundColorAttributeName value:self.fontColor range:range];
    [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:self.fontSize weight:self.fontWeight] range:range];
    return attributedString;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return self.height;
}

- (void)reloadPickerFrame
{
    self.pickerView.frame = self.bounds;
    self.needUpdate = YES;
    // FIX iOS9 no autoFresh
    if (@available(iOS 10.0, *)) {
    } else {
      [self.pickerView setNeedsLayout];
    }
}

@end

@interface BDXUIPickerColumnView()<BDXPickerColumnViewDelegate>

@property (nonatomic, copy) NSArray<NSObject *> *columnValue;
@property (nonatomic, copy) NSString *key;
@property (nonatomic) NSInteger index;

@end

@implementation BDXUIPickerColumnView

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-picker-view-column")
#else
LYNX_REGISTER_UI("x-picker-view-column")
#endif

LYNX_PROP_SETTER("range", columnValue, NSArray *)
{
    if (requestReset || !value || [value isEqual:[NSNull null]]) {
      return;
    }
    _columnValue = [value copy];
    self.view.columnValue = [NSArray arrayWithObject:_columnValue];
    [self.view.pickerView reloadAllComponents];
    if (self.index) {
        [self.view.pickerView selectRow:_index inComponent:0 animated:NO];
    }
    
}

LYNX_PROP_SETTER("range-key", key, NSString *)
{
    if (requestReset || !value || [value isEqual:[NSNull null]]) {
      return;
    }
    _key = [value copy];
    self.view.key = _key;
}

LYNX_PROP_SETTER("value", index, NSInteger)
{
    _index = value;
    self.view.index = _index;
    
    if (self.view.columnValue != nil && ![self.view.columnValue isEqual:[NSNull null]]) {
        // select _index row
        [self.view.pickerView selectRow:_index inComponent:0 animated:NO];
    }
}

- (UIView *)createView
{
    BDXPickerColumnView *view = [[BDXPickerColumnView alloc] init];
    view.delegate = self;
    view.clipsToBounds = YES;
    return view;
}

#pragma mark - LynxEvent

- (void)onPickerColumnChangedWithResult:(NSDictionary *)res
{
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"change" targetSign:[self sign] detail:res];
    [self.context.eventEmitter sendCustomEvent:event];
}

@end
