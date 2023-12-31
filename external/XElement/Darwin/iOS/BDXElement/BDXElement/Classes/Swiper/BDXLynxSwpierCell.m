//
//  BDXLynxSwpierCell.m
//  BDAlogProtocol
//
//  Created by bill on 2020/3/20.
//

#import "BDXLynxSwpierCell.h"
#import <UIKit/UIKit.h>
#import <Lynx/LynxUI.h>

@implementation BDXLynxSwpierCell

- (id)init {
    if (self = [super init]) {
        self.ui = nil;
    }
    return self;
}

- (void)addContent:(UIView*)view {
    if (nil != view) {
        [self.contentView addSubview:view];
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

@end
