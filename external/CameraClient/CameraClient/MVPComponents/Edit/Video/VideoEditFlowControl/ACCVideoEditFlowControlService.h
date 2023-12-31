//
//  ACCVideoEditFlowControlService.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/12/21.
//

#ifndef ACCVideoEditFlowControlService_h
#define ACCVideoEditFlowControlService_h

@protocol ACCVideoEditFlowControlService;
@class AWEResourceUploadParametersResponseModel;

@protocol ACCVideoEditFlowControlSubscriber <NSObject>

@optional
- (void)dataClearForBackup:(id<ACCVideoEditFlowControlService>)service;

- (void)willGoBackToRecordPageWithEditFlowService:(id<ACCVideoEditFlowControlService>)service;

- (void)willDirectPublishWithEditFlowService:(id<ACCVideoEditFlowControlService>)service;

- (void)willEnterPublishWithEditFlowService:(id<ACCVideoEditFlowControlService>)service;

- (void)willSwitchImageAlbumEditModeWithEditFlowService:(id<ACCVideoEditFlowControlService>)service;

- (void)willSwitchSmartMovieEditModeWithEditFlowService:(id<ACCVideoEditFlowControlService> _Nullable)service;

- (void)synchronizeRepositoryWithEditFlowService:(id<ACCVideoEditFlowControlService>)service;

- (void)didUpdatePublishButton:(UIView *)publishButton nextButton:(UIView *)nextButton;

- (void)didQuickPublishGuideDismiss:(id<ACCVideoEditFlowControlService>)service;

- (void)didFetchUploadParams:(nonnull AWEResourceUploadParametersResponseModel *)uploadParams;

@end


@protocol ACCVideoEditFlowControlService <NSObject>

@property (nonatomic, assign, readonly) BOOL isQuickPublishBubbleShowed;
@property (nonatomic, strong, readonly) AWEResourceUploadParametersResponseModel *uploadParamsCache;

- (void)addSubscriber:(id<ACCVideoEditFlowControlSubscriber>)subscriber;

@optional
- (void)notifyWillSwitchSmartMovieEditMode;
- (void)notifyWillGoBackToRecordPage;

- (void)notifyWillSwitchImageAlbumEditMode;

- (void)notifyShouldSynchronizeRepository;

- (void)notifyWillDirectPublish;

- (void)notifyWillEnterPublishPage;

- (void)publishPrivateWork;

- (void)didSaveDraftOnEditPage;

@end

#endif /* ACCVideoEditFlowControlService_h */
