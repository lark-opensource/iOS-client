//
//  ACCViewController.m
//  CameraClient
//
//  Created by Liu Deping on 2020/7/10.
//

#import "ACCRouterCoordinatorProtocol.h"
#import "ACCViewModelContainerHolder.h"
#import "ACCViewController.h"
#import "ACCViewModelFactory.h"
#import "ACCComponentsFactory.h"
#import "ACCComponentViewModelProvider.h"
#import "ACCCreativePathManagable.h"
#import "ACCServiceLocator.h"
#import "ACCPadUIAdapter.h"
#import <IESInject/IESInject.h>

#ifndef ACCSafeForwardedClass
#define ACCSafeForwardedClass(s) (((void)(NO && (s *)nil)), NSClassFromString(@#s))
#endif

// let
#if defined(__cplusplus)
#define let auto const
#else
#define let const __auto_type
#endif

// weakify
#ifndef btd_keywordify
#if DEBUG
    #define btd_keywordify autoreleasepool {}
#else
    #define btd_keywordify try {} @catch (...) {}
#endif
#endif

#ifndef weakify
    #if __has_feature(objc_arc)
        #define weakify(object) btd_keywordify __weak __typeof__(object) weak##_##object = object;
    #else
        #define weakify(object) btd_keywordify __block __typeof__(object) block##_##object = object;
    #endif
#endif

#ifndef strongify
    #if __has_feature(objc_arc)
        #define strongify(object) btd_keywordify __typeof__(object) object = weak##_##object;
    #else
        #define strongify(object) btd_keywordify __typeof__(object) object = block##_##object;
    #endif
#endif

@interface ACCViewController ()<ACCComponentManagerLoadPhaseDelegate>

@property (nonatomic, strong) id<IESServiceRegister, IESServiceProvider> businessServiceContainer;
@property (nonatomic, strong) id<IESServiceProvider> serviveProvider;
@property (nonatomic, strong) id<ACCComponentManager> componentManager;
@property (nonatomic, strong) ACCViewModelContainer *viewModelContainer;
@property (nonatomic, strong) ACCComponentsFactory *componentFactory;
@property (nonatomic, strong) id<ACCBusinessConfiguration> business;
@property (nonatomic, strong) NSNumber *startLoadUITime;
@property (nonatomic, strong) NSNumber *endLoadUITime;

@property (nonatomic, strong) NSHashTable *routerServiceSubscribers;

@property (nonatomic, strong) ACCSessionServiceContainer *sessionContainer;
@property (nonatomic, strong) id<IESServiceRegister, IESServiceProvider> pageServiceContainer;//provides service that businessServiceContainer need use, external business will not be aware of it
@end

@implementation ACCViewController

@synthesize routerAnimated = _routerAnimated;

- (void)dealloc
{
    [self.componentManager prepareForUnmount];
    [self.componentManager unmountComponents];
    [self.viewModelContainer clear];
}

- (instancetype)initWithBusinessConfiguration:(id<ACCBusinessConfiguration>)business
{
    if (self = [super init]) {
        _routerAnimated = YES;
        _sessionContainer = [ACCCreativePath() sessionContainerWithCreateId:((id<ACCBusinessInputData>)business.inputData).createId saveHolder:self];
        
        _pageServiceContainer = [[IESContainer alloc] initWithParentContainer:_sessionContainer ?: ACCBaseContainer()];
        _business = ACCBusinessConfigurationCached(business, _pageServiceContainer);
        self.businessServiceContainer = [_business businessServiceContainerWithSessionContainer:_pageServiceContainer];
        [self configBusinessServiceContainer];
        
        IESContainer *parentContext = [[IESContainer alloc] init];
        id<ACCBusinessInputData> inputData = [_business inputData];
        
        _serviveProvider = self.businessServiceContainer;
        _componentManager = [self creatComponentManager];
        
        NSAssert([inputData conformsToProtocol:@protocol(ACCBusinessInputData)], @"input data should conforms to ACCBusinessInputData");
        
        if (inputData != nil) {
            [parentContext registerInstance:inputData forProtocol:@protocol(ACCBusinessInputData)];
            AWEVideoPublishViewModel *publishModel = inputData.publishModel;
            if (publishModel != nil) {
                [parentContext registerInstance:publishModel forClass:ACCSafeForwardedClass(AWEVideoPublishViewModel)];
            }
        }
        
        IESContainer *viewModelContext = [[IESContainer alloc] initWithParentContainer:parentContext];
        [viewModelContext registerInstance: self.businessServiceContainer forProtocol:@protocol(IESServiceProvider)];
        ACCViewModelFactory *viewModelFactory = [[ACCViewModelFactory alloc] initWithContext:viewModelContext];
        
        ACCViewModelContainer *viewModelContainer = [[ACCViewModelContainer alloc] initWithFactory:viewModelFactory];
        _viewModelContainer = viewModelContainer;
        
        @weakify(self);
        IESContainer *componentContext = [[IESContainer alloc] initWithParentContainer:parentContext];
        [componentContext registerProvider:^id {
            @strongify(self);
            return self;
        } forProtocol:@protocol(ACCComponentController) scope:(IESInjectScopeTypeWeak)];
        [componentContext registerProvider:^id {
            @strongify(self);
            return self.componentManager;
        } forProtocol:@protocol(ACCComponentManager) scope:(IESInjectScopeTypeWeak)];
        [componentContext registerInstance:[_business businessTemplate] forProtocol:@protocol(ACCBusinessTemplate)];
        [componentContext registerInstance:viewModelFactory forProtocol:@protocol(ACCViewModelFactory)];
        [componentContext registerInstance:viewModelContainer forProtocol:@protocol(ACCComponentViewModelProvider)];
        [componentContext registerInstance:self.businessServiceContainer forProtocol:@protocol(IESServiceProvider)];
        [componentContext registerInstance:self.businessServiceContainer forProtocol:@protocol(IESServiceRegister)];
        ACCComponentsFactory *componentFactory = [[ACCComponentsFactory alloc] initWithContext:componentContext];
        [componentFactory loadComponents];
        self.componentFactory = componentFactory;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self prepareForLoadComponent];
    self.startLoadUITime = @(CACurrentMediaTime()*1000.0);
    [self.componentManager prepareForViewDidLoad];
    self.endLoadUITime = @(CACurrentMediaTime()*1000.0);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.componentManager prepareForWillAppear];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setNeedsStatusBarAppearanceUpdate];
    [self.componentManager prepareForDidAppear];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.componentManager prepareForWillDisappear];
    [ACCPadUIAdapter setIPadScreenWidth:0.f];
    [ACCPadUIAdapter setIPadScreenHeight:0.f];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.componentManager prepareForDidDisappear];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self.componentManager prepareForWillLayoutSubviews];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self.componentManager prepareForDidLayoutSubviews];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self.componentManager prepareForViewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [ACCPadUIAdapter setIPadScreenWidth:size.width];
    [ACCPadUIAdapter setIPadScreenHeight:size.height];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - ACCComponentManagerLoadPhaseDelegate

- (void)componentManager:(id<ACCComponentManager>)manager willLoadPhase:(ACCFeatureComponentLoadPhase)phase
{
    if (phase == ACCFeatureComponentLoadPhaseBeforeFirstRender) {
        [self beforeLoadBeforeFirstRenderComponent];
    }else if (phase == ACCFeatureComponentLoadPhaseEager) {
        [self beforeLoadEagerComponent];
    }else if (phase == ACCFeatureComponentLoadPhaseLazy) {
        [self beforeLoadLazyComponent];
    }
}

#pragma mark - ACCViewController

- (id<ACCComponentManager>_Nonnull)creatComponentManager
{
    ACCComponentManager *componentManager = [[ACCComponentManager alloc] init];
    componentManager.loadPhaseDelegate = self;
    return componentManager;
}

-(NSTimeInterval)loadPageUICost
{
    NSTimeInterval timeInterval = [self.endLoadUITime doubleValue] - [self.startLoadUITime doubleValue];
    return timeInterval;
}

- (void)prepareForLoadComponent
{
    
}

- (void)beforeLoadBeforeFirstRenderComponent
{

}

- (void)beforeLoadEagerComponent
{
    
}

- (void)beforeLoadLazyComponent
{
    
}

- (id)handleTargetViewControllerInputData
{
    return nil;
}

- (BOOL)enableFirstRenderOptimize
{
    return NO;
}

- (void)popSelf
{
    if ([[self.navigationController viewControllers] firstObject] == self || !self.navigationController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - ACCComponentController

- (UIViewController *)root {
    return self;
}

- (void)close
{
    [self.componentManager prepareForUnmount];
    [self popSelf];
    [self.componentManager unmountComponents];
    [self.viewModelContainer clear];
}

- (id)getViewModel:(Class)clazz
{
    return [self.viewModelContainer getViewModel:clazz];
}

- (void)controllerTaskFinished
{
    let routerCoordinator = [self.business routerCoordinator];
    routerCoordinator.sourceViewController = self;
    routerCoordinator.sourceViewControllerInputData = self.inputData;
    id targetViewControllerInputData = [routerCoordinator handleTargetViewControllerInputData];
    for (id<ACCRouterServiceSubscriber> subscriber in self.routerServiceSubscribers) {
        if ([subscriber respondsToSelector:@selector(processedTargetVCInputDataFromData:)]) {
            targetViewControllerInputData = [subscriber processedTargetVCInputDataFromData:targetViewControllerInputData];
        }
    }
    routerCoordinator.targetViewControllerInputData = targetViewControllerInputData;
    @weakify(routerCoordinator);
    [routerCoordinator routeWithAnimated:self.routerAnimated completion:^{
        @strongify(routerCoordinator);
        routerCoordinator.targetViewControllerInputData = nil;
    }];
}

- (id)inputData
{
    return [self.business inputData];
}

#pragma mark - private

- (void)configBusinessServiceContainer
{
    @weakify(self);
    [_pageServiceContainer registerProvider:^id _Nonnull{
        @strongify(self);
        return self;
    } forProtocol:@protocol(ACCUIViewControllerProtocol) scope:IESInjectScopeTypeWeak];
    
    [_pageServiceContainer registerProvider:^id _Nonnull{
        @strongify(self);
        return self.inputData;
    } forProtocol:@protocol(ACCBusinessInputData) scope:IESInjectScopeTypeWeak];
    
    [_pageServiceContainer registerProvider:^id _Nonnull{
        @strongify(self);
        return self;
    } forProtocol:@protocol(ACCRouterService) scope:IESInjectScopeTypeWeak];
}

#pragma mark - ACCRouterService

- (void)addSubscriber:(id<ACCRouterServiceSubscriber>)subscriber
{
    if ([self.routerServiceSubscribers containsObject:subscriber]) {
        return;
    }
    [self.routerServiceSubscribers addObject:subscriber];
}

- (void)removeSubscriber:(id<ACCRouterServiceSubscriber>)subscriber
{
    if (![self.routerServiceSubscribers containsObject:subscriber]) {
        return;
    }
    [self.routerServiceSubscribers removeObject:subscriber];
}

- (NSHashTable *)routerServiceSubscribers
{
    if (!_routerServiceSubscribers) {
        _routerServiceSubscribers = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    return _routerServiceSubscribers;
}

@end
