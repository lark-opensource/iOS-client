//
//  BDPPickerView.m
//  TTMicroAppImpl
//
//  Created by MacPu on 2018/12/27.
//

#import "BDPPickerView.h"
#import <OPFoundation/BDPPickerPluginModel.h>
#import <OPFoundation/UIView+BDPExtension.h>
#import <OPFoundation/BDPI18n.h>
#import <OPFoundation/UIColor+EMA.h>
#import <Masonry/Masonry.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>

@interface BDPPickerView()<UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, strong) UIView *background;
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UIPickerView *picker;
@property (nonatomic, assign, readwrite) BDPPickerViewType type;
@property (nonatomic, strong, readwrite) BDPPickerPluginModel *model;
@property (nonatomic, assign, readwrite) BDPPickerViewStyle style;
@end

@implementation BDPPickerView

- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame style:BDPPickerViewStylePicker];
}

- (instancetype)initWithFrame:(CGRect)frame style:(BDPPickerViewStyle)style
{
    self = [super initWithFrame:frame];
    if (self) {
        _style = style;
        [self setupViews];
    }
    return self;
}

- (void)setupViews
{
    _background = [[UIView alloc] initWithFrame:self.bounds];
    _background.backgroundColor = UDOCColor.bgMask;
    _background.alpha = 0.f;
    UITapGestureRecognizer * backgroundGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(cancelButtonOnClick:)];
    [_background addGestureRecognizer:backgroundGesture];

    _picker = [[UIPickerView alloc] initWithFrame:CGRectZero];
    _picker.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _picker.backgroundColor = UDOCColor.bgBody;
    _picker.delegate = self;
    _picker.dataSource = self;

    [_picker sizeToFit];
    _picker.bdp_top = self.bdp_bottom;
    _picker.bdp_width = self.bdp_width;

    _toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.bdp_bottom, self.bdp_width, 40)];
    _toolbar.translucent = NO;
    _toolbar.barTintColor = UDOCColor.bgBody;

    UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithTitle:BDPI18n.cancel style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonOnClick:)];
    [left setTintColor:UDOCColor.primaryPri500];
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithTitle:BDPI18n.confirm style:UIBarButtonItemStylePlain target:self action:@selector(confirmButtonOnClick:)];
    [right setTintColor:UDOCColor.primaryPri500];
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 20;
    if (_style == BDPPickerViewStyleAlert) {
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
    [self addSubview:self.picker];
    [self addSubview:self.toolbar];
    [_background mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self);
    }];
}

- (void)showInView:(UIView *)view
{
    self.style = BDPPickerViewStylePicker;
    [view addSubview:self];
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(view);
    }];
    [UIView animateWithDuration:0.25f animations:^{
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
        // 改用autolayout后，需要调用一次layoutIfNeeded以在动画过程中立即生效
        [self layoutIfNeeded];
    }];
}

- (void)showAlertInView:(UIView *)view
{
    self.style = BDPPickerViewStyleAlert;
    self.background.alpha = 1;
    // 此处逻辑由原始frame布局迁移为autolayout, 布局遵循原始frame布局不变
    [_toolbar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.width.mas_equalTo(self);
        make.height.mas_equalTo(40.0);
    }];
    [_picker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self).offset(20);
        make.width.centerX.mas_equalTo(self);
        make.top.mas_equalTo(_toolbar.mas_bottom);
    }];
    // 改用autolayout后，需要调用一次layoutIfNeeded以在动画过程中立即生效
    [self layoutIfNeeded];
}

- (void)dismiss
{
    if (self.style == BDPPickerViewStyleAlert) {
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
        // 改用autolayout后，需要调用一次layoutIfNeeded以在动画过程中立即生效
        [self layoutIfNeeded];

    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)cancelButtonOnClick:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(didCancelPicker:)]) {
        [self.delegate didCancelPicker:self];
    }
    [self dismiss];
}

- (void)confirmButtonOnClick:(id)sender
{
    NSArray<NSNumber *> *indexs = [self selectedIndexs];
    if ([self.delegate respondsToSelector:@selector(picker:didConfirmOnIndexs:)]) {
        [self.delegate picker:self didConfirmOnIndexs:indexs];
    }
    [self dismiss];
}

- (NSArray<NSNumber *> *)selectedIndexs
{
    NSInteger components = [self.picker numberOfComponents];
    NSMutableArray *indexs = [[NSMutableArray alloc] initWithCapacity:components];

    for (NSInteger i = 0; i < components; i++) {
        [indexs addObject:@([self.picker selectedRowInComponent:i])];
    }

    return [indexs copy];
}

-(CGFloat)componentWidthWithCount:(NSUInteger)count
{
    if (self.model.components.count == 1) {
        return self.bdp_width - 50 * 2;
    }
    else if (self.model.components.count == 2) {
        return (self.bdp_width - 25 * 4 ) / 2;
    }
    else if (self.model.components.count == 3) {
        return (self.bdp_width - 12 * 6) / 3;
    }
    else{
        return self.bdp_width / self.model.components.count;
    }
}

- (void)updateWithModel:(BDPPickerPluginModel *)model
{
    self.model = model;
    self.type = model.components.count == 1 ? BDPPickerViewTypeNormal : BDPPickerViewTypeMulti;

    [self.picker reloadAllComponents];

    [model.selectedRows enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger componentCount = [self.picker numberOfComponents];
        if (idx < componentCount) {
            NSInteger rowNum = [self.picker numberOfRowsInComponent:idx];
            NSInteger index = [obj integerValue];
            if (index >= 0 && index < rowNum) {
                [self.picker selectRow:index inComponent:idx animated:NO];
            }
        }
    }];
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return self.model.components.count;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.model.components[component].count;
}

#pragma mark - UIPickerViewDelegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if ([self.delegate respondsToSelector:@selector(picker:didSelectRow:inComponent:)]) {
        [self.delegate picker:self didSelectRow:row inComponent:component];
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
    fontLabel.textColor = UDOCColor.textTitle;

    UIFont *font = [UIFont systemFontOfSize:18.f];
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
    NSAttributedString *attributesString = [[NSAttributedString alloc] initWithString:self.model.components[component][row] attributes:attributesDictionary];
    fontLabel.attributedText = attributesString;
    [fontLabel sizeToFit];
    CGFloat width = [self componentWidthWithCount:self.model.components.count];
    fontLabel.frame = CGRectMake(0, 0, width, fontLabel.bdp_height);
    return fontLabel;
}

@end
