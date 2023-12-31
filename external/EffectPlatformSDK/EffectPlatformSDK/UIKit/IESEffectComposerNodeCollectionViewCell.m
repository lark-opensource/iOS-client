//
//  IESEffectComposerNodeCollectionViewCell.m
//  Pods
//
//  Created by stanshen on 2018/10/8.
//

#import "IESEffectComposerNodeCollectionViewCell.h"
#import <Masonry.h>

@interface IESEffectComposerNodeCollectionViewCell()
@property (nonatomic, strong) UILabel *titleLabel;
@end
@implementation IESEffectComposerNodeCollectionViewCell


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.titleLabel];
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        self.layer.borderColor = [UIColor whiteColor].CGColor;
    }
    return self;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.layer.borderWidth = selected ? 1.0 : 0.0;
}

-(void)renderWithTitle:(NSString *)title {
    self.titleLabel.text = title;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.numberOfLines = 0;
        _titleLabel.text = @"xxxx";
    }
    return _titleLabel;
}


@end
