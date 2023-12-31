//
//  BDPreloadDebugView.m
//  BDPreloadSDK
//
//  Created by wealong on 2019/8/28.
//

#import "BDPreloadDebugView.h"

@interface BDPreloadDebugView()

@property (strong, nonatomic) UILabel *finishLabel;
@property (strong, nonatomic) UILabel *runningLabel;
@property (strong, nonatomic) UILabel *pendingLabel;
@property (strong, nonatomic) UILabel *waitingLabel;

@end

@implementation BDPreloadDebugView

+ (instancetype)sharedInstance {
    static BDPreloadDebugView * _sharedInstance;
    if (!self.enable) {
        if (_sharedInstance) {
            [_sharedInstance removeFromSuperview];
            _sharedInstance = nil;
        }
        return nil;
    }
    if (_sharedInstance) {
        
    } else {
        _sharedInstance = [[BDPreloadDebugView alloc] init];
    }
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self _setup];
    }
    return self;
}


- (void)_setup {
    self.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 40 - 44 - ([self.class isIPhoneXSeries] ? 34.0f : 0.f), [UIScreen mainScreen].bounds.size.width, 40);
    self.userInteractionEnabled = NO;
    
    self.finishLabel = [BDPreloadDebugView createLabelWithColor:[UIColor blueColor]];
    [self addSubview:self.finishLabel];
    
    self.runningLabel = [BDPreloadDebugView createLabelWithColor:[UIColor greenColor]];
    CGRect frame = self.runningLabel.frame;
    frame.origin.x = self.finishLabel.frame.origin.x + self.finishLabel.frame.size.width;
    self.runningLabel.frame = frame;
    [self addSubview:self.runningLabel];
    
    self.pendingLabel = [BDPreloadDebugView createLabelWithColor:[UIColor yellowColor]];
    frame = self.pendingLabel.frame;
    frame.origin.x = self.runningLabel.frame.origin.x + self.runningLabel.frame.size.width;
    self.pendingLabel.frame = frame;
    [self addSubview:self.pendingLabel];
    
    self.waitingLabel = [BDPreloadDebugView createLabelWithColor:[UIColor redColor]];
    frame = self.waitingLabel.frame;
    frame.origin.x = self.pendingLabel.frame.origin.x + self.pendingLabel.frame.size.width;
    self.waitingLabel.frame = frame;
    [self addSubview:self.waitingLabel];
    
    UIWindow * win = [[UIApplication sharedApplication] keyWindow];
    [win addSubview:self];
}

+ (UILabel *)createLabelWithColor:(UIColor *)color {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width / 4, 40)];
    
    label.backgroundColor = color;
    label.alpha = 0.5;
    label.textColor = [UIColor blackColor];
    label.textAlignment = NSTextAlignmentCenter;
    return label;
}

+ (BOOL)isIPhoneXSeries {
    BOOL iPhoneXSeries = NO;
    if (@available(iOS 11.0, *)) {
        UIWindow *mainWindow = [[[UIApplication sharedApplication] delegate] window];
        if (mainWindow.safeAreaInsets.bottom > 0.0) {
            iPhoneXSeries = YES;
        }
    }
    return iPhoneXSeries;
}

+ (BOOL)enable {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"kBDPreloadDebugViewShowEnable"];
}

@end
