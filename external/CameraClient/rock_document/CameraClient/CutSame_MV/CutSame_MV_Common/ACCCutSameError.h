//
//  ACCCutSameError.h
//  CameraClient-Pods-Aweme
//
//  Created by LeonZou on 2020/10/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString *const ACCCutSameErrorDomain;

// User Info Key

FOUNDATION_EXTERN NSString *const ACCCutSameErrorUserInfoCartoonFaceFailCount;

/*
 Error code format: abc-xx
 abc -> domain
 xx -> code
 */

typedef NS_ENUM(NSUInteger, ACCCutSameErrorCode) {
    // fail to upload pic to server when use CartoonFace template
    ACCCutSameErrorCodeUploadToServerFailedForCartoonFace = 10001,
        
    // CartoonFace procession is canceled by user manually
    ACCCutSameErrorCodeCancelProcessCartoonFaceByUser,
};

NS_ASSUME_NONNULL_END
