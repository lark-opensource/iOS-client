//
//  ACCCreativeBrightnessABUtil.m
//  CameraClient-Pods-Aweme
//
//  Created by liumiao on 2021/3/31.
//

#import "ACCCreativeBrightnessABUtil.h"
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitInfra/ACCConfigManager.h>
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/NSTimer+ACCAdditions.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreativeKit/ACCResourceBundleProtocol.h>
#import <CreativeKit/ACCMacros.h>

static const NSInteger kACCCreativeBrightnessAdjustFrame = 15;
static const CFTimeInterval kACCCreativeBrightnessAdjustInterval = 0.5;

@interface ACCCreativeBrightnessABUtil()

@property (nonatomic, strong) NSNumber *originalSystemBrightness; // record brightness when system brightness changed or brightness changed by userinteract
@property (nonatomic, strong) NSNumber *recentCreativeBrightness; // record brightness when enter background

@property (nonatomic, strong, readwrite) NSNumber *currentBrightness; // record brightness for business track
@property (nonatomic, assign) BOOL hasChangedOriginalValue; // has changed due to user interact or environment change

// new ab
@property (nonatomic, assign) BOOL brightnessABSwitch;
@property (nonatomic, assign) BOOL enableAdjustBrightness;
@property (nonatomic, assign) CGFloat lowLevelAdjustRange;
@property (nonatomic, assign) CGFloat highLevelAdjustRange;
@property (nonatomic, assign) CGFloat lowLevelAdjustGap;
@property (nonatomic, assign) CGFloat highLevelAdjustGap;
@property (nonatomic, assign) CGFloat ratioInEdit;
@property (nonatomic, assign) CGFloat ratioInPublish;

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation ACCCreativeBrightnessABUtil

+ (instancetype)shareBrightnessManager
{
    static dispatch_once_t onceToken;
    static ACCCreativeBrightnessABUtil *manager;
    dispatch_once(&onceToken, ^{
        if (!manager) {
            manager = [[ACCCreativeBrightnessABUtil alloc] init];
        }
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self updateABValue];
    }
    return self;
}

- (void)updateABValue
{
    NSDictionary *dic = ACCConfigDict(kConfigDict_studio_screen_brightness_adjust);
    self.brightnessABSwitch = [dic acc_boolValueForKey:@"enable"];
    self.lowLevelAdjustRange = [dic acc_intValueForKey:@"low_adjust_range"] / 100.f;
    self.lowLevelAdjustGap = [dic acc_intValueForKey:@"low_adjust_gap"] / 100.f;
    self.highLevelAdjustRange = [dic acc_intValueForKey:@"high_adjust_range"] / 100.f;
    self.highLevelAdjustGap = [dic acc_intValueForKey:@"high_adjust_gap"] / 100.f;
    self.ratioInEdit = [dic acc_floatValueForKey:@"ratio_in_Edit"];
    self.ratioInPublish = [dic acc_floatValueForKey:@"ratio_in_publish"];
}

- (void)adjustBrightnessWhenEnterCreationLine
{
    [self changeBrightnessWithRatio:1.0f];
    [self logWithInfo:[NSString stringWithFormat:@"Brightness Util enter record"]];
}

- (void)resumeBrightnessWhenEnterEditor
{
    [self changeBrightnessWithRatio:self.ratioInEdit];
    [self logWithInfo:[NSString stringWithFormat:@"Brightness Util enter edit"]];
}

- (void)resumeBrightnessWhenEnterPublish
{
    BOOL dark = [IESAutoInline(ACCBaseServiceProvider(), ACCResourceBundleProtocol) isDarkMode];
    [self changeBrightnessWithRatio:dark ? self.ratioInPublish : 0.f];
    [self logWithInfo:[NSString stringWithFormat:@"Brightness Util enter publish"]];
}

- (void)restoreBrightness
{
    if (self.enableAdjustBrightness && self.originalSystemBrightness) {
        [self exitCreative];
    }
}

- (NSNumber *)currentBrightness {
    if (_currentBrightness) {
        return _currentBrightness;
    }
    return @([UIScreen mainScreen].brightness);
}

#pragma mark - notification

- (void)enterBackground:(NSNotification *)noti {
    if (self.originalSystemBrightness) {
        [self realChangeBrightness:[self.originalSystemBrightness floatValue]];
    }
    [self logWithInfo:[NSString stringWithFormat:@"Brightness Util enter background"]];
}

- (void)enterForeground:(NSNotification *)noti {
    if (self.recentCreativeBrightness) {
        [self realChangeBrightness:self.recentCreativeBrightness.floatValue];
    }
    [self logWithInfo:[NSString stringWithFormat:@"Brightness Util enter foreground"]];
}

- (void)brightnessDidChange:(NSNotification *)notification {
    UIApplicationState state = [UIApplication sharedApplication].applicationState;
    if (state == UIApplicationStateActive) {
        self.originalSystemBrightness = @([UIScreen mainScreen].brightness);
        [self logWithInfo:[NSString stringWithFormat:@"Brightness Util original change : %@", @([UIScreen mainScreen].brightness)]];
    } else {
        self.hasChangedOriginalValue = YES;
        [self logWithInfo:[NSString stringWithFormat:@"Brightness Util back change : %@", @([UIScreen mainScreen].brightness)]];
    }
}

#pragma mark - private

- (void)enterCreative {
    CGFloat brightness = [UIScreen mainScreen].brightness;
    self.enableAdjustBrightness = self.brightnessABSwitch && brightness < self.highLevelAdjustRange;
    if (self.enableAdjustBrightness) {
        self.originalSystemBrightness = @(brightness);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(brightnessDidChange:) name:UIScreenBrightnessDidChangeNotification object:[UIScreen mainScreen]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackground:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [self logWithInfo:[NSString stringWithFormat:@"Brightness Util enter : %@", self.originalSystemBrightness]];
    }
}

- (void)exitCreative {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self realChangeBrightness:[self.originalSystemBrightness floatValue]];
    self.originalSystemBrightness = nil;
    self.hasChangedOriginalValue = NO;
    self.currentBrightness = nil;
    [self logWithInfo:[NSString stringWithFormat:@"Brightness Util exit"]];
}

- (void)changeBrightnessWithRatio:(CGFloat)ratio {
    if (!self.originalSystemBrightness) {
        [self enterCreative];
    }
    if (!self.enableAdjustBrightness) {
        return;
    }
    CGFloat original = [self.originalSystemBrightness floatValue];
    if (original >= 0.f) {
        CGFloat adjust = 0.f;
        if (original <= self.lowLevelAdjustRange) {
            adjust = self.lowLevelAdjustGap;
        } else if (original <= self.highLevelAdjustRange) {
            adjust = self.highLevelAdjustGap * (1 - (original - self.lowLevelAdjustRange) / (self.highLevelAdjustRange - self.lowLevelAdjustRange));
        }
        self.recentCreativeBrightness = @(original + adjust * ratio);
        [self realChangeBrightness:self.recentCreativeBrightness.floatValue];
    }
}

- (void)realChangeBrightness:(CGFloat)brightness
{
    if (![self shouldChangeBrightnessInCreative]) {
        return;
    }
    if (![self brightnessValueValid:brightness]) {
        return;
    }
    
    [self logWithInfo:[NSString stringWithFormat:@"Brightness Util set : %@", @(brightness)]];
    acc_dispatch_main_async_safe(^{
        self.currentBrightness = @(brightness);
        
        CFTimeInterval interval = kACCCreativeBrightnessAdjustInterval / kACCCreativeBrightnessAdjustFrame;
        CGFloat gapPerLoop = (brightness - [UIScreen mainScreen].brightness) / kACCCreativeBrightnessAdjustFrame;
        __block NSInteger frame = kACCCreativeBrightnessAdjustFrame;
        [self.timer invalidate];
        self.timer = [NSTimer acc_scheduledTimerWithTimeInterval:interval block:^(NSTimer * _Nonnull timer) {
            if (frame <= 0) {
                [timer invalidate];
                return;
            }
            [UIScreen mainScreen].brightness += gapPerLoop;
            frame -= 1;
        } repeats:YES];
    });
}

- (BOOL)brightnessValueValid:(CGFloat)value {
    return value >= 0.0 && value <= 1.0;
}

- (BOOL)shouldChangeBrightnessInCreative {
    return self.enableAdjustBrightness && !self.hasChangedOriginalValue;
}

- (void)logWithInfo:(NSString *)info {
    if (self.enableAdjustBrightness && info.length > 0) {
        AWELogToolInfo(AWELogToolTagRecord, @"%@", info);
    }
}

@end
