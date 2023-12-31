//
//  BDXCategoryListContainerRTLCell.m
//  BDXCategoryView
//
//  Created by jiaxin on 2020/7/3.
//

#import "BDXCategoryListContainerRTLCell.h"
#import "BDXRTLManager.h"

@implementation BDXCategoryListContainerRTLCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [BDXRTLManager horizontalFlipViewIfNeeded:self];
        [BDXRTLManager horizontalFlipViewIfNeeded:self.contentView];
    }
    return self;
}

@end
