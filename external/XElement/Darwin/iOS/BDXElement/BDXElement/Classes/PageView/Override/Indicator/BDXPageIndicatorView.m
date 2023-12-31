//
//  BDXPageBaseView.m
//  BDXElement
//
//  Created by AKing on 2021/2/6.
//

#import "BDXPageIndicatorView.h"
#import "BDXCategoryTitleView.h"

@interface BDXPageIndicatorView ()

@property (nonatomic, strong) BDXCategoryIndicatorLineView *indicatorLineView;

@end

@implementation BDXPageIndicatorView

#pragma mark - View life cycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.myCategoryView.titleColor = [UIColor grayColor];
        self.myCategoryView.titleSelectedColor = [UIColor redColor];
        self.myCategoryView.titleColorGradientEnabled = YES;
        self.myCategoryView.titleLabelZoomEnabled = YES;
        BDXCategoryIndicatorLineView *lineView = [[BDXCategoryIndicatorLineView alloc] init];
        lineView.indicatorWidth = 20;
        lineView.indicatorColor = [UIColor colorWithRed:105/255.0 green:144/255.0 blue:239/255.0 alpha:1];
        self.myCategoryView.indicators = @[lineView];
        self.indicatorLineView = lineView;
    }
    return self;
}

- (void)setTitles:(NSArray *)titles {
    [super setTitles:titles];
    self.myCategoryView.titles = titles;
}

- (void)hideIndicatorLine: (BOOL)hidden {
    self.myCategoryView.indicators = hidden ? @[] : @[self.indicatorLineView];
}

- (BDXCategoryTitleView *)myCategoryView {
    return (BDXCategoryTitleView *)self.categoryView;
}

- (BDXCategoryBaseView *)preferredCategoryView {
    return [[BDXCategoryTitleView alloc] init];
}
@end
