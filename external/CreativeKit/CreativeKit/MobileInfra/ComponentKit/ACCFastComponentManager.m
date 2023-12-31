//
//  ACCFastComponentManager.m
//  CreativeKit-Pods-Aweme
//
//  Created by Liu Deping on 2021/2/2.
//

#import "ACCFastComponentManager.h"
#if ACC_DEBUG_MODE
#import "ACCMemoryMonitor.h"
#endif
#import "ACCFeatureComponent.h"

#ifndef acc_infra_queue_async_safe
#define acc_infra_queue_async_safe(queue, block)\
if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(queue)) {\
block();\
} else {\
dispatch_async(queue, block);\
}
#endif

#ifndef acc_infra_main_async_safe
#define acc_infra_main_async_safe(block) acc_infra_queue_async_safe(dispatch_get_main_queue(), block)
#endif

@interface ACCFastComponentManager ()

@property (nonatomic, strong) NSMutableArray *loadedComponents;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableArray<ACCFeatureComponent> *> *loadPhaseMap;
@property (nonatomic, strong) NSMapTable *lifeCycleBindings;

@property (nonatomic, strong) NSMutableArray *mountCompletions;
@property (nonatomic, strong) NSMutableArray *loadViewCompletions;
@property (nonatomic, strong) NSMutableArray *allComponents;

@property (nonatomic, assign) ACCComponentMountState mountState;
@property (nonatomic, assign) ACCComponentViewState viewState;
@property (nonatomic, assign) BOOL isStartMonitorMemory;
@property (nonatomic, copy) NSString *memoryContext;
 
@property (nonatomic, assign) BOOL forceLoaded;
@property (nonatomic, assign) ACCFeatureComponentLoadPhase currentLoadPhase;

// Need to remove in the future. It's too tricky.
@property (nonatomic, strong) NSSet<NSString *> *allowListSelectorWhenUnmounted;

@end

@implementation ACCFastComponentManager

@synthesize delegate = _delegate;
@synthesize loadPhaseDelegate = _loadPhaseDelegate;

- (instancetype)init
{
    if (self = [super init]) {
        _loadedComponents = [NSMutableArray array];
        _mountCompletions = [NSMutableArray array];
        _loadViewCompletions = [NSMutableArray array];
        _allComponents = [NSMutableArray array];
        _lifeCycleBindings = [NSMapTable strongToWeakObjectsMapTable];
        _mountState = ACCComponentMountStateMounted;
        _viewState = ACCComponentViewStateUnkown;
    }
    return self;
}

- (void)dealloc
{
    NSAssert(ACCMountStateIsUnmounted(self.mountState), @"UnmountComponents Method must be called before dealloc");
    [self unmountComponents];
}

- (void)addComponent:(id<ACCFeatureComponent>)component
{
    NSAssert(!ACCMountStateIsUnavailable(self.mountState), @"cannot add component during/after purging");
#if ACC_DEBUG_MODE
    if (!self.memoryContext && [component isKindOfClass:[ACCFeatureComponent class]]) {
        self.memoryContext = [NSString stringWithFormat:@"%@-%p", NSStringFromClass([[(ACCFeatureComponent *)component controller] class]), [(ACCFeatureComponent *)component controller]];
    }
    if (!self.isStartMonitorMemory) {
        self.isStartMonitorMemory = YES;
        [ACCMemoryMonitor startMemoryMonitorForContext:self.memoryContext tartgetClasses:[NSArray array] maxInstanceCount:1];
    }
    
    [ACCMemoryMonitor addObject:component forContext:self.memoryContext];
#endif
    ACCFeatureComponentLoadPhase phase = ACCFeatureComponentLoadPhaseLazy;
    if ([component respondsToSelector:@selector(preferredLoadPhase)]) {
        phase = [component preferredLoadPhase];
    }
    
    [self.loadPhaseMap[@(phase)] addObject:component];
    [self.allComponents addObject:component];
}

- (void)bindLife:(id)object with:(id<ACCFeatureComponent>)component
{
    [self.lifeCycleBindings setObject:component forKey:object];
}

- (void)loadComponentOfPhase:(ACCFeatureComponentLoadPhase)phase
{
    if (self.currentLoadPhase & phase) {
        return;
    }
    self.currentLoadPhase |= phase;
    NSMutableArray *componentsToLoad = self.loadPhaseMap[@(phase)] ? : [@[] mutableCopy];
        
    NSArray *loadedComponents = [componentsToLoad copy];
    if (loadedComponents.count == 0) {
        return;
    }
    [componentsToLoad removeAllObjects];
        
    acc_infra_main_async_safe(^{
        for (id<ACCFeatureComponent> aComponent in loadedComponents) {
            [self.loadedComponents addObject:aComponent];
            
            if (ACCMountStateIsUnavailable(self.mountState)) {
                return;
            }
            
            if ([aComponent respondsToSelector:@selector(componentDidMount)]) {
                [self performComponent:aComponent selector:@selector(componentDidMount)];
            }
            if ([aComponent respondsToSelector:@selector(setMounted:)]) {
                aComponent.mounted = YES;
            }
        }
        
        for (id<ACCFeatureComponent> aComponent in loadedComponents) {
            [self handleComponentAppearEvent:aComponent];
        }
        
        if (phase == ACCFeatureComponentLoadPhaseEager) {
            for (dispatch_block_t completion in self.mountCompletions) {
                completion();
            }
        }
    });
}

- (void)handleComponentAppearEvent:(id<ACCFeatureComponent>)component
{
    if (self.viewState == ACCComponentViewStateAppearing ||
        self.viewState == ACCComponentViewStateAppeared) {
        if ([component respondsToSelector:@selector(componentWillAppear)]) {
            [component componentWillAppear];
        }
    }
    if (self.viewState == ACCComponentViewStateAppeared) {
        if ([component respondsToSelector:@selector(componentDidAppear)]) {
            [component componentDidAppear];
        }
    }
}

- (void)performComponent:(id<ACCFeatureComponent>)component selector:(SEL)aSelector
{
    NSTimeInterval currentTime = CFAbsoluteTimeGetCurrent();
    if ((![component respondsToSelector:@selector(isMounted)] ||
        component.isMounted) ||
        [self.allowListSelectorWhenUnmounted containsObject:NSStringFromSelector(aSelector)]) {
        [component performSelector:aSelector];
    }
    NSTimeInterval duration = (CFAbsoluteTimeGetCurrent() - currentTime) * 1000;
    if (self.delegate) {
        [self.delegate logComponent:component selector:aSelector duration:duration];
    }
}

- (void)registerMountCompletion:(dispatch_block_t)completion
{
    if (completion) {
        [_mountCompletions addObject:completion];
    }
}

- (void)registerLoadViewCompletion:(dispatch_block_t)completion {
    if (completion) {
        [_loadViewCompletions addObject:completion];
    }
}

- (void)prepareForViewDidLoad
{
    if (self.loadPhaseDelegate && [self.loadPhaseDelegate respondsToSelector:@selector(componentManager:willLoadPhase:)]) {
        [self.loadPhaseDelegate componentManager:self willLoadPhase:ACCFeatureComponentLoadPhaseBeforeFirstRender];
    }

    [self loadComponentOfPhase:ACCFeatureComponentLoadPhaseBeforeFirstRender];
    [self loadComponentsView];
}

- (void)prepareForWillAppear
{
    self.viewState = ACCComponentViewStateAppearing;
    [self performLifeCycleSelector:@selector(componentWillAppear)];
}

- (void)prepareForDidAppear
{
    self.viewState = ACCComponentViewStateAppeared;
    [self performLifeCycleSelector:@selector(componentDidAppear)];
}

- (void)prepareForWillDisappear
{
    self.viewState = ACCComponentViewStateDisappearing;
    [self performLifeCycleSelector:@selector(componentWillDisappear)];
}

- (void)prepareForDidDisappear
{
    self.viewState = ACCComponentViewStateDisappeared;
    [self performLifeCycleSelector:@selector(componentDidDisappear)];
}

- (void)prepareForReceiveMemoryWarning
{
    [self performLifeCycleSelector:@selector(componentReceiveMemoryWarning)];
}

- (void)prepareForViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    for (id<ACCFeatureComponent> aComponent in self.allComponents) {
        dispatch_block_t block = ^{
            if ([aComponent respondsToSelector:@selector(componentWillTransitionToSize:withTransitionCoordinator:)]) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [aComponent componentWillTransitionToSize:size withTransitionCoordinator:coordinator];
                #pragma clang diagnostic pop
            }
        };
       acc_infra_main_async_safe(block);
    }
}

- (void)performLifeCycleSelector:(SEL)aSelector {
    if (ACCMountStateIsUnavailable(self.mountState)) {
        return;
    }
    for (id<ACCFeatureComponent> aComponent in self.allComponents) {
        dispatch_block_t block = ^{
            if ([aComponent respondsToSelector:aSelector]) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [self performComponent:aComponent selector:aSelector];
                #pragma clang diagnostic pop
            }
        };
       acc_infra_main_async_safe(block);
    }
}

- (void)prepareForUnmount
{
    if (ACCMountStateIsUnavailable(self.mountState)) {
        return;
    }
    
    NSArray *loadedComponents = [self.loadedComponents copy];
    
    // Call disappear methods mannually, as these methods are often used to cleanup.
    if (self.viewState < ACCComponentViewStateDisappearing) {
        for (id<ACCFeatureComponent> aComponent in loadedComponents) {
            if ([aComponent respondsToSelector:@selector(componentWillDisappear)]) {
                [aComponent componentWillDisappear];
            }
        }
    }
    
    if (self.viewState < ACCComponentViewStateDisappeared) {
        for (id<ACCFeatureComponent> aComponent in loadedComponents) {
            if ([aComponent respondsToSelector:@selector(componentDidDisappear)]) {
                [aComponent componentDidDisappear];
            }
        }
    }
    
    for (id<ACCFeatureComponent> aComponent in loadedComponents) {
        if ([aComponent respondsToSelector:@selector(componentWillUnmount)]) {
            [aComponent componentWillUnmount];
        }
    }
    
    self.mountState = ACCComponentMountStateUnmounting;
}

- (void)unmountComponents
{
    if (ACCMountStateIsUnmounted(self.mountState)) {
        return;
    }
    self.mountState = ACCComponentMountStateUnmounted;
    NSArray *loadedComponents = [self.loadedComponents copy];
#if ACC_DEBUG_MODE
    [ACCMemoryMonitor stopMemoryMonitorForContext:self.memoryContext];
#endif
    acc_infra_main_async_safe(^{
        for (id<ACCFeatureComponent> aComponent in loadedComponents) {
            if ([aComponent respondsToSelector:@selector(componentDidUnmount)]) {
                [aComponent componentDidUnmount];
#if ACC_DEBUG_MODE
                [ACCMemoryMonitor startCheckMemoryLeaks:aComponent];
#endif
            }
            if ([aComponent respondsToSelector:@selector(setMounted:)]) {
                aComponent.mounted = NO;
            }
        }
    });
}

- (void)loadComponentsView
{
    [self performLifeCycleSelector:@selector(loadComponentView)];
    for (dispatch_block_t completion in self.loadViewCompletions) {
        completion();
    }
}

- (void)finishFirstRenderTask
{
    if (self.forceLoaded) {
        return;
    }
    [self doLoadTask];
}

- (NSArray<NSNumber *> *)loadPhases
{
    return @[@(ACCFeatureComponentLoadPhaseEager), @(ACCFeatureComponentLoadPhaseLazy), @(ACCFeatureComponentLoadPhaseBeforeFirstRender)];
}

- (NSMutableDictionary<NSNumber *,NSMutableArray<ACCFeatureComponent> *> *)loadPhaseMap
{
    if (!_loadPhaseMap) {
        NSArray<NSNumber *> *loadPhases = [self loadPhases];
        _loadPhaseMap = [NSMutableDictionary dictionaryWithCapacity:loadPhases.count];
        
        for (NSNumber *phase in loadPhases) {
            _loadPhaseMap[phase] = (NSMutableArray<ACCFeatureComponent> *)[NSMutableArray arrayWithCapacity:70];
        }
    }
    
    return _loadPhaseMap;
}

- (void)doLoadTask
{
    if (self.currentLoadPhase & ACCFeatureComponentLoadPhaseEager) {
        return;
    }
    self.mountState = ACCComponentMountStateMounted;
    if (self.loadPhaseDelegate && [self.loadPhaseDelegate respondsToSelector:@selector(componentManager:willLoadPhase:)]) {
        [self.loadPhaseDelegate componentManager:self willLoadPhase:ACCFeatureComponentLoadPhaseEager];
    }
    [self loadComponentOfPhase:ACCFeatureComponentLoadPhaseEager];

    if (self.loadPhaseDelegate && [self.loadPhaseDelegate respondsToSelector:@selector(componentManager:willLoadPhase:)]) {
        [self.loadPhaseDelegate componentManager:self willLoadPhase:ACCFeatureComponentLoadPhaseLazy];
    }
    [self loadComponentOfPhase:ACCFeatureComponentLoadPhaseLazy];
}

- (void)forceLoadComponentsWhenInteracting
{
    self.forceLoaded = YES;
    [self doLoadTask];
}

- (NSSet<NSString *> *)allowListSelectorWhenUnmounted
{
    if (!_allowListSelectorWhenUnmounted) {
        _allowListSelectorWhenUnmounted = [NSSet setWithObjects:NSStringFromSelector(@selector(loadComponentView)),
                           NSStringFromSelector(@selector(componentDidMount)), nil];
    }
    return _allowListSelectorWhenUnmounted;
}

@end
