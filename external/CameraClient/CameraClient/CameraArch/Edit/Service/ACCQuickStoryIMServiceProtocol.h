//
//  ACCQuickStoryIMServiceProtocol.h
//  CameraClient
//
//  Created by ZZZ on 2021/10/8.
//

#import <CreativeKit/ACCServiceLocator.h>

@protocol ACCEditViewContainer;
@protocol ACCEditServiceProtocol;

@class AWEResourceUploadParametersResponseModel;
@class AWEVideoPublishViewModel;

@protocol ACCQuickStoryIMServiceDelegate <NSObject>

@required

- (void)quickStoryIMServiceSendIMWillStart; // 只发私信 开始

- (void)quickStoryIMServiceSendIMDidFinish; // 只发私信 结束

@end

@protocol ACCQuickStoryIMServiceProtocol <NSObject>

@required

@property (nonatomic, weak, nullable) id <ACCQuickStoryIMServiceDelegate> delegate;
@property (nonatomic, strong, nullable) AWEResourceUploadParametersResponseModel *uploadParamsCache;
@property (nonatomic, assign) BOOL shouldVideoSaveAsPhoto;

- (void)showPanelWithRepository:(nullable AWEVideoPublishViewModel *)repository
                    editService:(nullable id <ACCEditServiceProtocol>)editService
                  viewContainer:(nullable id <ACCEditViewContainer>)viewContainer;

- (BOOL)canGoNext;

@end

FOUNDATION_STATIC_INLINE id <ACCQuickStoryIMServiceProtocol> ACCQuickStoryIMService()
{
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCQuickStoryIMServiceProtocol)];
}
