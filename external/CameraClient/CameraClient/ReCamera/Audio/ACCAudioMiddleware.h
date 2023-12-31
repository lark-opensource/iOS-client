//
//  ACCAudioMiddleware.h
//  CameraClient
//
//  Created by ZhangYuanming on 2020/1/8.
//

#import <CameraClient/ACCMiddleware.h>

NS_ASSUME_NONNULL_BEGIN

@class IESMMCamera;
@protocol IESMMRecoderProtocol;

@interface ACCAudioMiddleware : ACCMiddleware

+ (ACCAudioMiddleware *)middlewareWithCamera:(IESMMCamera<IESMMRecoderProtocol> *)camera;

@end

NS_ASSUME_NONNULL_END
