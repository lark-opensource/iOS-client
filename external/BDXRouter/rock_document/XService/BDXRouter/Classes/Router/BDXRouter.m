//
//  BDXRouter.m
//  Pods
//
//  Created by bill on 2021/3/22.
//

#import "BDXRouter.h"
#import <BDXServiceCenter/BDXContainerProtocol.h>
#import <BDXServiceCenter/BDXContextKeyDefines.h>
#import <BDXServiceCenter/BDXGlobalContext.h>
#import <BDXServiceCenter/BDXMonitorProtocol.h>
#import <BDXServiceCenter/BDXPageContainerProtocol.h>
#import <BDXServiceCenter/BDXPopupContainerProtocol.h>
#import <BDXServiceCenter/BDXSchemaProtocol.h>
#import <BDXServiceCenter/BDXServiceCenter.h>
#import <BDXServiceCenter/BDXServiceRegister.h>
#import <ByteDanceKit/BTDMacros.h>
#import <ByteDanceKit/BTDResponder.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSURL+BTDAdditions.h>
#import <objc/message.h>

@BDXSERVICE_REGISTER(BDXRouter)

    static NSString *BDXRouterErrorDomain = @"BDXRouterErrorDomain";

@interface BDXRouter ()

@property(nonatomic, strong) NSHashTable<id<BDXContainerProtocol>> *containers;
@property(nonatomic, assign) int currentIndex;

@end

@implementation BDXRouter

BDXSERVICE_SINGLETON_IMP

- (instancetype)init
{
    self = [super init];
    if (self) {
        _containers = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
        _currentIndex = 0;
    }

    return self;
}

+ (BDXServiceScope)serviceScope
{
    return BDXServiceScopeGlobalDefault;
}

+ (BDXServiceType)serviceType
{
    return BDXServiceTypeRouter;
}

+ (NSString *)serviceBizID
{
    return DEFAULT_SERVICE_BIZ_ID;
}

- (void)openWithUrl:(nonnull NSString *)urlString context:(BDXContext *)context completion:(nullable void (^)(id<BDXContainerProtocol>, NSError *))completion
{
    id<BDXMonitorProtocol> lifeCycleTracker = [self lifeCycleTrackerWithContext:context];
    [lifeCycleTracker trackLifeCycleWithEvent:@"router_will_handle_url"];

    NSURL *url = [NSURL URLWithString:urlString];
    NSString *host = url.host;
    NSArray *pageHosts = @[@"lynx_page", @"lynxview", @"webview_page", @"webview"];
    NSArray *popupHosts = @[@"lynx_popup", @"lynxview_popup", @"webview_popup"];
    id<BDXContainerProtocol> container = nil;
    NSString *bid = [[url btd_queryItems] btd_stringValueForKey:@"bid"];
    [context registerCopyObj:bid forKey:kBDXContextKeyBid];
    /// merge local context to global context
    context = [BDXGlobalContext mergeContext:context withBid:bid];
    if ([pageHosts containsObject:host]) {
        id<BDXPageContainerServiceProtocol> service = BDXSERVICE_WITH_DEFAULT(BDXPageContainerServiceProtocol, bid);
        container = [service open:urlString context:context];
    } else if ([popupHosts containsObject:host]) {
        id<BDXPopupContainerServiceProtocol> service = BDXSERVICE_WITH_DEFAULT(BDXPopupContainerServiceProtocol, bid);
        container = [service open:urlString context:context];
    }
    if (container) {
        objc_setAssociatedObject(container, @"__BDXRouterIndex__", [NSNumber numberWithInt:self.currentIndex++], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [_containers addObject:container];
        if (completion) {
            completion(container, nil);
        }
    }
}

- (id<BDXContainerProtocol>)containerWithUrl:(NSString *)urlString context:(BDXContext *)context autoPush:(BOOL)autoPush
{
    id<BDXMonitorProtocol> lifeCycleTracker = [self lifeCycleTrackerWithContext:context];
    [lifeCycleTracker trackLifeCycleWithEvent:@"router_will_handle_url"];

    NSURL *url = [NSURL URLWithString:urlString];
    NSString *host = url.host;
    NSArray *pageHosts = @[@"lynx_page", @"lynxview", @"webview_page", @"webview"];
    NSArray *popupHosts = @[@"lynx_popup", @"lynxview_popup", @"webview_popup"];
    id<BDXContainerProtocol> container = nil;
    NSString *bid = [[url btd_queryItems] btd_stringValueForKey:@"bid"];
    [context registerCopyObj:bid forKey:kBDXContextKeyBid];
    if ([pageHosts containsObject:host]) {
        id<BDXPageContainerServiceProtocol> service = BDXSERVICE_WITH_DEFAULT(BDXPageContainerServiceProtocol, bid);
        if (autoPush) {
            container = [service open:urlString context:context];
        } else {
            container = [service create:urlString context:context];
        }
    } else if ([popupHosts containsObject:host]) {
        id<BDXPopupContainerServiceProtocol> service = BDXSERVICE_WITH_DEFAULT(BDXPopupContainerServiceProtocol, bid);
        container = [service open:urlString context:context];
    }
    if (container) {
        return container;
    }
    return nil;
}

- (BOOL)closeWithContainerID:(NSString *)containerID params:(nullable NSDictionary *)params completion:(nullable void (^)(NSError *_Nullable))completion
{
    if (BTD_isEmptyString(containerID)) {
        NSError *error = [NSError errorWithDomain:BDXRouterErrorDomain code:0 userInfo:@{@"reason": @"containerID is empty"}];
        !completion ?: completion(error);
        return NO;
    }

    id<BDXContainerProtocol> targetContainer = [self containerWithContainerID:containerID];
    if (!targetContainer) {
        NSString *reason = [NSString stringWithFormat:@"can not find container by containerID:%@", containerID];
        NSError *error = [NSError errorWithDomain:BDXRouterErrorDomain code:0 userInfo:@{@"reason": reason}];
        !completion ?: completion(error);
        return NO;
    }

    if ([targetContainer conformsToProtocol:@protocol(BDXPageContainerProtocol)]) {
        [(id<BDXPageContainerProtocol>)targetContainer close:params];
    } else {
        [(id<BDXPopupContainerProtocol>)targetContainer close:params];
    }
    !completion ?: completion(nil);
    return YES;
}

- (nullable NSArray<id<BDXContainerProtocol>> *)routeStack
{
    NSMutableArray<id<BDXContainerProtocol>> *res = [[NSMutableArray alloc] init];
    for (id<BDXContainerProtocol> item in self.containers) {
        if ([item conformsToProtocol:@protocol(BDXPageContainerProtocol)]) {
            [res addObject:item];
        }
    }
    [res sortUsingComparator:^NSComparisonResult(NSObject *obj1, NSObject *obj2) {
        int index1 = [objc_getAssociatedObject(obj1, @"__BDXRouterIndex__") intValue];
        int index2 = [objc_getAssociatedObject(obj2, @"__BDXRouterIndex__") intValue];
        return index1 < index2;
    }];
    return res;
}

- (nullable id<BDXContainerProtocol>)containerWithContainerID:(NSString *)containerID
{
    for (id<BDXContainerProtocol> item in self.containers) {
        if ([item.containerID isEqualToString:containerID]) {
            return item;
        }
    }
    return nil;
}

- (id<BDXMonitorProtocol>)lifeCycleTrackerWithContext:(BDXContext *)context
{
    id<BDXMonitorProtocol> lifeCycleTracker = [context getObjForKey:@"lifeCycleTracker"];
    if (!lifeCycleTracker) {
        // every bdxview has its own tracker , thus init tracker manually.
        Class monitorClass = BDXSERVICE_CLASS(BDXMonitorProtocol, nil);
        lifeCycleTracker = [[monitorClass alloc] init];
        [context registerStrongObj:lifeCycleTracker forKey:@"lifeCycleTracker"];
    }

    return lifeCycleTracker;
}

@end
