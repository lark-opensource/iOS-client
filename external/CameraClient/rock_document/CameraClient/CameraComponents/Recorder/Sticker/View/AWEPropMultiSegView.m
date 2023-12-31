//
//  AWEPropMultiSegView.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/1/18.
//

#import "AWEPropMultiSegView.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>

#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>

@interface AWEPropMultiSegView()

@end

@implementation AWEPropMultiSegView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews
{
    UIImageView *bottomImageView = [[UIImageView alloc] init];
    bottomImageView.contentMode = UIViewContentModeScaleAspectFill;
    bottomImageView.layer.masksToBounds = YES;
    bottomImageView.layer.cornerRadius = 4.0f;
    [self addSubview:bottomImageView];
    ACCMasMaker(bottomImageView, {
        make.edges.equalTo(self);
    });
    _bottomImageView = bottomImageView;
    
    UIView *grayCoverView = [[UIView alloc] init];
    [self addSubview:grayCoverView];
    grayCoverView.layer.masksToBounds = YES;
    grayCoverView.layer.cornerRadius = 4.0f;
    grayCoverView.layer.borderWidth = 2.0f;
    grayCoverView.layer.borderColor = ACCResourceColor(ACCColorConstTextInverse).CGColor;
    grayCoverView.backgroundColor = ACCResourceColor(ACCColorTextReverse4);
    ACCMasMaker(grayCoverView, {
        make.edges.equalTo(self);
    });
    _grayCoverView = grayCoverView;
    
    UIImageView *completeImageView = [[UIImageView alloc] init];
    completeImageView.image = ACCResourceImage(@"iconCheck");
    completeImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:completeImageView];
    ACCMasMaker(completeImageView, {
        make.center.equalTo(self);
        make.width.height.equalTo(@12);
    });
    _completeImageView = completeImageView;

    UILabel *secondsLabel = [[UILabel alloc] init];
    secondsLabel.font = [UIFont fontWithName:@"PingFang SC" size:10.0];
    secondsLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
    [self addSubview:secondsLabel];
    ACCMasMaker(secondsLabel, {
        make.center.equalTo(self);
    });
    _secondsLabel = secondsLabel;
}

- (void)setState:(AWEPropMultiSegViewState)state
{
    switch (state) {
        case AWEPropMultiSegViewStateNone: {
            self.alpha = 0.34;
            self.transform = CGAffineTransformMakeScale(1, 1);
            self.bottomImageView.image = nil;
            self.completeImageView.alpha = 0.f;
            self.secondsLabel.alpha = 1.f;
            break;
        }
            
        case AWEPropMultiSegViewStateProcessing: {
            self.alpha = 1.f;
            self.transform = CGAffineTransformMakeScale(1.1, 1.1);
            self.bottomImageView.image = nil;
            self.completeImageView.alpha = 0.f;
            self.secondsLabel.alpha = 1.f;
            break;
        }
            
        case AWEPropMultiSegViewStateCompleted: {
            self.alpha = 1.f;
            self.transform = CGAffineTransformMakeScale(1, 1);
            self.completeImageView.alpha = 1.f;
            self.secondsLabel.alpha = 0.f;
            break;
        }
    }
}

@end
