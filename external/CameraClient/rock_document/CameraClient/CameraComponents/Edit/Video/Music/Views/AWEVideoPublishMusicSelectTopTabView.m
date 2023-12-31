//
//  AWEVideoPublishMusicSelectTopTabView.m
//  Pods
//
//  Created by resober on 2019/5/22.
//

#import "AWEVideoPublishMusicSelectTopTabView.h"
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCFontProtocol.h>

@interface AWEVideoPublishMusicSelectTopTabItemData ()

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) UIColor *titleColor;
@property (nonatomic, strong) UIColor *unselectColor;
@property (nonatomic, strong) UIFont *titleFont;
@property (nonatomic, strong) UIFont *unselectTitleFont;

@end

/* AWEVideoPublishMusicSelectTopTabItemData */

@implementation AWEVideoPublishMusicSelectTopTabItemData

- (instancetype)initWithTitle:(NSString *)title {
    self = [super init];
    if (self) {
        _title = title;
        self.titleColor = ACCResourceColor(ACCColorConstTextInverse);
        self.titleFont = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightMedium];
        self.unselectTitleFont = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightMedium];
        self.unselectColor = ACCResourceColor(ACCUIColorConstTextInverse3);
        self.titleTopOffset = 0;
        self.buttonLeftOffset = 0;
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title isLightStyle:(BOOL)isLightStyle {
    self = [super init];
    if (self) {
        _title = title;
        if (isLightStyle) {
            self.titleColor = ACCResourceColor(ACCColorConstTextInverse);
            self.titleFont = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightMedium];
            self.unselectTitleFont = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightMedium];
            self.unselectColor = ACCResourceColor(ACCUIColorConstTextInverse3);
            self.titleTopOffset = 0;
            self.buttonLeftOffset = 0;
        } else {
            self.titleColor = ACCResourceColor(ACCColorTextReverse);
            self.unselectColor = ACCResourceColor(ACCColorTextReverse3);
            self.unselectTitleFont = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightRegular];
            self.titleFont = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightMedium];
            self.titleTopOffset = 0;
            self.buttonLeftOffset = 0;
        }
    }
    return self;
}

@end

static const CGFloat kLineHeight = 21.f;
static const CGFloat kLabelAndUnderLineGap = 9.f;
static const CGFloat kUnderlineHeight = 2.f;

/* AWEVideoPublishMusicSelectTopTabItemView */

@interface AWEVideoPublishMusicSelectTopTabItemView() {
    CGFloat _titleLabelWidth;
}
/// 用来响应整个点击事件的按钮
@property (nonatomic, strong) UIButton *maskButton;
@property (nonatomic, strong) UILabel *titleLable;
@property (nonatomic, strong) UIView *underLineView;
@property (nonatomic, strong) AWEVideoPublishMusicSelectTopTabItemData *itemData;
@end

@implementation AWEVideoPublishMusicSelectTopTabItemView
- (instancetype)initWithItemData:(AWEVideoPublishMusicSelectTopTabItemData *)itemData {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _itemData = itemData;
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    if (!_itemData || _itemData.title.length == 0) {
        return;
    }
    _titleLable = [[UILabel alloc] init];
    UIFont *font = nil;
    CGFloat fontSize = 15.f;
    if (_itemData.titleFont) {
        font = _itemData.titleFont;
    } else {
        font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightMedium];
    }
    
    _titleLable.font = font;
    _titleLable.numberOfLines = 1;
    [self addSubview:_titleLable];
    _titleLable.text = _itemData.title;
    _titleLabelWidth = [_titleLable sizeThatFits:CGSizeMake(CGFLOAT_MAX, kLineHeight)].width;
    _titleLable.frame = CGRectMake(0, 0, _titleLabelWidth, kLineHeight);

    CGFloat underlineSpace = ACC_FLOAT_EQUAL_TO(_itemData.underlineSpace, 0.f) ?  kLabelAndUnderLineGap : _itemData.underlineSpace;
    _underLineView = [[UIView alloc] initWithFrame:CGRectMake(0, _titleLable.frame.size.height + _titleLable.frame.origin.y + underlineSpace, _titleLabelWidth, kUnderlineHeight)];
    _underLineView.backgroundColor = _itemData.titleColor;
    _underLineView.layer.masksToBounds = YES;
    _underLineView.layer.cornerRadius = 1.8;
    [self addSubview:_underLineView];

    _maskButton = [[UIButton alloc] init];
    _maskButton.backgroundColor = [UIColor clearColor];
    [_maskButton addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_maskButton];

    [self refresh];
    
    [self p_setupAccessibility];
}

- (void)layoutSubviews {
    _maskButton.frame = CGRectMake(0, 0, self.bounds.size.width + _itemData.buttonLeftOffset + 11, self.bounds.size.height + _itemData.titleTopOffset);
    _titleLable.frame = CGRectMake(_itemData.buttonLeftOffset, _itemData.titleTopOffset, self.bounds.size.width, kLineHeight);
    _underLineView.frame = CGRectMake(_itemData.buttonLeftOffset, _titleLable.frame.size.height + _titleLable.frame.origin.y + kLabelAndUnderLineGap, self.bounds.size.width, kUnderlineHeight);
}

- (void)refresh {
    _titleLable.textColor = _itemData.selected ? _itemData.titleColor : _itemData.unselectColor;
    _titleLable.font = _itemData.selected ? _itemData.titleFont : _itemData.unselectTitleFont;
    _underLineView.hidden = !_itemData.selected;
    [self setNeedsDisplay];
}

- (void)buttonClicked:(UIButton *)sender {
    if (self.clickBlock) {
        self.clickBlock(self.itemData);
    }
}

- (CGSize)intrinsicContentSize {
    if (!_itemData) {
        return CGSizeZero;
    }
    return CGSizeMake(_titleLabelWidth, kLineHeight + kLabelAndUnderLineGap + kUnderlineHeight);
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (view == nil) {
        for (UIView *subView in self.subviews) {
            CGPoint p = [subView convertPoint:point fromView:self];
            if (CGRectContainsPoint(subView.bounds, p)) {
                view = subView;
            }
        }
    }
    return view;
}

#pragma mark - UIAccessibility

- (void)p_setupAccessibility
{
    self.isAccessibilityElement = NO;
    self.maskButton.isAccessibilityElement = YES;
    self.maskButton.accessibilityTraits = UIAccessibilityTraitButton;
    self.maskButton.accessibilityLabel = self.titleLable.text;
    self.maskButton.accessibilityViewIsModal = YES;
}

@end

/* AWEVideoPublishMusicSelectTopTabView */

static const CGFloat kItemHoriGap = 27.f;

@interface AWEVideoPublishMusicSelectTopTabView() {
    CGFloat _calcedInnerWidth;
}
@property (nonatomic, strong) NSArray<AWEVideoPublishMusicSelectTopTabItemData *> *items;
@property (nonatomic, strong) NSArray<AWEVideoPublishMusicSelectTopTabItemView *> *views;
@end

@implementation AWEVideoPublishMusicSelectTopTabView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (view == nil) {
        for (UIView *subView in self.subviews) {
            CGPoint p = [subView convertPoint:point fromView:self];
            if (CGRectContainsPoint(subView.bounds, p)) {
                view = subView;
            }
        }
    }
    return view;
}

- (instancetype)initWithItems:(NSArray<AWEVideoPublishMusicSelectTopTabItemData *> *)items {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _items = items;
        [self setupViews];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    @weakify(self);
    __block CGFloat x = 0;
    CGFloat width = self.frame.size.width;
    [self.views enumerateObjectsUsingBlock:^(AWEVideoPublishMusicSelectTopTabItemView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @strongify(self);
        if (idx >= self.items.count) {
            *stop = YES;
            return;
        }
        CGFloat w = MIN(width - x, obj.intrinsicContentSize.width);
        obj.frame = CGRectMake(x, 0, w, obj.intrinsicContentSize.height);
        x += w + kItemHoriGap;
    }];
}

- (void)setupViews {
    if (!_items || _items.count == 0) {
        return;
    }
    NSMutableArray *mViewsArray = [[NSMutableArray alloc] initWithCapacity:_items.count];
    __block CGFloat x = 0;
    [_items enumerateObjectsUsingBlock:^(AWEVideoPublishMusicSelectTopTabItemData * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == 0 && _items.count > 1) {
            obj.selected = YES;
        } else {
            obj.selected = NO;
        }
        AWEVideoPublishMusicSelectTopTabItemView *tmp = [[AWEVideoPublishMusicSelectTopTabItemView alloc] initWithItemData:obj];
        [self addSubview:tmp];
        tmp.frame = CGRectMake(x, 0, tmp.intrinsicContentSize.width, tmp.intrinsicContentSize.height);
        __weak typeof(self) weakSelf = self;
        if (_items.count > 1) {
            [tmp setClickBlock:^(AWEVideoPublishMusicSelectTopTabItemData * _Nonnull itemData) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (itemData.selectedBlock) {
                    itemData.selectedBlock();
                }
                [strongSelf refreshWithClickedItemData:itemData];
            }];
        }
        // 预先计算下一个item的x坐标
        x += (tmp.intrinsicContentSize.width + kItemHoriGap);
        [mViewsArray addObject:tmp];
        if (idx == _items.count - 1) {
            _calcedInnerWidth = x - kItemHoriGap;
        }
    }];
    _views = mViewsArray;
}

- (void)refreshWithClickedItemData:(AWEVideoPublishMusicSelectTopTabItemData *)itemData {
    [_views enumerateObjectsUsingBlock:^(AWEVideoPublishMusicSelectTopTabItemView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.itemData == itemData) {
            obj.itemData.selected = YES;
        } else {
            obj.itemData.selected = NO;
        }
        [obj refresh];
    }];
}

- (CGSize)intrinsicContentSize {
    if (!_items || _items.count == 0 || !_views || _views.count == 0) {
        return CGSizeZero;
    }
    // view都是等高，只是长度不同
    CGFloat h = _views.firstObject.intrinsicContentSize.height;
    CGFloat w = _calcedInnerWidth;
    return CGSizeMake(w, h);
}

- (void)setItemClicked:(AWEVideoPublishMusicSelectTopTabItemData *)item {
    if (![self.items containsObject:item] || self.items.count <= 1) {
        return;
    }
    [self refreshWithClickedItemData:item];
}

@end
