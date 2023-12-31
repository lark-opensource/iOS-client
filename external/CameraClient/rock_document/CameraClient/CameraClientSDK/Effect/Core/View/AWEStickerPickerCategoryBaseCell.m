//
//  AWEStickerPickerCategoryBaseCell.m
//  Pods
//
//  Created by Chipengliu on 2020/8/20.
//

#import "AWEStickerPickerCategoryBaseCell.h"

@implementation AWEStickerPickerCategoryBaseCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor clearColor];
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)categoryDidUpdate {}

@end
