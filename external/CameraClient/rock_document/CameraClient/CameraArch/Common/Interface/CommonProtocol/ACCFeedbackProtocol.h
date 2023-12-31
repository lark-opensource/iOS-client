//
//  ACCFeedbackProtocol.h
//  CameraClient
//
//  Created by lxp on 2019/11/11.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>
#import "AWEStudioFeedbackRecorderConsts.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCFeedbackProtocol <NSObject>

- (void)acc_studioRegisterParsers;

// Upload
- (void)acc_recordForVideoUpload:(AWEStudioFeedBackStatus)status code:(NSInteger)code stage:(NSInteger)stage;

// Merge
- (void)acc_recordForVideoMerge:(AWEStudioFeedBackStatus)status code:(NSInteger)code;

// Record
- (void)acc_recordForVideoRecord:(AWEStudioFeedBackStatus)status code:(NSInteger)code;
- (void)acc_recordForCameraInit:(AWEStudioFeedBackStatus)status code:(NSInteger)code;

// Draft
- (void)acc_recordForSaveVideoDraft:(AWEStudioFeedBackStatus)status code:(NSInteger)code;
- (void)acc_recordForLoadVideoDraft:(AWEStudioFeedBackStatus)status code:(NSInteger)code;
- (void)acc_recordForDeleteVideoDraft:(AWEStudioFeedBackStatus)status code:(NSInteger)code;
- (void)acc_recordForTotalVideoDraft:(AWEStudioFeedBackStatus)status code:(NSInteger)code draftCreationData:(NSString *)creationData;

@end

FOUNDATION_STATIC_INLINE id<ACCFeedbackProtocol> ACCFeedback() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCFeedbackProtocol)];
}

NS_ASSUME_NONNULL_END
