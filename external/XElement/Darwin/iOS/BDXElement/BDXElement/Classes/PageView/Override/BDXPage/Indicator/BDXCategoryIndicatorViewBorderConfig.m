//
//  BDXCategoryIndicatorViewBorderConfig.m
//  BDXElement
//
//  Created by hanzheng on 2021/2/25.
//

#import "BDXCategoryIndicatorViewBorderConfig.h"

@implementation BDXCategoryIndicatorViewBorderConfig

- (instancetype)init
{
    self = [super init];
    if (self) {
        _width = 100;
        _height = 1;
        _hidden = TRUE;
        _margin = 0;
        _color = [UIColor grayColor];
    }
    return self;
}

@end
