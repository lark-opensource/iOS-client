//
//  ACCRepoFlowControlModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/25.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModelDefine.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/AWERecordEnterFromDefine.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, ACCLVFrameRecoverOption) {
    ACCLVFrameRecoverMusic = 1 << 0,
    ACCLVFrameRecoverVolume = 1 << 2,
    ACCLVFrameRecoverCutMusic = 1 << 3,
    ACCLVFrameRecoverVoiceChanger = 1 << 4,
    ACCLVFrameRecoverTextReading = 1 << 5,
    
    ACCLVFrameRecoverAll = ACCLVFrameRecoverMusic | ACCLVFrameRecoverVolume | ACCLVFrameRecoverCutMusic | ACCLVFrameRecoverVoiceChanger | ACCLVFrameRecoverTextReading,
};

@interface ACCRepoFlowControlModel : NSObject <ACCRepositoryContextProtocol, NSCopying>

@property (nonatomic, assign) AWEPublishFlowStep step;

@property (nonatomic, assign) BOOL disableBackToTabBar;
@property (nonatomic, assign) BOOL hasRecoveredAudioFragments;

@property (nonatomic, assign) AWEVideoRecordButtonType videoRecordButtonType;

 @property (nonatomic, assign) BOOL showOneTabExclusively;

 // only show which tab. if live, this field will be 'live'
 @property (nonatomic, copy) NSString *exclusiveRecordType;
 @property (nonatomic, assign, readonly) NSInteger exclusiveRecordModeId;

- (BOOL)isFixedDuration;

@end

@interface AWEVideoPublishViewModel (RepoFlowControl)
 
@property (nonatomic, strong, readonly) ACCRepoFlowControlModel *repoFlowControl;
 
@end

NS_ASSUME_NONNULL_END
