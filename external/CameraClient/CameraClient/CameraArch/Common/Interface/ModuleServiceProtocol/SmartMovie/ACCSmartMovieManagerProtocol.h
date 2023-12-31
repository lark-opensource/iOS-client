//
//  ACCSmartMovieManagerProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by LeonZou on 2021/8/2.
//

#import <Foundation/Foundation.h>

#import <CreativeAlbumKit/CAKAlbumAssetModel.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>
#import <NLEPlatform/NLEModel+iOS.h>
#import <TTVideoEditor/IESMMMVModel.h>
#import "ACCSmartMovieDefines.h"

/**
 智能照片电影     PM: zhangshupeng@bytedance.com
 https://bytedance.feishu.cn/docs/doccnjuT7oxRSNCt98ftg6FuJ1b
 */
@class AWEVideoPublishViewModel;
@class ACCSceneDataMarker;
@protocol ACCEditVideoDataProtocol;

typedef void(^ACCSmartMovieModelCallback)(BOOL isCanceled,
                                          NLEModel_OC *_Nullable model,
                                          NSError * _Nullable error);
typedef void(^ACCSmartMovieVideoDataCallback)(id<ACCEditVideoDataProtocol> _Nullable info,
                                              NSError * _Nullable error);

@protocol ACCSmartMovieManagerProtocol <NSObject>
@required

@property (nonatomic, copy, nullable) NSString *createId;

/**
 上一个场景，用于编辑页切换时确定数据源
 */
@property (nonatomic, assign) ACCSmartMovieSceneMode previousScene;

/// APP 是否Resign Active;
@property (nonatomic, assign, readonly) BOOL isResignActive;

/**
 清除manager的delegate数据
 */
- (void)clean;

/// 停止预加载
- (void)prefetchStop;

/// 开始预加载
- (void)prefetchStart;

/**
 清除manager的内部数据（音乐列表，taskID等）
 */
- (void)resetData;

/**
 开始智照流程前的预处理
 */
- (void)prepareToProcessSmartMovie;

/// 请求音乐列表
/// @param assets 资源路径
- (void)fetchMusicListWithAssets:(NSArray<NSString *> *_Nonnull)assets;

/// 获取NLEModel
/// @param assets 资源路径
/// @param musicID 音乐ID
/// @param isSwitchMusic 是否是切换音乐
/// @param completion 结果回调
- (void)fetchNLEModelWithAssets:(NSArray<NSString *> *_Nonnull)assets
                        musicID:(NSString *_Nullable)musicID
                  isSwitchMusic:(BOOL)isSwitchMusic
                     completion:(ACCSmartMovieModelCallback _Nullable)completion;

// Music
- (BOOL)useSmartMovieMusic;
- (nullable NSArray<id<ACCMusicModelProtocol>> *)recommendMusicList;
- (void)refreshMusicListWithAssets:(NSArray<NSString *> *_Nullable)assets;   // 草稿恢复场景下，需要重新请求音乐列表

// UI
/**
 相册页引导气泡
 */
- (void)showAlbumGuideBubbleIfNeeded:(UIButton *_Nullable)button;
- (void)dismissAlbumGuideBubbleIfNeeded;

// Helper

/**
 智照场景判断
 */
- (BOOL)isSmartMovieMode;

/**
 MV场景判断
 */
- (BOOL)isMVVideoMode;

/**
 智照流程是否被用户取消
 */
- (BOOL)isCanceled;

/**
 取消导出
 */
- (void)cancelExport;

/**
 预发布开关
 */
- (BOOL)isUserUploadEnabled;

/**
 设置编辑页场景（普通MV / 智照）
 */
- (void)setCurrentScene:(ACCSmartMovieSceneMode)mode;

/**
 展示编辑页安全Toast
 */
- (void)showRemindUploadToastIfNeeded;

/**
 转换场景时，标识数据是否已生成
 */
 - (ACCSceneDataMarker *)sceneDataMarker;

@end

@interface ACCSceneDataMarker : NSObject

@property (nonatomic, assign) BOOL smartMovieDataExist;
@property (nonatomic, assign) BOOL mvDataExist;
@property (nonatomic, assign) BOOL imageAlbumDataExist;

- (void)resetAllMark;

@end

OBJC_EXTERN id<ACCSmartMovieManagerProtocol> acc_sharedSmartMovieManager();
