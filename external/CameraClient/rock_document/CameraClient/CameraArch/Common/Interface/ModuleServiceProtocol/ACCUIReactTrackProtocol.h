//
//  ACCUIReactTrackProtocol.h
//  CameraClient-Pods-AwemeCore
//
//  Created by Leon on 2021/11/5.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreativeKit/ACCToolUIReactTracker.h>


@protocol ACCUIReactTrackProtocol <NSObject>

- (NSString *)latestEventName;

- (void)eventBegin:(NSString *)event;

//Use kAWEUIEventLatestEvent to complete the latest event.
- (void)eventEnd:(NSString *)event withPublishModel:(AWEVideoPublishViewModel *)publishModel;

@end

FOUNDATION_STATIC_INLINE id<ACCUIReactTrackProtocol> ACCToolUIReactTrackService() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCUIReactTrackProtocol)];
}

