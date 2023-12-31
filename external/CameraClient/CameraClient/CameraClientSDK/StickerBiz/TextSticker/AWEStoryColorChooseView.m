//
//  AWEStoryColorChooseView.m
//  AWEStudio
//
//  Created by hanxu on 2018/11/19.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEStoryColorChooseView.h"
#import <Masonry/View+MASAdditions.h>
#import <CreativeKit/ACCMacros.h>

static const CGFloat colorWidth = 24;
static const CGFloat colorHeight = 24;
static const CGFloat lineHalfWidth = 1;

@interface AWEStoryColorCollectionViewCell :UICollectionViewCell

@property (nonatomic, strong) UIView *backColorView;
@property (nonatomic, strong) UIView *colorView;

@property (nonatomic, strong) void (^didClickColorView)(AWEStoryColorCollectionViewCell *cell);
@property (nonatomic, strong) AWEStoryColor *color;
@property (nonatomic, copy) NSDictionary *colorNameDict;

@end

@implementation AWEStoryColorCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self.contentView addSubview:self.backColorView];
        [self.contentView addSubview:self.colorView];

        self.backColorView.layer.cornerRadius = colorWidth * 0.5;
        self.backColorView.frame = CGRectMake(self.frame.size.width * 0.5 - colorWidth * 0.5, self.frame.size.height * 0.5 - colorHeight * 0.5, colorWidth, colorHeight);
        
        CGRect rect = CGRectInset(self.backColorView.frame, lineHalfWidth * 2, lineHalfWidth * 2);
        self.colorView.layer.cornerRadius = (colorWidth - lineHalfWidth * 2 * 2) * 0.5;
        self.colorView.frame = rect;
    }
    return self;
}

- (UIView *)backColorView
{
    if (!_backColorView) {
        _backColorView = [[UIView alloc] init];
        _backColorView.backgroundColor = [UIColor whiteColor];
        _backColorView.clipsToBounds = YES;
    }
    return _backColorView;
}

- (UIView *)colorView
{
    if (_colorView == nil) {
        _colorView = [[UIView alloc] init];
        _colorView.clipsToBounds = YES;
    }
    return _colorView;
}

- (void)setColor:(AWEStoryColor *)color
{
    _color = color;
    [self.colorView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.colorView.backgroundColor = color.color;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    CGFloat colorWidth = selected ? 28 : 24;
    CGFloat colorHeight = colorWidth;
    
    [UIView animateWithDuration:0.2 animations:^{
        self.backColorView.layer.cornerRadius = colorWidth * 0.5;
        self.backColorView.frame = CGRectMake(self.frame.size.width * 0.5 - colorWidth * 0.5, self.frame.size.height * 0.5 - colorHeight * 0.5, colorWidth, colorHeight);
        
        CGRect rect = CGRectInset(self.backColorView.frame, lineHalfWidth * 2, lineHalfWidth * 2);
        self.colorView.layer.cornerRadius = (colorWidth - lineHalfWidth * 2 * 2) * 0.5;
        self.colorView.frame = rect;
    }];
}

#pragma mark - Accessibility
- (BOOL)isAccessibilityElement
{
    return YES;
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitNone | UIAccessibilityTraitStaticText;
}

- (NSString *)accessibilityLabel
{
    NSString *colorStr = ACCDynamicCast(self.colorNameDict[self.color.colorString], NSString);
    NSString *isSelectedStr = self.isSelected ? @"已选中" : @"未选中";
    return [NSString stringWithFormat:@"%@, %@", isSelectedStr, colorStr];
}

- (NSDictionary *)colorNameDict
{
    if (!_colorNameDict) {
        _colorNameDict = @{
            @"0xFFFFFF" : @"白色",
            @"0x000000" : @"黑色",
            @"0xEA4040" : @"红色",
            @"0xFF933D" : @"橙色",
            @"0xF2CD46" : @"黄色",
            @"0xFFFCDB" : @"米黄色",
            @"0x78C25E" : @"绿色",
            @"0x78C8A6" : @"浅绿色",
            @"0x3596F0" : @"浅蓝色",
            @"0x2444B3" : @"深蓝色",
            @"0x5756D5" : @"紫色",
            @"0xF8D7E9" : @"粉色",
            @"0xA4895B" : @"棕色",
            @"0x32523C" : @"深绿色",
            @"0x2F698D" : @"湖蓝色",
            @"0x92979E" : @"浅灰色",
            @"0x333333" : @"深灰色",
        };
    }
    return _colorNameDict;
}

@end


@interface AWEStoryColorChooseView () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) AWEStoryColor *selectedColor;

@end

@implementation AWEStoryColorChooseView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.itemSize = CGSizeMake(colorWidth + 13.5, colorWidth + 12);
        layout.minimumInteritemSpacing = 0;
        layout.minimumLineSpacing = 0;
        self.collectionView = [[UICollectionView alloc] initWithFrame:frame collectionViewLayout:layout];
        self.collectionView.delegate = self;
        self.collectionView.dataSource = self;
        self.collectionView.backgroundColor = [UIColor clearColor];
        self.collectionView.alwaysBounceVertical = NO;
        self.collectionView.alwaysBounceHorizontal = YES;
        self.collectionView.showsVerticalScrollIndicator = NO;
        self.collectionView.showsHorizontalScrollIndicator = NO;
        self.collectionView.scrollEnabled = YES;
        [self.collectionView registerClass:[AWEStoryColorCollectionViewCell class] forCellWithReuseIdentifier:@"AWEStoryPenColorCollectionViewCell"];
        [self addSubview:self.collectionView];
        ACCMasMaker(self.collectionView, {
            make.edges.equalTo(self);
        });
        [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        self.selectedColor = self.storyColors.firstObject;
    }
    return self;
}

- (void)dealloc
{
    _collectionView.delegate = nil;
    _collectionView.dataSource = nil;
    _collectionView = nil;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.storyColors.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    AWEStoryColorCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AWEStoryPenColorCollectionViewCell" forIndexPath:indexPath];
    cell.color = self.storyColors[indexPath.row];
    return cell;
}

- (void)selectWithIndexPath:(NSIndexPath *)indexPath
{
    AWEStoryColor *storyColor = [self.storyColors objectAtIndex:indexPath.row];
    if (self.didSelectedColorBlock) {
        self.didSelectedColorBlock(storyColor, indexPath);
    }
    self.selectedColor = storyColor;
}

- (void)updateSelectedColorWithIndexPath:(NSIndexPath *)indexPath
{
    AWEStoryColor * storyColor = [self.storyColors objectAtIndex:indexPath.row];
    self.selectedColor = storyColor;
}

- (void)selectWithColor:(UIColor *)color
{
    if ([self isColor:color equalTo:self.selectedColor.color]) {
        return;
    }

    [self.collectionView layoutIfNeeded];
    __block NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.storyColors enumerateObjectsUsingBlock:^(AWEStoryColor *obj, NSUInteger idx, BOOL *stop) {
        if ([self isColor:color equalTo:obj.color]) {
            indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
        }
    }];
    [self selectWithIndexPath:indexPath];
    [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{    
    [self selectWithIndexPath:indexPath];
    
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
}

- (NSArray<AWEStoryColor *> *)storyColors
{
    return [[self class] storyColors];
}

+ (NSArray<AWEStoryColor *> *)storyColors
{
    return @[
        [AWEStoryColor colorWithTextColorHexString:@"0xFFFFFF" borderColorHexString:@"0x000000"],
        [AWEStoryColor colorWithTextColorHexString:@"0x000000" borderColorHexString:@"0xFFFFFF"],
        [AWEStoryColor colorWithTextColorHexString:@"0xEA4040" borderColorHexString:@"0xFFFFFF"],
        [AWEStoryColor colorWithTextColorHexString:@"0xFF933D" borderColorHexString:@"0x481606"],
        [AWEStoryColor colorWithTextColorHexString:@"0xF2CD46" borderColorHexString:@"0x000000"],
        [AWEStoryColor colorWithTextColorHexString:@"0xFFFCDB" borderColorHexString:@"0xFFFFFF"],
        [AWEStoryColor colorWithTextColorHexString:@"0x78C25E" borderColorHexString:@"0xFFFFFF"],
        [AWEStoryColor colorWithTextColorHexString:@"0x78C8A6" borderColorHexString:@"0xFFFFFF"],
        [AWEStoryColor colorWithTextColorHexString:@"0x3596F0" borderColorHexString:@"0xFFFFFF"],
        [AWEStoryColor colorWithTextColorHexString:@"0x2444B3" borderColorHexString:@"0xF2CD46"],
        [AWEStoryColor colorWithTextColorHexString:@"0x5756D5" borderColorHexString:@"0xFFFFFF"],
        [AWEStoryColor colorWithTextColorHexString:@"0xF8D7E9" borderColorHexString:@"0xD26793"],
        [AWEStoryColor colorWithTextColorHexString:@"0xA4895B" borderColorHexString:@"0xFFFFFF"],
        [AWEStoryColor colorWithTextColorHexString:@"0x32523C" borderColorHexString:@"0xFFFFFF"],
        [AWEStoryColor colorWithTextColorHexString:@"0x2F698D" borderColorHexString:@"0xFFFFFF"],
        [AWEStoryColor colorWithTextColorHexString:@"0x92979E" borderColorHexString:@"0xFFFFFF"],
        [AWEStoryColor colorWithTextColorHexString:@"0x333333" borderColorHexString:@"0xFFFFFF"],
    ];
}

#pragma mark - privtae methods

- (BOOL)isColor:(UIColor *)firstColor equalTo:(UIColor *)secondColor
{
    CGFloat red1Value, green1Value, blue1Value, alpha1Value, red2Value, green2Value, blue2Value, alpha2Value;
    [firstColor getRed:&red1Value green:&green1Value blue:&blue1Value alpha:&alpha1Value];
    [secondColor getRed:&red2Value green:&green2Value blue:&blue2Value alpha:&alpha2Value];
    return (fabs(red1Value - red2Value) <= 0.01 && fabs(green1Value - green2Value) <= 0.01 && fabs(blue1Value - blue2Value) <= 0.01 && fabs(alpha1Value - alpha2Value) <= 0.01);
}

@end
