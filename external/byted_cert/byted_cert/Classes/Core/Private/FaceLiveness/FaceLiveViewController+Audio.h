//
//  FaceLiveViewController+Audio.h
//  byted_cert
//
//  Created by liuminghui.2022 on 2023/2/3.
//

#import "FaceLiveViewController.h"

NS_ASSUME_NONNULL_BEGIN


@interface FaceLiveViewController (Audio)

@property (nonatomic, assign) BOOL openAudio;

@property (nonatomic, copy) NSString *audioPath;

- (void)playAudioWithActionTip:(NSString *)actionTip smallActionTip:(NSString *)smallActionTip;
- (void)changeSystemVolume;

@end

NS_ASSUME_NONNULL_END
