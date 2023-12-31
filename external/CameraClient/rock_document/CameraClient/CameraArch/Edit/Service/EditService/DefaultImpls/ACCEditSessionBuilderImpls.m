//
//  ACCEditSessionBuilderImpls.m
//  AWEStudio-Pods-Aweme
//
//  Created by Liu Deping on 2020/12/13.
//

#import "AWERepoContextModel.h"
#import "ACCEditSessionBuilderImpls.h"
#import <TTVideoEditor/VEEditorSession.h>
#import "ACCMediaContainerView.h"
#import <CreationKitInfra/UIView+ACCRTL.h>
#import "AWERepoVideoInfoModel.h"
#import "AWERepoMVModel.h"
#import "ACCEditVideoDataDowngrading.h"
#import "ACCEditSessionConfigBuilder.h"
#import "ACCNLEUtils.h"

@interface ACCEditSessionBuilderImpls ()

@property (nonatomic, assign) BOOL isMV;
@property (nonatomic, weak) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, strong, readwrite) VEEditorSession *editSession;

@property (nonatomic, strong) NSHashTable *subscribers;

@end

@implementation ACCEditSessionBuilderImpls

@synthesize mediaContainerView = _mediaContainerView;

- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel *)publishModel isMV:(BOOL)isMV
{
    ACC_CHECK_NLE_COMPATIBILITY(NO, publishModel);
    self = [super init];
    if (self) {
        _publishModel = publishModel;
        _isMV = isMV;
    }
    return self;
}

- (VEEditorSession *)editSession
{
    if (!_editSession) {
        _editSession = [[VEEditorSession alloc] init];
    }
    return _editSession;
}

- (ACCEditSessionWrapper *)buildEditSession
{
    [self.mediaContainerView builder];
    
    if (!self.editSession) {
        self.editSession = [[VEEditorSession alloc] init];
    }
    
    VEEditorSessionConfig *config = [self editorSessionConfigWithPublishModel:self.publishModel];
    ACCEditSessionWrapper *wrapper = [[ACCEditSessionWrapper alloc] initWithEditorSession:self.editSession];
    
    if (config) {
        HTSVideoData *videoData = acc_videodata_make_hts(self.publishModel.repoVideoInfo.video);
        [self.editSession createSceneWithVideoData:videoData withConfig:config];
        for (id<ACCEditBuildListener> listener in self.subscribers) {
            [listener onEditSessionInit:wrapper];
        }
    }
    return wrapper;
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

- (VEEditorSessionConfig *)editorSessionConfigWithPublishModel:(AWEVideoPublishViewModel *)publishModel;
{
    publishModel.repoVideoInfo.video.normalizeSize = self.mediaContainerView.bounds.size;
    if (self.isMV) {
        return [ACCEditSessionConfigBuilder mvEditorSessionConfigWithPublishModel:publishModel];
    } else {
        return [ACCEditSessionConfigBuilder publishEditorSessionConfigWithPublishModel:publishModel];
    }
}

- (void)resetPlayerAndPreviewEdge {
}

- (UIView <ACCMediaContainerViewProtocol> *)mediaContainerView
{
    if (!_mediaContainerView) {
        _mediaContainerView = [[ACCMediaContainerView alloc] initWithPublishModel:self.publishModel];
        _mediaContainerView.accrtl_viewType = ACCRTLViewTypeNormal;
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

@end
