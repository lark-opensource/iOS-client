//
//  ACCCreativePathManager.m
//  CameraClient-Pods-Aweme
//
//  Created by Fengfanhua.byte on 2020/12/29.
//

#import "ACCCreativePathManager.h"
#import "UIViewController+AWECreativePath.h"
#import "ACCCreativePathMessage.h"
#import <CreativeKit/ACCCreativeSession.h>
#import <CreativeKit/ACCSessionServiceContainer.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <HTSServiceKit/HTSMessageCenter.h>

NSString * const kACCCreativePathEnterNotification = @"kACCCreativePathEnterNotification";
NSString * const kACCCreativePathExitNotification = @"kACCCreativePathExitNotification";

@interface ACCCreativePathManager ()

@property (nonatomic, assign) BOOL flag;
@property (nonatomic, strong) NSPointerArray *observers;
@property (nonatomic, assign, readwrite) ACCCreativePage currentPage;
@property (nonatomic, strong) NSMapTable *sessionContainersMap;


@end

@implementation ACCCreativePathManager

+ (instancetype)manager
{
    static dispatch_once_t onceToken;
    static ACCCreativePathManager *shared;
    dispatch_once(&onceToken, ^{
        shared = [[ACCCreativePathManager alloc] init];
    });
    return shared;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _flag = NO;
        _observers = [NSPointerArray weakObjectsPointerArray];
        _sessionContainersMap = [NSMapTable strongToWeakObjectsMapTable];
    }
    return self;
}

- (ACCSessionServiceContainer *)sessionContainerWithCreateId:(NSString *)createId
{
    return [self sessionContainerWithCreateId:createId saveHolder:nil];
}

- (ACCSessionServiceContainer *)sessionContainerWithCreateId:(NSString *)createId saveHolder:(id)holder
{
    ACCSessionServiceContainer *container = [self.sessionContainersMap objectForKey:createId];
    if (container) {
        if (holder != nil) {
            [container.session addHolder:holder];
        }
        return container;
    }
    
    @autoreleasepool {
        ACCSessionServiceContainer *container = [[ACCSessionServiceContainer alloc] initWithParentContainer:ACCBaseContainer()];
        container.session = [[ACCCreativeSession alloc] initWithCreateId:createId];
        if (holder != nil) {
            [container.session addHolder:holder];
        }
        [self.sessionContainersMap setObject:container forKey:createId];
        return container;
    }
}

- (NSArray<ACCSessionServiceContainer *> *)allSessionContainers
{
    return [NSArray arrayWithArray:self.sessionContainersMap.objectEnumerator.allObjects];
}

- (void)checkWindow
{
    @synchronized (self.observers) {
        BOOL onWindow = NO;
        ACCCreativePage page = ACCCreativePageNone;
        @autoreleasepool {
            NSArray *validObserver = [self.observers allObjects];
            for (AWECreativePathObserverViewController *observer in validObserver) {
                if ([observer isKindOfClass:[AWECreativePathObserverViewController class]]) {
                    if (observer.onWindow) {
                        if (observer.page != ACCCreativePageNone) {
                            page = observer.page; //取最后一个在window上的page
                        }
                        onWindow = YES;
                    }
                }
            }
        }
        self.currentPage = page;
        if (self.flag != onWindow) {
            if (onWindow) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kACCCreativePathEnterNotification object:nil];
                SAFECALL_MESSAGE(ACCCreativePathMessage, @selector(enterCreativePath), enterCreativePath);
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:kACCCreativePathExitNotification object:nil];
                SAFECALL_MESSAGE(ACCCreativePathMessage, @selector(exitCreativePath), exitCreativePath);
            }
            
            self.flag = onWindow;
        }
    }
}

- (void)setupObserve:(UIViewController *)viewController
{
    [self setupObserve:viewController page:ACCCreativePageNone];
}

- (void)setupObserve:(UIViewController *)viewController page:(ACCCreativePage)page
{
    if (viewController.awe_pathObserver) {
        return;
    }
    AWECreativePathObserverViewController *observer = [[AWECreativePathObserverViewController alloc] init];
    observer.page = page;
    [viewController addChildViewController:observer];
    observer.view.hidden = YES;
    observer.view.frame = CGRectMake(0, 0, ACC_SCREEN_WIDTH , 1);
    [viewController.view addSubview:observer.view];
    [viewController.view sendSubviewToBack:observer.view];
    [observer didMoveToParentViewController:viewController];
    
    viewController.awe_pathObserver = observer;
    
    @synchronized (self.observers) {
        [self.observers compact]; //remove nil;
        [self.observers addPointer:(__bridge void *)observer];
        [self checkWindow];
    }
}

#pragma mark - Getter
- (BOOL)onPath
{
    [self checkWindow];
    return self.flag;
}

#pragma mark - Private
- (void)observerWillAppear:(AWECreativePathObserverViewController *)observer
{
    
}
- (void)observerDidAppear:(AWECreativePathObserverViewController *)observer
{
}
- (void)observerWillDisappear:(AWECreativePathObserverViewController *)observer
{
}
- (void)observerDidDisappear:(AWECreativePathObserverViewController *)observer
{
}


@end
