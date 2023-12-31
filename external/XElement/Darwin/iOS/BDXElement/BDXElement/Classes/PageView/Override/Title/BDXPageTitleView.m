//
//  BDXPageBaseView.m
//  BDXElement
//
//  Created by AKing on 2021/2/6.
//

#import "BDXPageTitleView.h"
#import "BDXCategoryTitleView.h"

@interface BDXPageTitleView ()


@end

@implementation BDXPageTitleView

#pragma mark - View life cycle

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {

    }
    
    return self;
}

- (void)setTitles:(NSArray *)titles {
    [super setTitles:titles];
    self.myCategoryView.titles = titles;
}

- (BDXCategoryTitleView *)myCategoryView {
    return (BDXCategoryTitleView *)self.categoryView;
}

- (BDXCategoryBaseView *)preferredCategoryView {
    return [[BDXCategoryTitleView alloc] init];
}

@end
