//
//  AWEStudioSpringDefine.h
//  CameraClient
//
//  Created by lixingdong on 2019/11/8.
//

#ifndef AWEStudioSpringDefine_h
#define AWEStudioSpringDefine_h

typedef NS_ENUM(NSUInteger, AWEPublishShareResult) {
    AWEPublishShareResultSuccess,
    AWEPublishShareResultError,
    AWEPublishShareResultCancel,
};

typedef void(^AWEPublishShareCompletionBlock)(AWEPublishShareResult res, NSError * _Nullable error);

#endif /* AWEStudioSpringDefine_h */
