//
//  ACCCameraMiddleware.h
//  CameraClient
//
//  Created by leo on 2019/12/12.
//

#import <Foundation/Foundation.h>

#import <CameraClient/ACCMiddleware.h>
#import <TTVideoEditor/IESMMRecoder.h>
#import <TTVideoEditor/IESMMCamera+Effect.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCCameraMiddleware : ACCMiddleware
@property (nonatomic, strong) IESMMCamera<IESMMRecoderProtocol> *camera;
@property (nonatomic, assign) BOOL disableFlashOnFrontPosition;

+ (instancetype)middlewareWithCamera:(IESMMCamera<IESMMRecoderProtocol> *)camera;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
