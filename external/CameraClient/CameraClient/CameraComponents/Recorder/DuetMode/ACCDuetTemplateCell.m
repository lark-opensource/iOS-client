//
//  ACCDuetTemplateCell.m
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/10/20.
//

#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCColorNameDefines.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCDuetTemplateCell.h"
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreationKitArch/ACCAwemeModelProtocol.h>
#import <CameraClient/ACCAwemeModelProtocolD.h>
#import "ACCDuetAmountView.h"

@interface ACCDuetTemplateCell()

@property (nonatomic, strong) id<ACCAwemeModelProtocolD> templateModel;
@property (nonatomic, strong) ACCDuetAmountView *amountView;

@end

@implementation ACCDuetTemplateCell

#pragma mark - Class Methods

+ (NSString *)cellIdentifier
{
    static NSString *cellIdentifier = nil;
    if (!cellIdentifier) {
        cellIdentifier = NSStringFromClass([self class]);
    }
    return cellIdentifier;
}

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupViews];
    }
    return self;
}

- (void)updateWithTemplateModel:(id<ACCAwemeModelProtocolD>)templateModel
{
    self.templateModel = templateModel;
    [ACCWebImage() imageView:self.coverImageView setImageWithURLArray:templateModel.video.dynamicCover.URLList.count ? templateModel.video.dynamicCover.URLList : templateModel.video.coverURL.URLList];
    if (templateModel.duetCount > 0) {
        self.amountView.hidden = NO;
        self.amountView.text = [ACCDuetAmountView usageAmountString:templateModel.duetCount];
    } else {
        self.amountView.hidden = YES;
    }
}

#pragma mark - Getters

- (UIImageView *)coverImageView
{
    if (!_coverImageView) {
        _coverImageView = [ACCWebImage() animatedImageView];
        _coverImageView.backgroundColor = ACCResourceColor(ACCColorBGCreation);
        _coverImageView.clipsToBounds = YES;
        _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _coverImageView;
}

- (ACCDuetAmountView *)amountView
{
    if (!_amountView) {
        _amountView = [[ACCDuetAmountView alloc] initWithFrame:CGRectZero];
    }
    return _amountView;
}

#pragma mark - Private

- (void)p_setupViews
{
    self.contentView.backgroundColor = ACCResourceColor(ACCColorBGCreation);
    self.contentView.layer.cornerRadius = 8.0f;
    self.contentView.layer.masksToBounds = YES;
    
    [self.contentView addSubview:self.coverImageView];
    ACCMasMaker(self.coverImageView, {
        make.edges.equalTo(self.contentView);
    });
    
    CAGradientLayer *gradient = [[CAGradientLayer alloc] init];
        gradient.frame = CGRectMake(0, self.contentView.frame.size.height - 50, self.contentView.frame.size.width, 50);
        gradient.colors = @[
            (__bridge id)UIColor.clearColor.CGColor,
            (__bridge id)[UIColor colorWithWhite:0 alpha:0.34].CGColor,
        ];
        gradient.locations = @[@(0), @(1)];
        [self.contentView.layer addSublayer:gradient];
    
    [self.contentView addSubview:self.amountView];
    ACCMasMaker(self.amountView, {
        make.left.equalTo(self.contentView).offset(8);
        make.bottom.equalTo(self.contentView).offset(-8);
    })
}
@end
