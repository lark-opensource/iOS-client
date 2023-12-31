//
//  ACCFlowerPropPanelView.m
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/11/12.
//


#import "ACCFlowerPropPanelView.h"
#import "ACCGradientView.h"

#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <KVOController/KVOController.h>
#import "ACCFlowerCampaignManagerProtocol.h"

@interface ACCFlowerTaskEntryView: UIView

@property (nonatomic, strong) ACCGradientView *gradientView;
@property (nonatomic, strong) UIImageView *taskEntryIcon;
@property (nonatomic, strong) UILabel *taskEntryLabel;
@property (nonatomic, strong) UIView *leftSpacer;
@property (nonatomic, strong) UIImageView *arrowIcon;
@property (nonatomic, strong) UIView *rightSpacer;

- (void)updateEntryText:(NSString *)entryText;
- (NSString *)taskEntryText;

@end

@implementation ACCFlowerTaskEntryView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.userInteractionEnabled = YES;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.gradientView = [[ACCGradientView alloc] init];
        self.gradientView.gradientLayer.colors = @[
         (__bridge id)[ACCUIColorFromRGBA(0xFFEBCE, 1.0) CGColor],
         (__bridge id)[ACCUIColorFromRGBA(0xFFF9EE, 1.0) CGColor]];

        self.gradientView.gradientLayer.startPoint = CGPointMake(.5f, 1.0f);
        self.gradientView.gradientLayer.endPoint = CGPointMake(.5f, .0f);
        self.gradientView.layer.cornerRadius = 16.0f;
        self.gradientView.layer.masksToBounds = YES;
        [self addSubview:self.gradientView];
        
        self.taskEntryIcon = [[UIImageView alloc] initWithImage: ACCResourceImage(@"ic_flower_task_entry")];
        [self addSubview:self.taskEntryIcon];
        
        self.taskEntryLabel = [[UILabel alloc] init];
        self.taskEntryLabel.adjustsFontSizeToFitWidth = NO;
        self.taskEntryLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        self.taskEntryLabel.textAlignment = NSTextAlignmentLeft;
        self.taskEntryLabel.textColor = ACCUIColorFromRGBA(0xfe2c55, 1.0);
        self.taskEntryLabel.font = [ACCFont() acc_boldSystemFontOfSize:14];
        [self addSubview:self.taskEntryLabel];
        
        self.leftSpacer = [[UIView alloc] init];
        self.leftSpacer.backgroundColor = [UIColor clearColor];
        self.rightSpacer = [[UIView alloc] init];
        self.rightSpacer.backgroundColor = [UIColor clearColor];
        
        [self addSubview:self.leftSpacer];
        [self addSubview:self.rightSpacer];

        self.arrowIcon = [[UIImageView alloc] initWithImage: ACCResourceImage(@"ic_flower_task_arrow")];
        self.arrowIcon.alpha = .6f;
        [self addSubview:self.arrowIcon];
        
        ACCMasReMaker(self.gradientView, {
            make.leading.equalTo(self.mas_leading);
            make.top.equalTo(self.mas_top);
            make.trailing.equalTo(self.mas_trailing);
            make.bottom.equalTo(self.mas_bottom);
        });
        
        ACCMasReMaker(self.leftSpacer, {
            make.leading.equalTo(self.mas_leading);
            make.top.equalTo(self.mas_top);
            make.bottom.equalTo(self.mas_bottom);
            make.width.mas_equalTo(15);
        });
        
        ACCMasReMaker(self.taskEntryIcon, {
            make.leading.equalTo(self.leftSpacer.mas_trailing).offset(0.5f);
            make.width.mas_equalTo(17);
            make.height.mas_equalTo(17);
            make.centerY.equalTo(self.mas_centerY).offset(-0.5f);
        });
        
        ACCMasReMaker(self.taskEntryLabel, {
            make.leading.equalTo(self.taskEntryIcon.mas_trailing).offset(4);
            make.top.equalTo(self.mas_top);
            make.bottom.equalTo(self.mas_bottom);;
        });
        
        ACCMasReMaker(self.arrowIcon, {
            make.leading.equalTo(self.taskEntryLabel.mas_trailing).offset(4);
            make.width.mas_equalTo(12);
            make.height.mas_equalTo(12);
            make.centerY.equalTo(self.mas_centerY);
        });
        
        ACCMasReMaker(self.rightSpacer, {
            make.leading.equalTo(self.arrowIcon.mas_trailing).offset(4);
            make.top.equalTo(self.mas_top);
            make.bottom.equalTo(self.mas_bottom);
            make.trailing.equalTo(self.mas_trailing);
            make.width.mas_equalTo(8);
        });
    }
    return self;
}

- (void)updateEntryText:(NSString *)entryText
{
    if(ACC_isEmptyString(entryText)) return;
    self.taskEntryLabel.text = entryText;
}

- (NSString *)taskEntryText
{
    return self.taskEntryLabel.text;
}

@end

@interface ACCFlowerPropPanelView ()

@property (nonatomic, strong) ACCAnimatedButton *closeButton;
@property (nonatomic, strong) ACCFlowerTaskEntryView *taskEntryView;

@end

@implementation ACCFlowerPropPanelView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        backgroundView.backgroundColor = [UIColor clearColor];
        [self addSubview:backgroundView];
        ACCMasMaker(backgroundView, {
            make.height.mas_equalTo(ACC_IPHONE_X_BOTTOM_OFFSET + 54);
            make.left.right.bottom.mas_equalTo(@0);
        });
        _backgroundView = backgroundView;
        
        _panelView = [[ACCFlowerScrollPropPanelView alloc] init];
        _exposePanGestureRecognizer = [[ACCExposePanGestureRecognizer alloc] initWithTarget:self action:@selector(onGestureRecognizer:)];
        _panelView.exposePanGestureRecognizer = _exposePanGestureRecognizer;
        @weakify(self);
        _panelView.didTakePictureBlock = ^{
            @strongify(self);
            ACCBLOCK_INVOKE(self.didTakePictureBlock);
        };

        [self addSubview:_panelView];
        ACCMasMaker(_panelView, {
            make.left.right.equalTo(@0);
            make.height.mas_equalTo(@80);
            make.top.mas_equalTo(@(self.recordButtonTop));
        })
        
        _taskEntryView = [[ACCFlowerTaskEntryView alloc] initWithFrame:CGRectZero];
        _taskEntryView.hidden = [ACCFlowerCampaignManager() getCurrentActivityStage] != ACCFLOActivityStageTypeLuckyCard;
        if ([ACCFlowerCampaignManager() audit]) {
            _taskEntryView.hidden = YES;
        }
        _taskEntryView.isAccessibilityElement = YES;
        _taskEntryView.accessibilityLabel = [_taskEntryView taskEntryText];
        _taskEntryView.accessibilityTraits = UIAccessibilityTraitButton;
        [self addSubview:_taskEntryView];
        
        UITapGestureRecognizer *flowerEntryTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(taskEntryTapped)];
        [_taskEntryView addGestureRecognizer:flowerEntryTapGesture];

        _closeButton = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeScale];
        [_closeButton setImage:ACCResourceImage(@"ic_submode_close_button") forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
        _closeButton.isAccessibilityElement = YES;
        _closeButton.accessibilityLabel = @"关闭";
        _closeButton.accessibilityTraits = UIAccessibilityTraitButton;
        [self addSubview:_closeButton];
        ACCMasMaker(_closeButton, {
            make.size.mas_equalTo(CGSizeMake(48, 48));
            make.centerX.mas_equalTo(@0);
            make.bottom.mas_equalTo(@(2 - ACC_IPHONE_X_BOTTOM_OFFSET));
        });
        
    }
    return self;
}

- (void)setPanelViewModel:(ACCFlowerPropPanelViewModel *)panelViewModel
{
    _panelViewModel = panelViewModel;
    [self.KVOController unobserveAll];
    @weakify(self);
    [self.KVOController observe:panelViewModel keyPath:FBKVOKeyPath(_panelViewModel.items) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        @strongify(self);
        self.taskEntryView.hidden = self.panelViewModel.items.count > 0;
    }];
}

- (void)setRecordButtonTop:(CGFloat)recordButtonTop
{
    _recordButtonTop = recordButtonTop;
    ACCMasReMaker(self.panelView, {
        make.left.right.equalTo(@0);
        make.height.mas_equalTo(@80);
        make.top.mas_equalTo(@(self.recordButtonTop));
    })
}

- (void)setTaskEntryViewBottom:(CGFloat)taskEntryViewBottom
{
    _taskEntryViewBottom = taskEntryViewBottom;
    ACCMasReMaker(self.taskEntryView, {
        make.bottom.equalTo(self.superview.mas_top).offset(taskEntryViewBottom - 8);
        make.centerX.equalTo(self);
        make.height.equalTo(@(32));
    });
}

- (void)onGestureRecognizer:(ACCExposePanGestureRecognizer *)gesture
{
    
}

- (void)reloadScrollPanel
{
    [self.panelView reloadScrollPanel];
}

- (void)close
{
    if (self.closeButtonClickCallback) {
        self.closeButtonClickCallback();
    }
}

- (void)taskEntryTapped
{
    if (self.entryButtonClickCallback) {
        self.entryButtonClickCallback();
        [self.panelViewMdoel flowerTrackForEnterTaskEntryView];
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    if (view == self && point.y < self.panelView.acc_top) {
        return nil;
    }
    return view;
}

- (void)updateEntryText:(NSString *)entryText
{
    [self.taskEntryView updateEntryText:entryText];
}

@end

