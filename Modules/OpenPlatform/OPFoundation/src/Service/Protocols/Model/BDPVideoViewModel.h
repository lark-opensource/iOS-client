//
//  BDPVideoViewModel.h
//  Timor
//
//  Created by CsoWhy on 2019/1/11.
//

#import "BDPBaseJSONModel.h"

@interface BDPVideoViewModel : BDPBaseJSONModel

@property (nonatomic, assign) BOOL hide;
@property (nonatomic, assign) BOOL autoplay;
@property (nonatomic, assign) BOOL loop;
@property (nonatomic, assign) CGRect frame;
@property (nonatomic, copy) NSString *data;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, strong, nullable) NSURL *poster;
@property (nonatomic, assign) CGFloat initialTime;
@property (nonatomic, assign) CGFloat duration; // 视频总时长
@property (nonatomic, strong) NSNumber *direction; // 全屏时旋转方向，有效值为0，90，-90，不传默认根据视频长宽确定旋转方向
@property (nonatomic, copy) NSString *objectFit; // contain包含 fill填充 cover覆盖
@property (nonatomic, copy) NSString<Ignore> *cacheDir;
@property (nonatomic, copy) NSString *encryptToken;
/// 是否静音播放，默认为 NO
@property (nonatomic, assign) BOOL muted;
@property (nonatomic, assign) BOOL controls;
@property (nonatomic, assign) BOOL showFullscreenBtn;
@property (nonatomic, assign) BOOL showPlayBtn;
@property (nonatomic, copy) NSString *playBtnPosition;
/// 是否第一次播放的时候全屏
@property (nonatomic, assign) BOOL autoFullscreen;
/// 是否展示静音按钮
@property (nonatomic, assign) BOOL showMuteBtn;
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *header;
@property (nonatomic, assign) BOOL showProgress;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) BOOL showBottomProgress;
@property (nonatomic, assign) BOOL showScreenLockButton;
@property (nonatomic, assign) BOOL showSnapshotButton;
@property (nonatomic, assign) BOOL showRateButton;
@property (nonatomic, assign) BOOL enableProgressGesture;
@property (nonatomic, assign) BOOL enablePlayGesture;
@property (nonatomic, assign) BOOL autoPauseIfOutsideScreen;

@end
