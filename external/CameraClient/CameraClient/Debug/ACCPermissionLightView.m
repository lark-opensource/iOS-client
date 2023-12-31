//
//  ACCPermissionLightView.m
//  CameraClientTikTok
//
//  Created by wishes on 2020/8/10.
//

#if DEBUG || INHOUSE_TARGET
#import <HTSServiceKit/HTSBootInterface.h>
#import "ACCPermissionLightView.h"
#import "ACCPermissionLight.h"

#if INHOUSE_TARGET
#import <AWELazyRegister/AWELazyRegisterDebugTools.h>
#import <AWEDebugTools/AWEDebugToolsModuleInterface.h>

AWELazyRegisterDebugTools()
{
    AWEDebugBaseModel *model = [[AWEDebugBaseModel alloc] init];
    model.cellName = AWEDebugToolsDebugString(@"音视频权限可视化", @"Video & Audio Permission Light");
    model.cellSwitchOn = !![[NSUserDefaults standardUserDefaults] objectForKey:@"show_permission_light_key"];
    model.cellType = AWEDebugCellTypeSwitch;
    model.switchDidChangeBlock = ^(BOOL isOn) {
        if (isOn) {
            [ACCPermissionLightView show];
        } else {
            [ACCPermissionLightView hide];
        }
    };
    [GET_PROTOCOL(AWEDebugToolsModuleInterface) registerDebugToolsWithCategory:AWEDebugToolsCategoryCommonTools
                                                                         model:model];
}
#endif

#define PERMISSION_RECORD_AU_PATH @"recordAU"
#define PERMISSION_IS_RECORD_VIDEO_PATH @"isRecordingVideo"
#define SHOW_PERMISSION_LIGHT_KEY @"show_permission_light_key"

@interface ACCPermissionLightView ()

@property (nonatomic,strong) UIButton* videoLight;

@property (nonatomic,strong) UIButton* audioLight;

@end


@implementation ACCPermissionLightView

UIWindow* window;

+ (void)show {
    if (!window) {
        window = [[UIWindow alloc] initWithFrame:CGRectMake(16, 100, 40, 80)];
        window.windowLevel = UIWindowLevelStatusBar + 99;
        [window addSubview:[[ACCPermissionLightView alloc] initWithFrame:CGRectMake(0, 0, 40, 80)]];
        window.hidden = NO;
        window.layer.cornerRadius = 10;
        window.layer.masksToBounds = YES;
        window.alpha = 0.5;
        window.userInteractionEnabled = NO;
        [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:SHOW_PERMISSION_LIGHT_KEY];
    }
    window.hidden = NO;
}

+ (void)hide {
    window.hidden = YES;
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SHOW_PERMISSION_LIGHT_KEY];
}

+ (void)load {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidFinishLaunching) name:UIApplicationDidFinishLaunchingNotification object:nil];
    HTSBootRunLaunchCompletion(HTSBootThreadMain, ^{
        [ACCPermissionLight acc_load];
        [AVCaptureSession acc_load];
    });
}

+ (void)appDidFinishLaunching {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([UIApplication sharedApplication].keyWindow != nil) {
            if ([[NSUserDefaults standardUserDefaults] objectForKey:SHOW_PERMISSION_LIGHT_KEY] ) { 
                [ACCPermissionLightView show];
            }
        }
    });
}


- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setUpLights];
        [self setUpListener];
    }
    return self;
}

- (void)setUpLights {
    [self addSubview:self.videoLight];
    [self addSubview:self.audioLight];
}

- (void)setUpListener {
    [[ACCPermissionLight shareInstance] addObserver:self forKeyPath:PERMISSION_IS_RECORD_VIDEO_PATH options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
    [[ACCPermissionLight shareInstance] addObserver:self forKeyPath:PERMISSION_RECORD_AU_PATH options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
}

- (UIButton *)audioLight {
    if (!_audioLight) {
        _audioLight = [self createAudioLight];
    }
    return _audioLight;
}

- (UIButton *)createAudioLight {
    __auto_type audioL = [[UIButton alloc] init];
    [audioL setTitle:@"A" forState:UIControlStateNormal];
    audioL.backgroundColor = UIColor.greenColor;
    return audioL;
}

- (UIButton *)videoLight {
    if (!_videoLight) {
        _videoLight = [[UIButton alloc] init];
        [_videoLight setTitle:@"V" forState:UIControlStateNormal];
        _videoLight.backgroundColor = UIColor.grayColor;
    }
    return _videoLight;
}

- (void)layoutSubviews {
    self.videoLight.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height / 2.0);
    self.audioLight.frame = CGRectMake(0, self.bounds.size.height / 2.0, self.bounds.size.width, self.bounds.size.height / 2.0);
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([keyPath isEqualToString:PERMISSION_IS_RECORD_VIDEO_PATH]) {
            if ([change[NSKeyValueChangeNewKey] boolValue]) {
                self.videoLight.backgroundColor = [UIColor redColor];
            } else {
                self.videoLight.backgroundColor = [UIColor greenColor];
            }
            
        } else if ([keyPath isEqualToString:PERMISSION_RECORD_AU_PATH]) {
            NSValue* value = change[NSKeyValueChangeNewKey];
            struct RECORD_AU AU;
            [value getValue:&AU];
            UIButton* AUView = [self viewWithTag:AU.AU];
            if (!AU.isRecording) {
                [AUView removeFromSuperview];
            } else {
                if (AUView) {
                    [self bringSubviewToFront:AUView];
                    return;
                }
                UIButton* al = [self createAudioLight];
                al.tag = AU.AU;
                al.frame = self.audioLight.frame;
                al.backgroundColor = [UIColor redColor];
                [self addSubview:al];
            }
        }
    });
}

- (void)dealloc {
    [[ACCPermissionLight shareInstance] removeObserver:self forKeyPath:PERMISSION_IS_RECORD_VIDEO_PATH];
    [[ACCPermissionLight shareInstance] removeObserver:self forKeyPath:PERMISSION_RECORD_AU_PATH];
}


@end

#endif
