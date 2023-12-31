//
//  ACCPhotoToVideoComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by 李辉 on 2020/4/14.
//

#import "ACCPhotoToVideoComponent.h"

#import "ACCPhotoToVideoViewModel.h"
#import "ACCRecordFlowService.h"
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import "ACCRecordFlowConfigProtocol.h"
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CameraClient/ACCRecordViewControllerInputData.h>

@interface ACCPhotoToVideoComponent () <ACCRecordFlowServiceSubscriber>

@property (nonatomic, strong) ACCPhotoToVideoViewModel *photoToVideoViewModel;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCRecordFlowConfigProtocol> flowConfig;

@end

@implementation ACCPhotoToVideoComponent
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, flowConfig, ACCRecordFlowConfigProtocol)

#pragma mark - ACCFeatureComponent
- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

#pragma mark - getter and setters
- (ACCPhotoToVideoViewModel *)photoToVideoViewModel
{
    if (!_photoToVideoViewModel) {
        _photoToVideoViewModel = [self.modelFactory createViewModel:ACCPhotoToVideoViewModel.class];
    }
    return _photoToVideoViewModel;
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.flowService addSubscriber:self];
}

#pragma mark - ACCRecordFlowServiceSubscriber

- (void)flowServiceDidTakePicture:(UIImage *)image error:(NSError *)error
{
    if (error != nil) {
        AWELogToolError(AWELogToolTagRecord, @"Take picture failed. %@", error);
        return;
    }
    if (![self.flowConfig needJumpDirectlyAfterTakePicture]) {
        [self.photoToVideoViewModel exportMVVideoWithPublishModel:self.photoToVideoViewModel.inputData.publishModel failedBlock:^{
            [ACCToast() showError:ACCLocalizedString(@"com_mig_there_was_a_problem_with_the_internet_connection_try_again_later_yq455g", @"There was a problem with the internet connection. Try again later.")];
        }];
    }
}

@end
