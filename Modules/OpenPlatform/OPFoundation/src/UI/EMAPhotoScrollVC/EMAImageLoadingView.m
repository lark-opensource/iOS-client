//
//  EMAImageLoadingView.m
//  Article
//
//  Created by Huaqing Luo on 15/4/15.
//
//

#import "EMAImageLoadingView.h"
#import <OPFoundation/UIView+BDPExtension.h>
#import <OPFoundation/UIImage+EMA.h>

@interface EMAImageLoadingView ()

@property(nonatomic, assign) NSUInteger percent;
@property(nonatomic, strong, readwrite) UILabel * percentLabel;

@end

@implementation EMAImageLoadingView

- (instancetype)initWithFrame:(CGRect)frame
{
    frame.size = CGSizeMake(32, 32);
    self = [super initWithFrame:frame];
    if (self) {
        [self.percentLabel setText:[NSString stringWithFormat:@"%d%%", 0]];
        [self.percentLabel sizeToFit];
        self.percentLabel.center = CGPointMake(self.bdp_width / 2.f, self.bdp_height / 2.f);

    }
    return self;
}

#pragma mark -- Setters/Getters

- (void)setLoadingProgress:(CGFloat)loadingProgress
{
    loadingProgress = MAX(loadingProgress, 0);
    loadingProgress = MIN(loadingProgress, 1.f);

    if (_loadingProgress != loadingProgress) {
        _loadingProgress = loadingProgress;
        NSUInteger percent = (NSUInteger)(_loadingProgress * 100);
        self.percent = percent;
    }
}

- (void)setPercent:(NSUInteger)percent
{
    if (_percent != percent) {
        _percent = percent;
        [self.percentLabel setText:[NSString stringWithFormat:@"%ld%%", (unsigned long)_percent]];
        [self.percentLabel sizeToFit];
        _percentLabel.center = CGPointMake(self.bdp_width / 2.f, self.bdp_height / 2.f);
    }
}

- (UILabel *)percentLabel
{
    if (!_percentLabel) {
        _percentLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [_percentLabel setFont:[UIFont boldSystemFontOfSize:14]];
        [_percentLabel setTextColor:[UIColor whiteColor]];
        [_percentLabel setTextAlignment:NSTextAlignmentCenter];
        _percentLabel.backgroundColor = [UIColor clearColor];
        _percentLabel.shadowColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        _percentLabel.shadowOffset = CGSizeMake(1, 1);
        _percentLabel.center = CGPointMake(self.bdp_width / 2.f, self.bdp_height / 2.f);
        [self addSubview:_percentLabel];
    }
    
    return _percentLabel;
}

@end
