//
//  ACCSelfieImageProcessAndUploadService.h
//  CameraClient-Pods-Aweme
//
//  Created by liujingchuan on 2021/9/9.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, ACCUploadFaceResultType) {
    ACCUploadFaceResultTypeUnknow = 0,
    ///上传成功
    ACCUploadFaceResultTypeUploadSuccess,
    ///上传失败
    ACCUploadFaceResultTypeUploadFailed,
    ///审核成功
    ACCUploadFaceResultTypeReviewSuccess,
    ///审核失败
    ACCUploadFaceResultTypeReviewFailed
};

@protocol ACCSelfieImageProcessAndUploadProtocol <NSObject>

- (void)uploadImage:(UIImage * _Nonnull)image andVerfyWithCompletion:( void(^_Nullable)(NSError *error, ACCUploadFaceResultType type))completion;

@end

@interface ACCSelfieImageProcessAndUploadService : NSObject <ACCSelfieImageProcessAndUploadProtocol>

@end

