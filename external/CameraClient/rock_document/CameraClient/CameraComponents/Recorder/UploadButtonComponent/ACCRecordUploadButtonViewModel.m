//
//  ACCRecordUploadButtonViewModel.m
//  Pods
//
//  Created by guochenxiang on 2020/6/11.
//

#import "ACCRecordUploadButtonViewModel.h"

@interface ACCRecordUploadButtonViewModel()

@property (nonatomic, strong) RACSubject *viewDidAppearSubject;
@property (nonatomic, strong) RACSubject *cameraStartRenderSubject;
@property (nonatomic, strong) RACSubject *uploadVCShowedSubject;

@end

@implementation ACCRecordUploadButtonViewModel

- (void)dealloc
{
    [self.viewDidAppearSubject sendCompleted];
    [self.cameraStartRenderSubject sendCompleted];
    [self.uploadVCShowedSubject sendCompleted];
}

- (RACSubject *)viewDidAppearSubject
{
    if (!_viewDidAppearSubject) {
        _viewDidAppearSubject = [RACSubject subject];
    }
    return _viewDidAppearSubject;
}

- (RACSubject *)cameraStartRenderSubject
{
    if (!_cameraStartRenderSubject) {
        _cameraStartRenderSubject = [RACSubject subject];
    }
    return _cameraStartRenderSubject;
}

- (RACSubject *)uploadVCShowedSubject
{
    if (!_uploadVCShowedSubject) {
        _uploadVCShowedSubject = [RACSubject subject];
    }
    return _uploadVCShowedSubject;
}

@end
