//
//  ACCMultiTrackEditComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/9/14.
//

#import "ACCMultiTrackEditComponent.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>

#import <CameraClient/AWERepoDuetModel.h>
#import <CameraClient/ACCMultiTrackEditServiceProtocol.h>
#import <CameraClient/ACCMultiTrackEditViewModel.h>

#import <MobileCoreServices/UTCoreTypes.h>

@interface ACCMultiTrackEditComponent ()

@property (nonatomic, strong) ACCMultiTrackEditViewModel *multiTrackViewModel;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;

@end


@implementation ACCMultiTrackEditComponent

IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)

- (ACCServiceBinding *)serviceBinding {
    return ACCCreateServiceBinding(@protocol(ACCMultiTrackEditServiceProtocol),
                                   self.multiTrackViewModel);
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider {
     self.multiTrackViewModel.repository = self.repository;
    self.multiTrackViewModel.serviceProvider = self.serviceProvider;
}

#pragma mark - life cycle

- (void)componentDidMount {
    BOOL enableMultiTrack = [ACCMultiTrackEditViewModel enableMultiTrackWithPublishViewModel:self.repository];
    if (enableMultiTrack) {
        // 多轨道目前只有合拍支持上传和剪同款业务场景使用
        [self bindViewModel];
    }
}

#pragma mark - private

- (void)bindViewModel {
    [self.multiTrackViewModel bindViewModel];
}

- (ACCMultiTrackEditViewModel *)multiTrackViewModel {
    if (!_multiTrackViewModel) {
        _multiTrackViewModel = [[ACCMultiTrackEditViewModel alloc] init];
    }
    return _multiTrackViewModel;
}

@end
