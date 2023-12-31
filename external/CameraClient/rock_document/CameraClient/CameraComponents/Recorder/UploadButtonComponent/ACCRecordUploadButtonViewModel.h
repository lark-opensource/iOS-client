//
//  ACCRecordUploadButtonViewModel.h
//  Pods
//
//  Created by guochenxiang on 2020/6/11.
//

#import <CreationKitArch/ACCRecorderViewModel.h>
#import <CreationKitInfra/ACCRACWrapper.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCRecordUploadButtonViewModel : ACCRecorderViewModel

@property (nonatomic, readonly) RACSubject *viewDidAppearSubject;
@property (nonatomic, readonly) RACSubject *cameraStartRenderSubject;
@property (nonatomic, readonly) RACSubject *uploadVCShowedSubject;

@property (nonatomic, copy) BOOL (^needHideUploadLabelBlock)(void);

@end

NS_ASSUME_NONNULL_END
