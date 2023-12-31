//
//  ACCBusinessConfiguration.h
//  CameraClient
//
//  Created by Liu Deping on 2020/7/10.
//

#import <Foundation/Foundation.h>
#import <IESInject/IESInject.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCBusinessTemplate;
@protocol ACCRouterCoordinatorProtocol;

@class AWEVideoPublishViewModel;

@protocol ACCBusinessInputData <NSObject>

@property (nonatomic, strong, readonly) AWEVideoPublishViewModel *publishModel;

- (NSString *)createId;

@end

@protocol ACCBusinessConfiguration <NSObject>

@property (nonatomic, strong) id inputData;

- (id<ACCBusinessTemplate>)businessTemplate;
 
- (id<IESServiceRegister, IESServiceProvider>)businessServiceContainerWithSessionContainer:(id<IESServiceRegister, IESServiceProvider>)sessionContainer;

- (nullable id<ACCRouterCoordinatorProtocol>)routerCoordinator;

@end

FOUNDATION_EXPORT id<ACCBusinessConfiguration, NSCopying> ACCBusinessConfigurationCached(id<ACCBusinessConfiguration> config, id<IESServiceRegister, IESServiceProvider> parentContainer);

NS_ASSUME_NONNULL_END
