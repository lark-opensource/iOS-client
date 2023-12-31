//
//  ACCComponentManager.m
//  Pods
//
//  Created by DING Leo on 2020/2/6.
//

#import "ACCComponentManager.h"
#if ACC_DEBUG_MODE
#import "ACCMemoryMonitor.h"
#endif
#import "ACCFeatureComponent.h"
#import "ACCFeatureComponentPlugin.h"

#import <objc/runtime.h>

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

@interface ACCMulticastProxy : NSProxy

- (instancetype)initWithProtocol:(Protocol *)proto targets:(id<NSFastEnumeration>(^)(SEL selector))targets;

@end

@interface ACCMulticastProxy ()

@property (nonatomic) Protocol *proto;
@property (nonatomic) id<NSFastEnumeration>(^targets)(SEL selector);

@end

@implementation ACCMulticastProxy

- (instancetype)initWithProtocol:(Protocol *)proto targets:(id<NSFastEnumeration>(^)(SEL selector))targets
{
    _proto = proto;
    _targets = targets;
    return self;
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    return protocol_conformsToProtocol(self.proto, aProtocol);
}

+ (struct objc_method_description)methodSignatureOfProtocol:(Protocol *)proto with:(SEL)sel
{
    struct objc_method_description desc = protocol_getMethodDescription(proto, sel, YES, YES);
    if (desc.name == NULL) {
        desc = protocol_getMethodDescription(proto, sel, NO, YES);
    }
    return desc;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    struct objc_method_description desc = [ACCMulticastProxy methodSignatureOfProtocol:self.proto with:aSelector];
    return desc.name != NULL;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    struct objc_method_description desc = [ACCMulticastProxy methodSignatureOfProtocol:self.proto with:sel];
    NSMethodSignature *sign = [NSMethodSignature signatureWithObjCTypes:desc.types];
    return sign;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    for (id target in self.targets(invocation.selector)) {
        if ([target respondsToSelector:invocation.selector]) {
            [invocation invokeWithTarget:target];
        }
    }
}

@end

@interface ACCComponentManager()
@property (nonatomic, strong) NSMutableArray *loadedComponents;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableArray<ACCFeatureComponent> *> *loadPhaseMap;
@property (nonatomic, strong) NSMapTable *lifeCycleBindings;

@property (nonatomic, strong) NSMutableArray *mountCompletions;

@property (nonatomic, assign) ACCComponentMountState mountState;
@property (nonatomic, assign) ACCComponentViewState viewState;

@property (nonatomic, assign) BOOL isStartMonitorMemory;
@property (nonatomic, copy) NSString *memoryContext;
 
@property (nonatomic, strong) id<ACCFeatureComponent> componentsProxy;

@end

@implementation ACCComponentManager

@synthesize delegate = _delegate;
@synthesize loadPhaseDelegate = _loadPhaseDelegate;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _loadedComponents = [NSMutableArray array];
        _mountCompletions = [NSMutableArray array];
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
    NSAssert(ACCMountStateIsUnavailable(self.mountState) == NO, @"cannot add component during/after purging");
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
}

- (void)bindLife:(id)object with:(id<ACCFeatureComponent>)component
{
    [self.lifeCycleBindings setObject:component forKey:object];
}

- (void)loadComponentOfPhase:(ACCFeatureComponentLoadPhase)phase
{
    NSMutableArray *componentsToLoad = self.loadPhaseMap[@(phase)] ? : [@[] mutableCopy];
        
    NSArray *loadedComponents = [componentsToLoad copy];
    [componentsToLoad removeAllObjects];
        
    if (phase == ACCFeatureComponentLoadPhaseEager) {
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

            for (dispatch_block_t completion in self.mountCompletions) {
                completion();
            }
        });
    } else {
        dispatch_group_t group = dispatch_group_create();

        for (id<ACCFeatureComponent> aComponent in loadedComponents) {
            dispatch_group_async(group, dispatch_get_main_queue(), ^{
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
            });
        }
        
        for (id<ACCFeatureComponent> aComponent in loadedComponents) {
            dispatch_group_async(group, dispatch_get_main_queue(), ^{
                [self handleComponentAppearEvent:aComponent];
            });
        }

        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            if (phase == ACCFeatureComponentLoadPhaseEager) {
                for (dispatch_block_t completion in self.mountCompletions) {
                    completion();
                }
            }
        });
    }
}

- (void)performComponent:(id<ACCFeatureComponent>)component selector:(SEL)aSelector
{
    NSTimeInterval currentTime = CFAbsoluteTimeGetCurrent();
    [component performSelector:aSelector];
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

- (void)registerLoadViewCompletion:(dispatch_block_t)completion
{
    [self registerMountCompletion:completion];
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

- (void)prepareForViewDidLoad
{
    if (self.loadPhaseDelegate && [self.loadPhaseDelegate respondsToSelector:@selector(componentManager:willLoadPhase:)]) {
        [self.loadPhaseDelegate componentManager:self willLoadPhase:ACCFeatureComponentLoadPhaseEager];
    }
    [self loadComponentOfPhase:ACCFeatureComponentLoadPhaseEager];
}

- (void)prepareForWillAppear
{
    self.viewState = ACCComponentViewStateAppearing;
    [self.componentsProxy componentWillAppear];
}

- (void)prepareForDidAppear
{
    if (self.loadPhaseDelegate && [self.loadPhaseDelegate respondsToSelector:@selector(componentManager:willLoadPhase:)]) {
        [self.loadPhaseDelegate componentManager:self willLoadPhase:ACCFeatureComponentLoadPhaseLazy];
    }
    [self loadComponentOfPhase:ACCFeatureComponentLoadPhaseLazy];
    self.viewState = ACCComponentViewStateAppeared;
    [self.componentsProxy componentDidAppear];
}

- (void)prepareForWillDisappear
{
    self.viewState = ACCComponentViewStateDisappearing;
    [self.componentsProxy componentWillDisappear];
}

- (void)prepareForDidDisappear
{
    self.viewState = ACCComponentViewStateDisappeared;
    [self.componentsProxy componentDidDisappear];
}

- (void)prepareForReceiveMemoryWarning
{
    [self.componentsProxy componentReceiveMemoryWarning];
}

- (void)prepareForWillLayoutSubviews
{
    [self.componentsProxy componentWillLayoutSubviews];
}

- (void)prepareForDidLayoutSubviews
{
    [self.componentsProxy componentDidLayoutSubviews];
}

- (void)prepareForViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    acc_infra_main_async_safe(^{
        [self.componentsProxy componentWillTransitionToSize:size withTransitionCoordinator:coordinator];
    });
}

- (void)performLifeCycleSelector:(SEL)aSelector {
    for (id<ACCFeatureComponent> aComponent in self.loadedComponents) {
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
    
    // Call disappear methods mannually, as these methods are often used to cleanup.
    if (self.viewState < ACCComponentViewStateDisappearing) {
        [self.componentsProxy componentWillDisappear];
    }
    if (self.viewState < ACCComponentViewStateDisappeared) {
        [self.componentsProxy componentDidDisappear];
    }
    
    [self.componentsProxy componentWillUnmount];
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

- (id<ACCFeatureComponent>)componentsProxy
{
    if (!_componentsProxy) {
        __weak typeof(self) wself = self;
        _componentsProxy = (id<ACCFeatureComponent>)[[ACCMulticastProxy alloc] initWithProtocol:@protocol(ACCFeatureComponent) targets:^id<NSFastEnumeration>(SEL selector){
            __strong typeof(wself) sself = wself;
            if (sself == nil ||
                (ACCMountStateIsUnavailable(sself.mountState))) {
                return nil;
            }
            return [sself.loadedComponents filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id _Nullable evaluatedObject, NSDictionary<NSString *, id> * _Nullable bindings) {
                id<ACCFeatureComponent> obj = evaluatedObject;
                return (![obj respondsToSelector:@selector(isMounted)] ||
                obj.isMounted);
            }]];
        }];
    }
    return _componentsProxy;
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

@end

