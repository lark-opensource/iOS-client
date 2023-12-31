//
//  ACCMusicPanelViewModel.h
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/6/25.
//

#import <Foundation/Foundation.h>

#import "AWERepoMusicModel.h"
#import <CreativeKit/ACCMacros.h>
@protocol ACCMusicModelProtocol;

NS_ASSUME_NONNULL_BEGIN

@interface ACCMusicPanelViewModel : NSObject

@property (nonatomic, strong, readonly) AWEVideoPublishViewModel *publishViewModel;

- (instancetype)initWithPublishViewModel:(AWEVideoPublishViewModel *)publishViewModel NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

#pragma mark - public

- (BOOL)shouldShowMusicPanelTabOnly; // 是否隐藏音乐面板底部toolbar
- (NSString *)deselectedMusicToast; // 无法取消选中音乐的文案

- (BOOL)enableMusicPanelVertical;  // 是否支持新音乐面板
+ (BOOL)enableNewMusicPanelUnification;  // 拍摄编辑音乐面板统一
- (BOOL)enableCheckbox; // 线上面版支持checkbox调节配乐和原声
+ (BOOL)autoSelectedMusic; //  无配乐打开面板默认应用歌曲

#pragma mark - music panel

@property (nonatomic, assign) BOOL showPanelScrollToSelectItem; // 用于展示音乐面板数据加载后，滑动到用户选择的cell上
@property (nonatomic, assign) BOOL showPanelAutoSelectedMusic; // 展示音乐面板，已存在或选择过音乐后置为false，标记不受数据刷新影响
@property (nonatomic, assign) BOOL trackFirstShowMusicType; // 记录完成第一次音乐面板呈现的音乐数据源类型埋点
@property (nonatomic, assign) BOOL trackFirstDismissMusicType; // 记录完成第一次音乐面板退出的音乐数据源类型埋点
@property (nonatomic, assign) BOOL isShowing; // 记录当前面板是否正在展示中

@property (nonatomic, assign) BOOL bgmMusicDisable; // 控制配乐可用状态
@property (nonatomic, assign) float voiceVolume; // 记录用户选择的原声音量
@property (nonatomic, assign) float bgmVolume; // 记录配乐音量

- (void)resetPanelShowStatus:(BOOL)status;

@end

NS_ASSUME_NONNULL_END
