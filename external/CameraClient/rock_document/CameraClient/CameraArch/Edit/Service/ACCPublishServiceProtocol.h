//
//  ACCQuickStoryPublishService.h
//  CameraClient
//
//  Created by wishes on 2020/6/30.
//

#import <Foundation/Foundation.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
 
@class AWEVideoPublishViewModel, AWEResourceUploadParametersResponseModel;

@protocol ACCPublishServiceSaveAlbumHandle;

@protocol ACCPublishServiceProtocol <NSObject>

@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, strong) id<ACCEditServiceProtocol> editService;
@property (nonatomic, strong) AWEResourceUploadParametersResponseModel *uploadParamsCache;
@property (nonatomic, assign) BOOL shouldPreservePublishTitle;
@property (nonatomic, assign) BOOL isPostPage;
@property (nonatomic, assign) BOOL isSaveToAlbumSourceImage; // 存本地使用图片格式

- (void)publishQuickStory;

- (void)saveToAlbum;

- (id <ACCPublishServiceSaveAlbumHandle>)createSaveAlbumHandle;

- (void)publishNormalVideo;
- (void)publishNormalVideo:(BOOL)skipCover;
- (void)saveDraftWithFeedback:(BOOL)feedback;
- (void)saveOrignalDraft;
- (void)generateCoverAndSave:(BOOL)isBackup completion:(void(^)(NSError *_Nullable error))completion;

@end


