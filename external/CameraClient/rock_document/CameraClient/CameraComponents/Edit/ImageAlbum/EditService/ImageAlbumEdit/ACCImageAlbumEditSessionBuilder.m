//
//  ACCImageAlbumEditSessionBuilder.m
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by imqiuhang on 2020/12/23.
//

#import "ACCImageAlbumEditSessionBuilder.h"
#import "ACCImageAlbumEditorSession.h"
#import "ACCImageAlbumModernEditorSession.h"
#import "ACCImageEditMediaContainerView.h"
#import "ACCEditViewControllerInputData.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import "ACCRepoImageAlbumInfoModel.h"
#import <CreativeKit/ACCMacros.h>
#import "ACCImageAlbumData.h"
#import <CreationKitArch/ACCRepoDraftModel.h>
#import "ACCConfigKeyDefines.h"
#import "ACCNLEUtils.h"

@interface ACCImageAlbumEditSessionBuilder ()

@property (nonatomic, strong) id<ACCImageAlbumEditorSessionProtocol> editSession;
@property (nonatomic, weak  ) AWEVideoPublishViewModel *publishModel;

@property (nonatomic, strong) NSHashTable *subscribers;

@end

@implementation ACCImageAlbumEditSessionBuilder

@synthesize mediaContainerView = _mediaContainerView;

- (instancetype)initWithInputData:(ACCEditViewControllerInputData *)inputData
{
    ACC_CHECK_NLE_COMPATIBILITY(NO, inputData.publishModel);
    self = [super init];
    if (self) {
        _publishModel = inputData.publishModel;
    }
    return self;
}

- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    self = [super init];
    
    if (self) {
        _publishModel = publishModel;
    }
    
    return self;
}

#pragma mark - public
- (ACCEditSessionWrapper *)buildEditSession
{
    if (self.editSession) {
        [self p_updateImageAlbumData];
        [self.editSession updateAlbumData:self.publishModel.repoImageAlbumInfo.imageAlbumData];
        return [[ACCEditSessionWrapper alloc] initWithEditorSession:self.editSession];
    }
    
    [self.mediaContainerView builder];
    [self p_updateImageAlbumData];
    
    if (ACCConfigBool(kConfigBool_enable_image_album_ve_editor_cache_opt)) {
        self.editSession = [[ACCImageAlbumModernEditorSession alloc] initWithImageAlbumData:self.publishModel.repoImageAlbumInfo.imageAlbumData containerSize:self.mediaContainerView.originalPlayerFrame.size];
    } else {
        self.editSession = [[ACCImageAlbumEditorSession alloc] initWithImageAlbumData:self.publishModel.repoImageAlbumInfo.imageAlbumData containerSize:self.mediaContainerView.originalPlayerFrame.size];
    }

    ACCEditSessionWrapper *wrapper = [[ACCEditSessionWrapper alloc] initWithEditorSession:self.editSession];
    for (id<ACCEditBuildListener> listener in self.subscribers) {
        [listener onEditSessionInit:wrapper];
    }
    
    return [[ACCEditSessionWrapper alloc] initWithEditorSession:self.editSession];
}

- (void)addEditSessionListener:(id<ACCEditBuildListener>)listener
{
    if ([listener respondsToSelector:@selector(setupPublishViewModel:)]) {
        [listener setupPublishViewModel:self.publishModel];
    }
    
    if (self.editSession) {
        [listener onEditSessionInit:[[ACCEditSessionWrapper alloc] initWithEditorSession:self.editSession]];
    } else {
        [self.subscribers addObject:listener];
    }
}

#pragma mark - private

- (void)p_updateImageAlbumData
{
    AWEVideoPublishViewModel *publishModel = self.publishModel;
    ACCRepoImageAlbumInfoModel *albumInfoModel = publishModel.repoImageAlbumInfo;
    
    if (ACC_isEmptyArray(albumInfoModel.imageAlbumData.imageAlbumItems)) {
        albumInfoModel.imageAlbumData = [[ACCImageAlbumData alloc] initWithImageAlbumInfoModel:albumInfoModel taskId:publishModel.repoDraft.taskID];
    }
}

#pragma mark - getter
- (UIView<ACCMediaContainerViewProtocol> *)mediaContainerView
{
    if (!_mediaContainerView) {
        _mediaContainerView = [[ACCImageEditMediaContainerView alloc] initWithPublishModel:self.publishModel];
    }
    return _mediaContainerView;
}

- (NSHashTable *)subscribers
{
    if (!_subscribers) {
        _subscribers = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    return _subscribers;
}

- (void)resetPlayerAndPreviewEdge
{
    
}


@end
