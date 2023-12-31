//
//  ACCSpeedProbeProtocol.h
//  CameraClient-Pods-AwemeCore
//
//  Created by geekxing on 2021/11/4.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>

@protocol ACCSpeedProbeProtocol <NSObject>

@property (nonatomic, assign, readonly) NSInteger probeSpeed;

- (void)startIfNeeded;
- (void)stopIfNeeded;
- (BOOL)dataValid;
- (void)invalidateData;

@end

FOUNDATION_STATIC_INLINE id<ACCSpeedProbeProtocol> ACCSpeedProbe() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCSpeedProbeProtocol)];
}

