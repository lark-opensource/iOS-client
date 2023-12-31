//
//  ACCMusicMiddleware.h
//  CameraClient
//
//  Created by Liu Deping on 2020/1/14.
//

#import <Foundation/Foundation.h>
#import <CameraClient/ACCMiddleware.h>
#import <TTVideoEditor/IESMMRecoder.h>
#import <TTVideoEditor/IESMMCamera+Effect.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCMusicMiddleware : ACCMiddleware

@property (nonatomic, strong) IESMMCamera<IESMMRecoderProtocol> *camera;

+ (instancetype)middlewareWithCamera:(IESMMCamera<IESMMRecoderProtocol> *)camera;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
