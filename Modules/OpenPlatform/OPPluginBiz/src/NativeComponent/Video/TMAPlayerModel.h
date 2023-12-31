//
//  TMAPlayerModel.h
//  OPPluginBiz
//
//  Created by bupozhuang on 2019/1/3.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TMAPlayerModel : NSObject
/** 视频URL */
@property (nonatomic, strong) NSURL *videoURL;
/** 视频encryptToken */
@property (nonatomic, copy) NSString *encryptToken;
/** 播放器View的父视图 */
@property (nonatomic, weak) UIView *fatherView;

/** 从xx秒开始播放视频(默认0) */
@property (nonatomic, assign) CGFloat seekTime;
/** 视频总长度（默认0） */
@property (nonatomic, assign) CGFloat totalTime;
/** 视频缓存路径 */
@property (nonatomic, copy) NSString *cacheDir;
/** 视频全屏时方向 **/
//设置全屏时视频的方向，不指定则根据宽高比自动判断。
//有效值为 0（正常竖向）, 90（屏幕顺时针90度）, -90（屏幕逆时针90度）
@property (nonatomic, strong) NSNumber *direction;
/** 视频展示方式*/
@property (nonatomic, copy) NSString *objectFit;
/** 预览图*/
@property (nonatomic, strong, nullable) NSURL *poster;
/** 是否展示control*/
@property (nonatomic, assign) BOOL controls;
/** 是否循环播放, 默认为 NO */
@property (nonatomic, assign) BOOL loop;
/** 是否静音播放, 默认为 NO */
@property (nonatomic, assign) BOOL muted;
/** 是否第一次播放的时候全屏 */
@property (nonatomic, assign) BOOL autoFullscreen;
/** 是否展示静音按钮*/
@property (nonatomic, assign) BOOL showMuteBtn;

@property (nonatomic, assign) BOOL showPlayBtn;
@property (nonatomic, assign) BOOL showFullscreenBtn;
/** 播放按钮位置, 取值范围['bottom', 'center'], 默认值'bottom' */
@property (nonatomic, copy) NSString *playBtnPosition;
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *header;
@property (nonatomic, assign) BOOL showProgress;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) BOOL showBottomProgress;
@property (nonatomic, assign) BOOL showScreenLockButton;
@property (nonatomic, assign) BOOL showSnapshotButton;
@property (nonatomic, assign) BOOL showRateButton;
@property (nonatomic, assign) BOOL enableProgressGesture;
@property (nonatomic, assign) BOOL enablePlayGesture;

@end

NS_ASSUME_NONNULL_END
