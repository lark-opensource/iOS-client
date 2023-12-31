//
//  ACCEditSmartMovieViewModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/8/2.
//

#import "ACCEditViewModel.h"
#import <CameraClient/ACCSmartMovieManagerProtocol.h>

@protocol ACCMusicModelProtocol;

typedef void(^ACCExportSmartMovieSuccessCallback)(AWEVideoPublishViewModel *_Nullable result, BOOL isCanceled);

@interface ACCEditSmartMovieViewModel : ACCEditViewModel

/// 重新导出指定mode的数据
/// @param mode 指定mode
/// @param repository 源数据
/// @param musicID 音乐ID
- (void)exportDataForMode:(ACCSmartMovieSceneMode)mode
               repository:(AWEVideoPublishViewModel *_Nonnull)repository
                  musicID:(NSString *_Nullable)musicID
                  succeed:(ACCExportSmartMovieSuccessCallback _Nullable)succeedBlock
                   failed:(void(^_Nullable)(void))failedBlock;

/// 刷新repository的数据
/// @param repository 需要刷新的源数据
/// @param musicID 音乐ID（用于刷新）
- (void)refreshRepository:(AWEVideoPublishViewModel *_Nonnull)repository
                  musicID:(NSString *_Nonnull)musicID
                  succeed:(ACCExportSmartMovieSuccessCallback _Nullable)succeedBlock
                   failed:(void(^_Nullable)(void))failedBlock;

#pragma mark - Backup Methods

/// 恢复repository中的数据
/// @param repository 需要恢复的数据对象
- (void)recoveryRepository:(AWEVideoPublishViewModel *_Nonnull)repository;

/// 备份音乐数据
/// @param music 需要被备份的音乐
- (void)backupMusic:(id<ACCMusicModelProtocol> _Nullable)music;

@end
