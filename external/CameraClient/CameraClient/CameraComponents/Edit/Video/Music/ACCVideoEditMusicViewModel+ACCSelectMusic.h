//
//  ACCVideoEditMusicViewModel+ACCSelectMusic.h
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/7/29.
//

#import "ACCVideoEditMusicViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCVideoEditMusicViewModel (ACCSelectMusic)

@property (nonatomic, strong, readonly) NSNumber *isRequestingMusicForQuickPicture;  // 用于标记照片是否自动配乐，进行编辑页顶部音乐bar动画使用

- (void)fetchPhotoToVideoMusicSilently;
- (void)fetchPhotoToVideoMusicWithCompletion:(void (^ _Nullable)(BOOL))completion;

- (void)configForbidWeakBindMusicWithBlock:(void (^)(void))weakBindMusicSuccessBlock; // 配置是否需要禁用弱绑定音乐
- (void)selectFirstMusicAutomatically; 

- (BOOL)shouldSelectMusicAutomatically;
- (BOOL)shouldAutoApplyWeakBind;
- (BOOL)shouldRecordAutomaticSelectMusic;
- (BOOL)shouldImportAutomaticSelectMusic;

@end

NS_ASSUME_NONNULL_END
