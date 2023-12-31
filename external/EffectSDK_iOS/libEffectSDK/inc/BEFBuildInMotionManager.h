#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>

typedef void (^BEFDeviceMotionUpdatBlock)(CMDeviceMotion*);

@interface BEFBuildInMotionManager : NSObject

- (instancetype)init;

- (void)startDetectDeviceMotion:(BEFDeviceMotionUpdatBlock)block;

- (void)stopDetectDeviceMotion;

@end
