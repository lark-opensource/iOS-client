//
//  CameraRecordRouter.m
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/1/19.
//

#import "CameraRecordRouter.h"
#import "NLEEditorManager.h"
#import <NLEPlatform/NLEInterface.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>
#import <CameraClient/ACCEditViewControllerInputData.h>
#import <CameraClient/AWERepoVideoInfoModel.h>
#import <CameraClient/AWERepoFilterModel.h>
#import <CameraClient/AWERepoPublishConfigModel.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoPublishConfigModel.h>
#import "LarkVideoDirector/LarkVideoDirector-Swift.h"
#import "CameraRecordController.h"
#import "MVPBaseServiceContainer.h"
#import <CameraClient/ACCNLEUtils.h>

@interface CameraRecordRouter ()

@end

@implementation CameraRecordRouter

@synthesize targetViewControllerInputData;
@synthesize sourceViewControllerInputData;
@synthesize sourceViewController;

- (nonnull instancetype)initWithSourceViewController:(nonnull UIViewController *)sourceViewController targetViewControllerInputData:(id _Nullable)targetViewControllerInputData {
    self = [super init];
    if (self) {
        self.sourceViewController = sourceViewController;
        self.targetViewControllerInputData = targetViewControllerInputData;
    }
    return self;
}

- (void)routeWithAnimated:(BOOL)animated completion:(void (^ _Nullable)(void))completion {

    AWEVideoPublishViewModel* publishModel = self.targetViewControllerInputData.publishModel;
    if (publishModel.repoContext.videoType == AWEVideoTypePicture &&
        publishModel.repoPublishConfig.firstFrameImage != NULL) {
        [MVPBaseServiceContainer sharedContainer].isExport = YES;
        // 图片
        if ([self.sourceViewController isKindOfClass: [CameraRecordController class]]) {
            CameraRecordController* vc = self.sourceViewController;
            NSString *lensName = nil;
            if ([publishModel.repoPublishConfig isKindOfClass:[AWERepoPublishConfigModel class]]) {
                AWERepoPublishConfigModel *model = publishModel.repoPublishConfig;
                lensName = model.lensName;
            }
            [vc.delegate cameraTakePhoto:publishModel.repoPublishConfig.firstFrameImage
                                    from:lensName
                              controller:vc];
        } else {
            assert("vc type is wrong");
        }
    } else {
        [MVPBaseServiceContainer sharedContainer].inCamera = YES;
        NSArray<AVAsset *>* assets = [[publishModel.repoVideoInfo video] videoAssets];
        UIViewController *controller = [NLEEditorManager createDVEViewControllerWithAssets:assets from:self.sourceViewController];
        [CATransaction begin];
        [CATransaction setCompletionBlock:^{
            !completion ?: completion();
        }];
        [self.sourceViewController.navigationController pushViewController:controller animated:animated];
        [CATransaction commit];
    }
}

- (nonnull id)handleTargetViewControllerInputData {
    ACCEditViewControllerInputData *editData = [[ACCEditViewControllerInputData alloc] init];
    editData.publishModel = self.sourceViewControllerInputData.publishModel.copy;
    editData.sourceModel =  self.sourceViewControllerInputData.publishModel;
    editData.playImmediately = YES;
    @weakify(self);
    editData.cancelBlock = ^{
        @strongify(self);
        self.sourceViewControllerInputData.publishModel.repoFilter.capturedWithLightningFilter = NO;
    };
    return editData;
}

@end
