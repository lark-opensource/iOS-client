//
//  EMAPageIndcatorView.m
//  TTMicroApp
//
//  Created by yinyuan on 2018/12/13.
//

#import "EMAPageIndcatorView.h"

@interface EMAPageIndcatorView ()

@property (nonatomic, strong) NSMutableArray<CALayer *> *dotLayers;

@end

@implementation EMAPageIndcatorView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _selectedColor = [UIColor colorWithWhite:1 alpha:0.8];
    _unselectedColor = [UIColor colorWithWhite:1 alpha:0.5];
    _dotSize = 6;
    _dotMargin = 6;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat leftFrom = (self.frame.size.width - (self.totalPage * self.dotSize + (self.totalPage-1) * self.dotMargin))/2;
    CGFloat topFrom = (self.frame.size.height - self.dotSize)/2;
    for (NSUInteger i = 0; i < self.totalPage; i++) {
        CALayer *layer = [self dotLayerAtIndex:i];
        layer.hidden = self.hideDotsWhenOnlyOnePage&&self.totalPage<=1?YES:NO;
        layer.frame = CGRectMake(leftFrom + i * (self.dotSize + self.dotMargin), topFrom, self.dotSize, self.dotSize);
        layer.backgroundColor = (i==self.currentPage?self.selectedColor:self.unselectedColor).CGColor;
        layer.cornerRadius = self.dotSize/2;
        layer.shadowOffset = CGSizeMake(1, 1);
        layer.shadowColor = UIColor.blackColor.CGColor;
        layer.shadowOpacity = 0.2;
    }
    for (NSUInteger i = self.totalPage; i < self.dotLayers.count; i++) {
        CALayer *layer = [self dotLayerAtIndex:i];
        layer.hidden = YES;
    }
}

- (CALayer *)dotLayerAtIndex:(NSUInteger)index {
    if (!self.dotLayers) {
        self.dotLayers = [NSMutableArray array];
    }
    if (index >= self.dotLayers.count) {
        for (NSUInteger i = self.dotLayers.count; i <= index; i++) {
            CALayer *layer = [[CALayer alloc] init];
            [self.layer addSublayer:layer];
            [self.dotLayers addObject:layer];
        }
    }
    return self.dotLayers[index];
}

- (void)setDotSize:(CGFloat)dotSize {
    if (_dotSize != dotSize) {
        _dotSize = dotSize;
        [self setNeedsLayout];
    }
}

- (void)setDotMargin:(CGFloat)dotMargin {
    if (_dotMargin != dotMargin) {
        _dotMargin = dotMargin;
        [self setNeedsLayout];
    }
}

- (void)setTotalPage:(NSUInteger)totalPage {
    if (_totalPage != totalPage) {
        _totalPage = totalPage;
        [self setNeedsLayout];
    }
}

- (void)setCurrentPage:(NSUInteger)currentPage {
    if (_currentPage != currentPage) {
        _currentPage = currentPage;
        [self setNeedsLayout];
    }
}

- (void)setSelectedColor:(UIColor *)selectedColor {
    if (_selectedColor != selectedColor) {
        _selectedColor = selectedColor;
        [self setNeedsLayout];
    }
}

- (void)setUnselectedColor:(UIColor *)unselectedColor {
    if (_unselectedColor != unselectedColor) {
        _unselectedColor = unselectedColor;
        [self setNeedsLayout];
    }
}

- (void)setHideDotsWhenOnlyOnePage:(BOOL)hideDotsWhenOnlyOnePage {
    if (_hideDotsWhenOnlyOnePage != hideDotsWhenOnlyOnePage) {
        _hideDotsWhenOnlyOnePage = hideDotsWhenOnlyOnePage;
        [self setNeedsLayout];
    }
}

@end
