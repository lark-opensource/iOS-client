//
//  ACCRecorderMiddleware.h
//  CameraClient
//
//  Created by lxp on 2019/12/23.
//

#import <CameraClient/ACCMiddleware.h>
#import <TTVideoEditor/IESMMRecoder.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCRecorderMiddleware : ACCMiddleware

+ (instancetype)middlewareWithCamera:(IESMMCamera<IESMMRecoderProtocol> *)camera;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
