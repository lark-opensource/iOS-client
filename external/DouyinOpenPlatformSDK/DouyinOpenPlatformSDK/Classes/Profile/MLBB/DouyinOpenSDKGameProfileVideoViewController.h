//
//  DouyinOpenSDKGameProfileVideoViewController.h
//  DouyinOpenPlatformSDK
//
//  Created by bytedance on 2022/3/4.
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
#import "DouyinOpenSDKProfileVideoModel.h"
#import "DouyinOpenSDKProfile.h"

@class AVPlayer;
@interface DouyinOpenSDKGameProfileVideoViewController : UIViewController

@property (nonatomic, copy, readwrite) NSArray <DouyinOpenSDKProfileVideoModel *> *videoModels;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) UIInterfaceOrientationMask orientationMask;
@property (nonatomic, assign) BOOL isFromMiniPlay;

- (IBAction)playPausePressed:(UIButton *)sender;
- (IBAction)previousPressed:(UIButton *)sender;
- (IBAction)nextPressed:(UIButton *)sender;

@property (nonatomic, copy) DouyinOpenSDKVideoStateCallback videoStateCallback;
@property (nonatomic, copy) DouyinOpenSDKVideoPrePlayCallback prePlayCallback;
@property (nonatomic, copy) DouyinOpenSDKVideoNextPlayCallback nextPlayCallback;
@property (nonatomic, copy) DouyinOpenSDKVideoMiniPlayCallback miniPlayCallback;
@property (nonatomic, copy) DouyinOpenSDLVideoActionCallBack videoActionCallBack;
@property (nonatomic, copy) DouyinOpenSDKVideoDidFinishPlayingCallback videoDidFinishPlayingCallback;

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *nextHiddenLeading;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *previousHiddenTrailing;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *previousNormalTrailling;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *nextNormalLeading;

@property (nonatomic, copy) DouyinOpenSDKVideoErrorCallback videoErrorCallback;
@property (nonatomic, strong) IBOutlet UIButton *playPauseBackgroundButton;
@property (nonatomic, strong) IBOutlet UIButton *playPauseButton;
@property (nonatomic, strong) IBOutlet UIButton *nextViewButton;
@property (nonatomic, strong) IBOutlet UIButton *previousViewButton;
@property (nonatomic, strong) IBOutlet UIButton *previousButton;
@property (nonatomic, strong) IBOutlet UIButton *nextButton;
@property (nonatomic, strong) IBOutlet UISlider *slider;
@property (nonatomic, strong) IBOutlet UILabel *timePlayed;
@property (nonatomic, strong) IBOutlet UILabel *timeRemain;
@property (nonatomic, strong) IBOutlet UILabel *showStopperLabel;
@property (nonatomic, strong) IBOutlet UIButton *miniPlayButton;

- (void)updatePlayer:(AVPlayer *)player withCMTime:(CMTime)currentTime;

@end
