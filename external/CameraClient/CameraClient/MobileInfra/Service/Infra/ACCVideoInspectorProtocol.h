//
//  ACCVideoInspectorProtocol.h
//  AWEStudio-Pods-Aweme
//
//  Created by geekxing on 2020/12/20.
//

#import <Foundation/Foundation.h>
#import <IESVideoDetector/IESVideoDetectInputModel.h>
#import <CreativeKit/ACCServiceLocator.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCVideoInspectorProtocol <NSObject>

- (void)setup;
- (void)inspectVideo:(id<IESVideoDetectInputModelProtocol>)videoInput;

@end

FOUNDATION_STATIC_INLINE id<ACCVideoInspectorProtocol> ACCVideoInspector() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCVideoInspectorProtocol)];
}

NS_ASSUME_NONNULL_END
