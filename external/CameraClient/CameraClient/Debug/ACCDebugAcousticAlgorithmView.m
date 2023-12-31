//
//  ACCDebugAcousticAlgorithmView.m
//  CameraClient-Pods-Aweme
//
//  Created by xiafeiyu on 2021/6/6.
//

#if DEBUG || INHOUSE_TARGET

#import "ACCDebugAcousticAlgorithmView.h"

#import "ACCRecorderWrapper+Debug.h"

#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreativeKit/UIImage+ACC.h>
#import <AWELazyRegister/AWELazyRegisterPremain.h>


NSString * const ACCDebugShowAlgoViewKey = @"1";

#if INHOUSE_TARGET
#import <AWELazyRegister/AWELazyRegisterDebugTools.h>
#import <AWEDebugTools/AWEDebugToolsModuleInterface.h>

AWELazyRegisterDebugTools()
{
    AWEDebugBaseModel *model = [[AWEDebugBaseModel alloc] init];
    model.cellName = AWEDebugToolsDebugString(@"音频算法可视化", @"Acoustic Algorithm Visualization");
    model.cellSwitchOn = !![[NSUserDefaults standardUserDefaults] objectForKey:ACCDebugShowAlgoViewKey];
    model.cellType = AWEDebugCellTypeSwitch;
    model.switchDidChangeBlock = ^(BOOL isOn) {
        if (isOn) {
            [ACCDebugAcousticAlgorithmView show];
        } else {
            [ACCDebugAcousticAlgorithmView hide];
        }
    };
    [GET_PROTOCOL(AWEDebugToolsModuleInterface) registerDebugToolsWithCategory:AWEDebugToolsCategoryCommonTools
                                                                         model:model];
}
#endif

static NSString * const AECKey = @"AECEnabled";
static NSString * const DAKey = @"DAEnabled";
static NSString * const LEKey = @"LEEnabled";
static NSString * const EBKey = @"EBEnabled";
static NSString * const DelayKey = @"delay";
static NSString * const LufsKey = @"lufs";
static NSString * const BackendModeKey = @"backendMode";
static NSString * const UseOutputKey = @"useOutput";
static NSString * const ForceRecordAudioKey = @"forceRecordAudio";


static NSInteger const buttonCount = 7;
static CGFloat const buttonWidth = 60;
static CGFloat const buttonHeight = 20;

@interface ACCDebugAcousticAlgorithmView()

@property (nonatomic,strong) UIButton *AECButton;
@property (nonatomic,strong) UIButton *EBButton;
@property (nonatomic,strong) UIButton *LEButton;
@property (nonatomic,strong) UIButton *DAButton;
@property (nonatomic,strong) UIButton *backendModeButton;
@property (nonatomic,strong) UIButton *useOutputButton;
@property (nonatomic,strong) UIButton *forceRecordAudioButton;

@end

@implementation ACCDebugAcousticAlgorithmView

UIWindow* acousticAlgorithmWindow;

AWELazyRegisterPremainClass(ACCDebugAcousticAlgorithmView)
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        UIWindow* win = [UIApplication sharedApplication].keyWindow;
        if ([[NSUserDefaults standardUserDefaults] objectForKey:ACCDebugShowAlgoViewKey] && win) {
            [self show];
        }
    });
}

+ (void)show
{
    if (!acousticAlgorithmWindow) {
        acousticAlgorithmWindow = [[UIWindow alloc] initWithFrame:CGRectMake(16, 200, buttonWidth, buttonHeight * buttonCount)];
        acousticAlgorithmWindow.windowLevel = UIWindowLevelStatusBar + 99;
        [acousticAlgorithmWindow addSubview:[[ACCDebugAcousticAlgorithmView alloc] initWithFrame:CGRectMake(0, 0, buttonWidth, buttonHeight * buttonCount)]];
        acousticAlgorithmWindow.hidden = NO;
        acousticAlgorithmWindow.layer.cornerRadius = 10;
        acousticAlgorithmWindow.layer.masksToBounds = YES;
        acousticAlgorithmWindow.alpha = 0.5;
        acousticAlgorithmWindow.userInteractionEnabled = NO;
        [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:ACCDebugShowAlgoViewKey];
    }
    acousticAlgorithmWindow.hidden = NO;
}

+ (void)hide
{
    acousticAlgorithmWindow.hidden = YES;
    [acousticAlgorithmWindow.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:ACCDebugShowAlgoViewKey];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self = [super initWithFrame:frame]) {
        [self setUpUI];
        [self setUpObservation];
    }
    return self;
}

- (void)dealloc
{
    [[ACCAcousticAlgorithmDebugger sharedInstance] removeObserver:self forKeyPath:AECKey];
    [[ACCAcousticAlgorithmDebugger sharedInstance] removeObserver:self forKeyPath:DAKey];
    [[ACCAcousticAlgorithmDebugger sharedInstance] removeObserver:self forKeyPath:LEKey];
    [[ACCAcousticAlgorithmDebugger sharedInstance] removeObserver:self forKeyPath:EBKey];
    [[ACCAcousticAlgorithmDebugger sharedInstance] removeObserver:self forKeyPath:DelayKey];
    [[ACCAcousticAlgorithmDebugger sharedInstance] removeObserver:self forKeyPath:LufsKey];
    [[ACCAcousticAlgorithmDebugger sharedInstance] removeObserver:self forKeyPath:BackendModeKey];
    [[ACCAcousticAlgorithmDebugger sharedInstance] removeObserver:self forKeyPath:UseOutputKey];
    [[ACCAcousticAlgorithmDebugger sharedInstance] removeObserver:self forKeyPath:ForceRecordAudioKey];
}

- (void)setUpObservation
{
    [[ACCAcousticAlgorithmDebugger sharedInstance] addObserver:self forKeyPath:AECKey options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
    [[ACCAcousticAlgorithmDebugger sharedInstance] addObserver:self forKeyPath:DAKey options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
    [[ACCAcousticAlgorithmDebugger sharedInstance] addObserver:self forKeyPath:LEKey options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
    [[ACCAcousticAlgorithmDebugger sharedInstance] addObserver:self forKeyPath:EBKey options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
    
    
    [[ACCAcousticAlgorithmDebugger sharedInstance] addObserver:self forKeyPath:DelayKey options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
    [[ACCAcousticAlgorithmDebugger sharedInstance] addObserver:self forKeyPath:LufsKey options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
    [[ACCAcousticAlgorithmDebugger sharedInstance] addObserver:self forKeyPath:BackendModeKey options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
    [[ACCAcousticAlgorithmDebugger sharedInstance] addObserver:self forKeyPath:UseOutputKey options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
    [[ACCAcousticAlgorithmDebugger sharedInstance] addObserver:self forKeyPath:ForceRecordAudioKey options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([keyPath isEqualToString:AECKey]) {
            self.AECButton.selected = [ACCAcousticAlgorithmDebugger sharedInstance].AECEnabled;
        } else if ([keyPath isEqualToString:DAKey]) {
            self.DAButton.selected = [ACCAcousticAlgorithmDebugger sharedInstance].DAEnabled;
        } else if ([keyPath isEqualToString:LEKey]) {
            self.LEButton.selected = [ACCAcousticAlgorithmDebugger sharedInstance].LEEnabled;
        } else if ([keyPath isEqualToString:EBKey]) {
            self.EBButton.selected = [ACCAcousticAlgorithmDebugger sharedInstance].EBEnabled;
        } else if ([keyPath isEqualToString:DelayKey]) {
            [self.DAButton setTitle:[NSString stringWithFormat:@"DA %.1f", [ACCAcousticAlgorithmDebugger sharedInstance].delay] forState:UIControlStateNormal];
        } else if ([keyPath isEqualToString:LufsKey]) {
            [self.LEButton setTitle:[NSString stringWithFormat:@"LE %d", [ACCAcousticAlgorithmDebugger sharedInstance].lufs] forState:UIControlStateNormal];
        } else if ([keyPath isEqualToString:BackendModeKey]) {
            NSMutableArray *tags = [NSMutableArray array];
            VERecorderBackendMode backendMode = [ACCAcousticAlgorithmDebugger sharedInstance].backendMode;
            BOOL selected = NO;
            if (backendMode & VERecorderBackendMode_Mic) {
                [tags addObject:@"mic"];
                selected = YES;
            }
            if (backendMode & VERecorderBackendMode_Bgm) {
                [tags addObject:@"bgm"];
                selected = YES;
            }
            [self.backendModeButton setTitle:[tags componentsJoinedByString:@","] forState:UIControlStateSelected];
            self.backendModeButton.selected = selected;
        } else if ([keyPath isEqualToString:UseOutputKey]) {
            self.useOutputButton.selected = [ACCAcousticAlgorithmDebugger sharedInstance].useOutput;
        } else if ([keyPath isEqualToString:ForceRecordAudioKey]) {
            self.forceRecordAudioButton.selected = [ACCAcousticAlgorithmDebugger sharedInstance].forceRecordAudio;
        }
    });
}

- (void)setUpUI;
{
    [self addSubview:self.AECButton];
    [self addSubview:self.DAButton];
    [self addSubview:self.LEButton];
    [self addSubview:self.EBButton];
    [self addSubview:self.backendModeButton];
    [self addSubview:self.useOutputButton];
    [self addSubview:self.forceRecordAudioButton];
}

- (UIButton *)AECButton
{
    if (!_AECButton) {
        _AECButton = [self buttonWithFrame:CGRectMake(0, buttonHeight * 0, buttonWidth, buttonHeight) title:@"AEC"];
    }
    return _AECButton;
}

- (UIButton *)DAButton
{
    if (!_DAButton) {
        _DAButton = [self buttonWithFrame:CGRectMake(0, buttonHeight * 1, buttonWidth, buttonHeight) title:@"DA"];
    }
    return _DAButton;
}

- (UIButton *)LEButton
{
    if (!_LEButton) {
        _LEButton  = [self buttonWithFrame:CGRectMake(0, buttonHeight * 2, buttonWidth, buttonHeight) title:@"LE"];
    }
    return _LEButton;
}

- (UIButton *)EBButton
{
    if (!_EBButton) {
        _EBButton = [self buttonWithFrame:CGRectMake(0, buttonHeight * 3, buttonWidth, buttonHeight) title:@"EB"];
    }
    return _EBButton;
}

- (UIButton *)backendModeButton
{
    if (!_backendModeButton) {
        _backendModeButton = [self buttonWithFrame:CGRectMake(0, buttonHeight * 4, buttonWidth, buttonHeight) title:@"None"];
    }
    return _backendModeButton;
}

- (UIButton *)useOutputButton
{
    if (!_useOutputButton) {
        _useOutputButton = [self buttonWithFrame:CGRectMake(0, buttonHeight * 5, buttonWidth, buttonHeight) title:@"useOutput"];
    }
    return _useOutputButton;
}

- (UIButton *)forceRecordAudioButton
{
    if (!_forceRecordAudioButton) {
        _forceRecordAudioButton = [self buttonWithFrame:CGRectMake(0, buttonHeight * 6, buttonWidth, buttonHeight) title:@"forceAudio"];
    }
    return _forceRecordAudioButton;
}

- (UIButton *)buttonWithFrame:(CGRect)frame title:(NSString *)title
{
    UIButton *button  = [[UIButton alloc] initWithFrame:frame];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    [button setBackgroundImage:[UIImage acc_imageFromColor:UIColor.systemBlueColor size:CGSizeMake(buttonWidth, buttonHeight)] forState:UIControlStateSelected];
    [button setBackgroundImage:[UIImage acc_imageFromColor:UIColor.blackColor size:CGSizeMake(buttonWidth, buttonHeight)] forState:UIControlStateNormal];
    return button;
}

@end

#endif
