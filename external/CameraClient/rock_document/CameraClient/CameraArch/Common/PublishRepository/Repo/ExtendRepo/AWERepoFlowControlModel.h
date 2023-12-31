//
//  AWERepoFlowControlModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/25.
//

#import <CreationKitArch/ACCRepoFlowControlModel.h>


NS_ASSUME_NONNULL_BEGIN


@interface AWERepoFlowControlModel : ACCRepoFlowControlModel <ACCRepositoryContextProtocol>

@property (nonatomic, assign) NSInteger modeId;

@property (nonatomic, assign) ACCLVFrameRecoverOption LVHasRecoverFlag;

@property (nonatomic, assign) AWERecordEnterFromType enterFromType;

@property (nonatomic, assign) BOOL autoShoot;

@property (nonatomic, assign) BOOL isShowingHalfScreenAlbum;
@property (nonatomic, assign) BOOL isSpecialPlusButton; // 是否加号异化


@end

@interface AWEVideoPublishViewModel (AWERepoFlowControl)
 
@property (nonatomic, strong, readonly) AWERepoFlowControlModel *repoFlowControl;
 
@end

NS_ASSUME_NONNULL_END
