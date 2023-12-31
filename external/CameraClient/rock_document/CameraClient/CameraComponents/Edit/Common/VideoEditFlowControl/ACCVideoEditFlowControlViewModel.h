//
//  ACCVideoEditFlowControlViewModel.h
//  CameraClient
//
//  Created by chengfei xiao on 2020/5/15.
//

#import "ACCEditViewModel.h"
#import <CreationKitInfra/ACCRACWrapper.h>
#import <CameraClient/AWEVideoPublishResponseModel.h>
#import "ACCVideoEditFlowControlService.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCTrackProtocol;
@class AWEVideoPublishViewModel;


@interface ACCVideoEditFlowControlViewModel : ACCEditViewModel<ACCVideoEditFlowControlService>

@property (nonatomic, strong, readonly) RACSignal *publishPrivateWorkSignal;

@property (nonatomic, assign, readonly) CGRect publishButtonFrame;

@property (nonatomic, assign) BOOL isQuickPublishBubbleShowed;

@property (nonatomic, copy) NSNumber *originalStickerCount;

- (void)notifyWillEnterPublishPage;
- (void)notifyWillDirectPublish;
- (void)notifyDataClearForBackup;
- (void)notifyDidUpdatePublishButton:(UIView *)publishButton nextButton:(UIView *)nextButton;
- (void)notifyDidQuickPublishGuideDismiss;

- (void)fetchUploadParams;

- (void)clearBeforeBack;

- (BOOL)isVideoEdited;

- (BOOL)isDraftEdited; // 草稿流程判断

- (NSMutableDictionary *)extraAttributes;

- (void)trackPlayPerformanceWithNextActionName:(NSString *)nextAction;

- (void)trackWhenGotoPublish;

- (void)trackEnterVideoEditPageEvent;

+ (void)trackEnterVideoEditPageWith:(AWEVideoPublishViewModel *)repository fromGroup:(NSString *)fromGroup tracker:(id<ACCTrackProtocol>)tracker;

/// flower红包单btn模式
- (BOOL)isFlowerRedpacketOneButtonMode;

- (NSString *_Nullable)nextButtonTitleForFlowerAwardIfEnable;

@end

NS_ASSUME_NONNULL_END
