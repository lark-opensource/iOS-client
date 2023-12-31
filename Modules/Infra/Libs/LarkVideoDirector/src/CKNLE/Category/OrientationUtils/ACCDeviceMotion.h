//
//  ACCDeviceMotion.h
//  CameraClient
//
//  Created by ZhangYuanming on 2019/12/30.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCDeviceMotion;
typedef void (^ACCDeviceMotionUpdateBlock)(ACCDeviceMotion *);
@interface ACCDeviceMotion : NSObject

@property (nonatomic, readonly) UIDeviceOrientation deviceOrientation;
@property (nonatomic, copy) ACCDeviceMotionUpdateBlock updateBlock;

- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
