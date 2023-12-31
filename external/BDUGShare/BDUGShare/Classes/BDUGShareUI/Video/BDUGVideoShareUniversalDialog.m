//
//  BDUGVideoShareUniversalDialog.m
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/5/17.
//

#import "BDUGVideoShareUniversalDialog.h"
#import "UIColor+UGExtension.h"
#import <ByteDanceKit/UIView+BTDAdditions.h>

@implementation BDUGVideoShareDialogInfo

@end

@interface BDUGVideoShareUniversalDialog ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *tipsLabel;

@end

@implementation BDUGVideoShareUniversalDialog

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        [self addSubview:self.titleLabel];
        [self addSubview:self.tipsLabel];
    }
    return self;
}

- (void)refreshContent:(BDUGVideoShareDialogInfo *)contentModel
{
    self.titleLabel.text = contentModel.titleString;
    self.tipsLabel.text = contentModel.tipString;
    [self refreshFrame];
}

- (void)refreshFrame
{
    self.titleLabel.frame = CGRectMake(0, 0, self.frame.size.width, 25);
    self.tipsLabel.frame = CGRectMake(22, self.titleLabel.btd_bottom + 13, self.btd_width - 2 * 22, 42);
}

#pragma mark -

- (UILabel *)titleLabel {
    if (_titleLabel == nil) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont boldSystemFontOfSize:19];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.textColor = [UIColor colorWithHexString:@"222222"];
    }
    return _titleLabel;
}

- (UILabel *)tipsLabel {
    if (_tipsLabel == nil) {
        _tipsLabel = [UILabel new];
        _tipsLabel.font = [UIFont systemFontOfSize:15];
        _tipsLabel.textColor = [UIColor colorWithHexString:@"505050"];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _tipsLabel.numberOfLines = 2;
    }
    return _tipsLabel;
}

@end
