//
// ACCDuetTemplateFetchProtocol.h
// CameraClient-Pods-AwemeCore
//
// Created by bytedance on 2021/10/22.
//

#import <Foundation/Foundation.h>
#import <IESInject/IESServiceContainer.h>
#import <CameraClient/ACCDuetTemplateDataControllerProtocol.h>
#import <CameraClient/ACCAwemeModelProtocolD.h>
#import <CreativeKit/ACCServiceLocator.h>


@protocol ACCDuetTemplateFetchProtocol <NSObject>
@property (nonatomic, assign, readonly) NSUInteger fetchCountPerRequest;

- (void)loadmoreDuetTemplatesWithCursor:(NSNumber * _Nonnull)cursor
                              fromScene:(ACCDuetSingSceneType)scene
                             completion:(void(^)(NSError * _Nullable error,
                                                 NSArray<id<ACCAwemeModelProtocolD>> * _Nullable templates,
                                                 BOOL hasMore,
                                                 NSNumber *cursor))completion;

- (void)refreshDuetTemplatesFromScene:(ACCDuetSingSceneType)scene
                           completion:(void(^)(NSError * _Nullable error,
                                               NSArray<id<ACCAwemeModelProtocolD>> * _Nullable templates,
                                               BOOL hasMore,
                                               NSNumber *cursor))completion;
@end

FOUNDATION_STATIC_INLINE id<ACCDuetTemplateFetchProtocol> ACCDuetTemplateFetch() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCDuetTemplateFetchProtocol)];
}


