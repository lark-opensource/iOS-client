//
//  ACCVideoPublishProtocol.h
//  CameraClient
//
//  Created by xiaojuan on 2020/6/10.
//
#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCVideoPublishProtocol <NSObject>
- (void)startMusicReplaceForVideoWithPublishModel:(AWEVideoPublishViewModel *)publishModel;
- (NSInteger)publishTaskCount;
- (BOOL)hasTaskExecuting;
- (NSString *)uploadClientOptParams;


@end

FOUNDATION_STATIC_INLINE id<ACCVideoPublishProtocol> ACCVideoPublish() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCVideoPublishProtocol)];
}

NS_ASSUME_NONNULL_END
