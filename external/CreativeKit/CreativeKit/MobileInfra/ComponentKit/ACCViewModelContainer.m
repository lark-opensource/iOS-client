//
//  ACCViewModelStore.m
//  Pods
//
//  Created by leo on 2020/2/5.
//

#import "ACCViewModelContainer.h"
#import "ACCViewModelFactory.h"

#if ACC_DEBUG_MODE
#import "ACCMemoryMonitor.h"
#endif

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

@interface ACCViewModelContainer ()

@property (nonatomic, strong) ACCViewModelFactory *factory;
@property (nonatomic, strong) NSMutableDictionary *viewModels;
@property (nonatomic, assign) BOOL isCleared;

@end

@implementation ACCViewModelContainer

- (instancetype)initWithFactory:(id<ACCViewModelFactory>)factory
{
    self = [super init];
    if (self) {
        _viewModels = [NSMutableDictionary dictionary];
        _factory = factory;
    }
    return self;
}

- (void)dealloc
{
    NSAssert(self.isCleared == YES, @"Clear Method must be called before dealloc");
    [self clear];
}

- (id<ACCViewModel>)getViewModel:(Class)viewModelClass
{
    NSString *key = NSStringFromClass(viewModelClass);
    id<ACCViewModel> cached = [self.viewModels objectForKey:key];
    if (cached != nil) {
        return cached;
    }
    cached = [self.factory createViewModel:viewModelClass];
    if (cached != nil) {
        [self putViewModel:cached];
    }
    return cached;
}

- (void)putViewModel:(id<ACCViewModel>)viewModel
{
    NSAssert([viewModel conformsToProtocol:@protocol(ACCViewModel)], @"viewModel should confirms to ACCViewModel protocol");
    NSString *key = NSStringFromClass(viewModel.class);
    
    id<ACCViewModel> oldModel = [self.viewModels objectForKey:key];
    if (oldModel) {
        [oldModel onCleared];
    }

    [self.viewModels setObject:viewModel forKey:key];
}

- (void)clear
{
    if (self.isCleared) {
        return;
    }
    self.isCleared = YES;
    acc_infra_main_async_safe(^{
        NSArray *liveViewModels = [self.viewModels allValues];
        [self.viewModels removeAllObjects];
        
        for (id<ACCViewModel> aViewModel in liveViewModels) {
            if ([aViewModel respondsToSelector:@selector(onCleared)]) {
                [aViewModel onCleared];
            }
#if ACC_DEBUG_MODE
            [ACCMemoryMonitor startCheckMemoryLeaks:aViewModel];
#endif
        }
    });
}
@end
