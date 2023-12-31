//
//  ACCFeatureComponent.m
//  Pods
//
//  Created by leo on 2020/2/5.
//

#import "ACCFeatureComponent.h"

@interface ACCFeatureComponent ()

@property (nonatomic, weak) id<IESServiceProvider> context;

@end

@implementation ACCFeatureComponent

@synthesize controller = _controller;
@synthesize modelFactory = _modelFactory;
@synthesize serviceProvider = _serviceProvider;
@synthesize repository = _repository;

IESRequiredInject(self.context, controller, ACCComponentController)
IESRequiredInject(self.context, modelFactory, ACCViewModelFactory)
IESRequiredInject(self.context, serviceProvider, IESServiceProvider)
IESRequiredInjectClass(self.context, repository, AWEVideoPublishViewModel)

- (instancetype)initWithContext:(id<IESServiceProvider>)context
{
    if (self = [super init]) {
        _context = context;
    }
    return self;
}

- (__kindof id<ACCViewModel>)getViewModel:(Class)viewModelClass
{
    id<ACCComponentViewModelProvider> viewModelProvider = IESRequiredInline(self.context, ACCComponentViewModelProvider);
    return [viewModelProvider getViewModel:viewModelClass];
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
}

@synthesize mounted = _mounted;

@end
