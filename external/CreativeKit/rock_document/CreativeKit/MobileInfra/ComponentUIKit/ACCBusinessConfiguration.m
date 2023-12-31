//
//  ACCBusinessConfiguration.m
//  CreativeKit-Pods-Aweme
//
//  Created by Howie He on 2021/6/9.
//

#import "ACCBusinessConfiguration.h"


@interface ACCBusinessConfigurationCache : NSObject <ACCBusinessConfiguration, NSCopying>

@property (nonatomic, strong) id inputData;

@property (nonatomic, strong) id<ACCBusinessTemplate> businessTemplate;
@property (nonatomic, strong) id<IESServiceRegister, IESServiceProvider> businessServiceContainer;
@property (nonatomic, strong, nullable) id<ACCRouterCoordinatorProtocol> routerCoordinator;
@property (nonatomic, weak) id<IESServiceRegister,IESServiceProvider> parentContainer;

@end

@implementation ACCBusinessConfigurationCache

- (instancetype)initWithConfig:(id<ACCBusinessConfiguration>)config parentContainer:(id<IESServiceRegister, IESServiceProvider>)parentContainer
{
    if (self = [super init]) {
        _parentContainer = parentContainer;
        _inputData = [config inputData];
        _businessTemplate = [config businessTemplate];
        _businessServiceContainer = [config businessServiceContainerWithSessionContainer:self.parentContainer];
        _routerCoordinator = [config routerCoordinator];
    }
    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    ACCBusinessConfigurationCache *newInstance = [[ACCBusinessConfigurationCache allocWithZone:zone] initWithConfig:self parentContainer:self.parentContainer];
    return newInstance;
}

- (id<IESServiceRegister,IESServiceProvider>)businessServiceContainerWithSessionContainer:(id<IESServiceRegister,IESServiceProvider>)sessionContainer
{
    return _businessServiceContainer;
}

@end

id<ACCBusinessConfiguration, NSCopying> ACCBusinessConfigurationCached(id<ACCBusinessConfiguration> config, id<IESServiceRegister, IESServiceProvider> parentContainer)
{
    return [[ACCBusinessConfigurationCache alloc] initWithConfig:config parentContainer:parentContainer];
}
