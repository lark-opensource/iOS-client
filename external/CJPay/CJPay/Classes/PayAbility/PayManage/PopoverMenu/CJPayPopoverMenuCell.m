//
//  CJPayPopoverMenuCell.m
//  Pods
//
//  Created by 易培淮 on 2021/3/17.
//

#import "CJPayPopoverMenuCell.h"
#import <ByteDanceKit/UIDevice+BTDAdditions.h>
#import "CJPayUIMacro.h"

@interface CJPayPopoverMenuCell ()

@property (nonatomic, strong) UIView *separatorView;

@end

@implementation CJPayPopoverMenuCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.textLabel.backgroundColor = [UIColor whiteColor];
        self.textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    return self;
}

- (void)setSeparatorViewHidden:(BOOL)isHidden {
    [self.separatorView setHidden:isHidden];
}

#pragma mark - Getter

- (UIView *)separatorView {
    if(!_separatorView) {
        _separatorView = [UIView new];
    }
    return _separatorView;
}

#pragma mark - UITableViewCell

- (void)prepareForReuse {
    [super prepareForReuse];
    self.separatorView.hidden = NO;
}

@end


