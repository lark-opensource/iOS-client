//
//  FaceLiveViewController+Audio.m
//  byted_cert
//
//  Created by liuminghui.2022 on 2023/2/3.
//

#import "FaceLiveViewController+Audio.h"
#import "BDCTAudioPlayer.h"

#import <MediaPlayer/MPVolumeView.h>
#import <objc/runtime.h>


@interface FaceLiveViewController ()

@property (nonatomic, strong) MPVolumeView *volumeView;

@property (nonatomic, strong) BDCTAudioPlayer *audioPlayer;

@end


@implementation FaceLiveViewController (Audio)

- (void)setOpenAudio:(BOOL)openAudio {
    objc_setAssociatedObject(self, @selector(openAudio), @(openAudio), OBJC_ASSOCIATION_RETAIN);
}

- (BOOL)openAudio {
    NSNumber *openAudio = objc_getAssociatedObject(self, _cmd);
    return [openAudio boolValue];
}

- (NSString *)audioPath {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setAudioPath:(NSString *)audioPath {
    objc_setAssociatedObject(self, @selector(audioPath), audioPath, OBJC_ASSOCIATION_COPY);
}

- (MPVolumeView *)volumeView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setVolumeView:(MPVolumeView *)volumeView {
    objc_setAssociatedObject(self, @selector(volumeView), volumeView, OBJC_ASSOCIATION_RETAIN);
}

- (BDCTAudioPlayer *)audioPlayer {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setAudioPlayer:(BDCTAudioPlayer *)audioPlayer {
    objc_setAssociatedObject(self, @selector(audioPlayer), audioPlayer, OBJC_ASSOCIATION_RETAIN);
}

- (void)playAudioWithActionTip:(NSString *)actionTip smallActionTip:(NSString *)smallActionTip {
    if (!self.openAudio || (!actionTip && !smallActionTip))
        return;
    NSString *fileNamePre = smallActionTip.length ? smallActionTip : actionTip;
    NSString *fileName = [NSString stringWithFormat:@"%@.mp3", fileNamePre];
    NSString *path = [self.audioPath stringByAppendingPathComponent:fileName];

    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL exist = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    if (exist && !isDir) {
        if (!self.audioPlayer) {
            self.audioPlayer = [[BDCTAudioPlayer alloc] init];
        }
        [self.audioPlayer playAudioWithFilePath:path];
    }
}

- (void)changeSystemVolume {
    self.volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(-100, -100, 10, 10)];
    [self.view addSubview:self.volumeView];

    UISlider *slider = nil;
    for (UIView *subview in [self.volumeView subviews]) {
        if ([subview.class.description isEqualToString:@"MPVolumeSlider"]) {
            slider = (UISlider *)subview;
            break;
        }
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!slider)
            return;
        slider.value = 0.5;
    });
}


@end
