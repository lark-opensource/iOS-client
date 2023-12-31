//
//  CJPayIndicatorView.m
//  CJPay
//
//  Created by 王新华 on 2019/5/5.
//

#import "CJPayIndicatorView.h"
#import "CJPayUIMacro.h"

@interface CJPayIndicatorView()

@property (nonatomic, strong) NSMutableArray<UIImageView *> *indicatorViews;
@property (nonatomic, strong) UIImage *curImage;
@property (nonatomic, strong) UIImage *noCurImage;

@end

@implementation CJPayIndicatorView

- (instancetype)init
{
    self = [super init];
    if (self) {
        _curImage = [UIImage cj_imageWithColor:[UIColor cj_ffffffWithAlpha: 1]];
        _noCurImage = [UIImage cj_imageWithColor:[UIColor cj_ffffffWithAlpha: 0.34]];
        _indicatorViews = [NSMutableArray new];
        _spacing = 10;
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    return self.cj_size;
}

- (CGFloat)itemSize {
    return MIN(self.cj_width, self.cj_height);
}

- (void)rebuildIndicatorView:(NSInteger)count {
    if (count < 2) {
        return;
    }
    [self cj_removeAllSubViews];
    [self.indicatorViews removeAllObjects];
    
    CGSize itemSize = CGSizeMake(self.itemSize, self.itemSize);
    CGFloat startX = (self.cj_width - (_spacing + itemSize.width) * count + _spacing) / 2;
    CGFloat startY = (self.cj_height - itemSize.height) / 2;
    
    for (int i = 0; i < count; i++) {
        UIImageView *iImageView = [UIImageView new];
        iImageView.clipsToBounds = YES;
        iImageView.image = _noCurImage;
        iImageView.frame = CGRectMake(startX, startY, itemSize.width, itemSize.height);
        iImageView.layer.cornerRadius = itemSize.width / 2;
        startX  = startX + itemSize.width + _spacing;
        [self addSubview:iImageView];
        [_indicatorViews addObject:iImageView];
    }
}

- (void)configCount:(NSInteger)count {
    [self rebuildIndicatorView:count];
}

- (void)didScrollTo:(NSInteger)index {
    if (index >= _indicatorViews.count || index < 0) {
        return;
    }
    [_indicatorViews enumerateObjectsUsingBlock:^(UIImageView * _Nonnull  obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.image = self.noCurImage;
    }];
    _indicatorViews[index].image = _curImage;
}

@end
