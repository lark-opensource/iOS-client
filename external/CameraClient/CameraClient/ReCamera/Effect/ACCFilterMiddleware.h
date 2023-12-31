//
//  ACCFilterMiddleware.h
//  CameraClient
//
//  Created by 郝一鹏 on 2020/1/13.
//

#import <CameraClient/ACCMiddleware.h>
#import <TTVideoEditor/IESMMRecoder.h>
#import <TTVideoEditor/IESMMCamera+Effect.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCFilterMiddleware : ACCMiddleware

@property (nonatomic, strong) IESMMCamera<IESMMRecoderProtocol> *camera;

@end

NS_ASSUME_NONNULL_END
