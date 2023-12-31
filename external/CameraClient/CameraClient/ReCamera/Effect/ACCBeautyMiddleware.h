//
//  ACCBeautyMiddleware.h
//  CameraClient
//
//  Created by luochaojing on 2019/12/25.
//

#import <TTVideoEditor/IESMMRecoder.h>
#import <TTVideoEditor/IESMMCamera+Effect.h>
#import <CameraClient/ACCMiddleware.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCBeautyMiddleware : ACCMiddleware

+ (ACCBeautyMiddleware *)middlewareWithCamera:(IESMMCamera<IESMMRecoderProtocol> *)camera;

@end

NS_ASSUME_NONNULL_END
