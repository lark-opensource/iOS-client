//
//  HMDVCFinder.m
//  CaptainAllred
//
//  Created by sunrunwang on 2019/6/4.
//  Copyright © 2019 Bill Sun. All rights reserved.
//

#include <stdatomic.h>
#include "pthread_extended.h"
#include <stdbool.h>
#include <objc/message.h>
#include <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "HMDVCFinder.h"
#import "HMDUITrackerTool.h"
#import "HMDMacro.h"

#define HMDVCFINDER_ENSSENTIAL_PERCENTAGE 0.6
#define HMDVCFINDER_ENSSENTIAL_SUBVIEW_NOT_TORLERANCE_OTHER_PERCENTAGE 0.35
#define CAVCFINDER_SCENE_UPDATE_WAIT_TIME 0.1
#define CAVCFINDER_SCENE_REFRESH_WAIT_TIME 0.5

typedef enum : NSInteger {
    UIViewCoverageRelationshipError = - 1,
    UIViewCoverageRelationshipAbove = 0,
    UIViewCoverageRelationshipEqual = 1,
    UIViewCoverageRelationshipBelow = 2,
} UIViewCoverageRelationship;

static void HMDVCFinder_update_importancy_main_thread_only(void);
static __kindof UIViewController * _Nonnull CA_topMostPresentedVC(void);
static __kindof UIViewController * _Nonnull CA_locateEssentialChildVC(__kindof UIViewController * _Nonnull parentVC);
static UIViewCoverageRelationship UIViewGetCoverageRelationship(__kindof UIView *view1, __kindof UIView *view2);
static void HMDVCFinder_trigger_update_internal_thread_safe(void);
static NSString *HMDVCFinder_sceneName_withPageExtension(UIViewController *viewController);
static atomic_ptrdiff_t scene_vc_unsafe;

@interface HMDVCFinder ()
@property(atomic, readwrite) NSString *scene;
@end

@implementation HMDVCFinder {
    pthread_mutex_t _mtx;
}

@dynamic sceneWithUpdate, scene_vc_unsafe;
@synthesize scene = _scene, previousScene = _previousScene;

+ (instancetype)finder {
    static __kindof HMDVCFinder *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[HMDVCFinder alloc] initWithDefault];
    });
    return shared;
}

- (instancetype)initWithDefault {
    if(self = [super init]) {
        pthread_mutex_init(&_mtx, NULL);
    }
    return self;
}

- (instancetype)init {
    DEBUG_POINT;  // HMDVCFinder singleton violation
    return HMDVCFinder.finder;
}

- (void)triggerUpdate {
    HMDVCFinder_trigger_update_internal_thread_safe();
}

- (void)triggerUpdateImmediately {
    dispatch_async(dispatch_get_main_queue(), ^{
        [HMDVCFinder.finder mainThreadUpdate];
    });
}

#pragma mark - Sence

- (NSString *)scene {
    pthread_mutex_lock(&_mtx);
    NSString *result = _scene;
    pthread_mutex_unlock(&_mtx);
    return result;
}

- (void)setScene:(NSString *)scene {
    if(scene != nil) {
        pthread_mutex_lock(&_mtx);
        if([_scene isEqualToString:scene]) {
            pthread_mutex_unlock(&_mtx);
            return;
        }
        pthread_mutex_unlock(&_mtx);
        [self willChangeValueForKey:@"previousScene"];
        pthread_mutex_lock(&_mtx);
        _previousScene = _scene;
        _scene = scene;
        pthread_mutex_unlock(&_mtx);
        [self didChangeValueForKey:@"previousScene"];
    }
}

- (NSString *)previousScene {
    pthread_mutex_lock(&_mtx);
    NSString *result = _previousScene;
    pthread_mutex_unlock(&_mtx);
    return result;
}

- (void *)scene_vc_unsafe {
    ptrdiff_t value = atomic_load_explicit(&scene_vc_unsafe, memory_order_acquire);
    return (void *)value;
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    if([key isEqualToString:@"previousScene"]) return NO;
    return [super automaticallyNotifiesObserversForKey:key];
}

- (NSString *)sceneWithUpdate {     // This method violate all the barriers within this class
    if(NSThread.isMainThread) HMDVCFinder_update_importancy_main_thread_only();
    else {
        dispatch_group_t group = dispatch_group_create();
        dispatch_group_async(group, dispatch_get_main_queue(), ^{
            HMDVCFinder_update_importancy_main_thread_only();
        });
#ifdef DEBUG
        if(!dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CAVCFINDER_SCENE_UPDATE_WAIT_TIME * NSEC_PER_SEC))))
            HMDPrint("CAVCFinder.sceneWithUpdate encounter update wait timeout\n");
#else
        dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CAVCFINDER_SCENE_UPDATE_WAIT_TIME * NSEC_PER_SEC)));
#endif
    }
    pthread_mutex_lock(&_mtx);
    NSString *result = _scene;
    pthread_mutex_unlock(&_mtx);
    if(result == nil) result = @"unknown";
    return result;
}

- (void)mainThreadUpdate {
    HMDVCFinder_update_importancy_main_thread_only();
}

@end

#pragma mark - Request

static void HMDVCFinder_trigger_update_internal_thread_safe(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:HMDVCFinder.finder selector:@selector(mainThreadUpdate) object:nil];
        [HMDVCFinder.finder performSelector:@selector(mainThreadUpdate) withObject:nil afterDelay:CAVCFINDER_SCENE_UPDATE_WAIT_TIME];
    });
}

static void HMDVCFinder_update_importancy_main_thread_only(void) {
    // MAIN-THREAD ONLY
    DEBUG_ASSERT(NSThread.isMainThread);
    
    __kindof UIViewController *vc = CA_locateEssentialChildVC(CA_topMostPresentedVC());
    NSString *current_scene;
    if(vc == nil) current_scene = @"unknown";
    else {
        ptrdiff_t temp = (ptrdiff_t)(__bridge void *)vc;
        atomic_store_explicit(&scene_vc_unsafe, temp, memory_order_release);
        current_scene = HMDVCFinder_sceneName_withPageExtension(vc);
    }
    HMDVCFinder.finder.scene = current_scene;
}

static NSString *HMDVCFinder_sceneName_withPageExtension(UIViewController *viewController) {
    NSString *clsName = NSStringFromClass([viewController class]);
    NSString *sceneName = clsName;
    if ([viewController respondsToSelector:NSSelectorFromString(@"hmdPageExtension")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        NSString *extension = [viewController performSelector:NSSelectorFromString(@"hmdPageExtension")];
#pragma clang diagnostic pop
        if (extension && [extension isKindOfClass:[NSString class]]) {
            sceneName = [NSString stringWithFormat:@"%@-%@", clsName, extension];
        }
    }
    return sceneName;
}

#pragma mark - Importancy

static __kindof UIViewController * _Nonnull CA_topMostPresentedVC(void) {
    DEBUG_ASSERT(NSThread.isMainThread); // CA_topMostPresentedVC not in main thread

    __kindof UIViewController *vc = HMDUITrackerTool.keyWindow.rootViewController;
    if(vc == nil) {
        UIApplication *application = UIApplication.sharedApplication;
        id<UIApplicationDelegate> delegate = application.delegate;
        if([delegate respondsToSelector:@selector(window)]) vc = delegate.window.rootViewController;
    }
    
    __kindof UIViewController *temp;
    
    // 因为都在主线程, 我们并不需要线程同步的概念
    static BOOL isQueriedStatusBarAppearance = NO;
    static BOOL viewControllerBased_statusBar = YES;
    if(!isQueriedStatusBarAppearance) {
        id maybeNumber = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"];
        
        // UIViewControllerBasedStatusBarAppearance 的含义是
        // 是否由 viewController 控制 statusBar 的状态
        // 这个键值不存在以及为YES, 都意味着 viewController 控制 statusBar 的状态
        if([maybeNumber isKindOfClass:NSNumber.class]) {
            viewControllerBased_statusBar = ((NSNumber *)maybeNumber).boolValue;
        }
        isQueriedStatusBarAppearance = YES;
    }
    do {
        if((temp = vc.presentedViewController) != nil) {
            UIModalPresentationStyle style = vc.presentedViewController.modalPresentationStyle;
            if(style == UIModalPresentationFullScreen ||
               style == UIModalPresentationOverFullScreen ||
               style == UIModalPresentationCurrentContext ||
               style == UIModalPresentationOverCurrentContext ||
               
               // 如果当前的状态是 Custom 要分为两种情况讨论
               // 类似 popover 的情况下可能当前的 VC 已经被隐藏了
               // 再者是比较特别的 Custom 展示，我们需要按照 hitTest 的条件判断是否满足
               // 这里我们加入 viewLoaded 选项, 防止在 viewLoaded 之前执行访问 view
               (style == UIModalPresentationCustom && (temp.presentedViewController != nil ||
                                                       (temp.viewLoaded && !temp.view.hidden && temp.view.alpha >= 0.01)))) {
                vc = temp; continue;
            }
            // 这里并不需要把 temp 赋值为 nil 来退出循环
            // 因为立即会走到 temp = vc.childViewControllerForStatusBarHidden
        }
        if((temp = vc.childViewControllerForStatusBarHidden) != nil) {
            // 这里我们加入 viewLoaded 选项, 防止在 viewLoaded 之前执行访问 view
            if(viewControllerBased_statusBar && temp.viewLoaded && ([vc isKindOfClass:UINavigationController.class] ||
                                                                    [vc isKindOfClass:UITabBarController.class])) {
                __kindof UIView *view = temp.view;
                if(view != nil && !view.hidden && view.alpha >= 0.01) vc = temp;
                else temp = nil;
            }
            else temp = nil;
        }
    }while(temp != nil);
    return vc;
}

static __kindof UIViewController * _Nonnull CA_locateEssentialChildVC(__kindof UIViewController * _Nonnull parentVC) {
    DEBUG_ASSERT(NSThread.isMainThread); // CA_locateEssentialChildVC not in main thread
    
    // 全局对于 ScreenSize 只获取一次
    static BOOL screenSizeDetermined = NO;
    static CGFloat screenSize;
    if(!screenSizeDetermined) {
        CGRect screenBounds = UIScreen.mainScreen.bounds;
        screenSize = screenBounds.size.width * screenBounds.size.height;
        screenSizeDetermined = YES;
    }
    
    // 从上层走下来只有 rootViewController 没有判断 viewLoaded
    // 这里没有必要保护判断是否 viewLoaded
    // viewLoaded 会减少卡死以及改变业务逻辑的情况
    __kindof UIView *this_view = parentVC.view;
    CGRect bounds = this_view.bounds;
    CGFloat parentSize = bounds.size.width * bounds.size.height;
    
    if(parentSize >= screenSize * HMDVCFINDER_ENSSENTIAL_PERCENTAGE) {
        NSArray *allChildViewControllers = parentVC.childViewControllers;
        if(allChildViewControllers.count == 1) {
            __kindof UIViewController *childVC = allChildViewControllers[0];
            if (childVC.isViewLoaded) {
                // viewcontroller viewDidLoad 的时候才能去判断
                // 否者直接调用 viewController.view
                // 使 viewController 的 view 被 load 影响正常的业务
                __kindof UIView *child_view = childVC.view;
                if(!child_view.hidden && child_view.alpha >= 0.01 && [child_view isDescendantOfView:this_view]) {
                    CGRect child_frame = [this_view convertRect:child_view.bounds fromView:child_view];
                    CGRect contained = CGRectIntersection(bounds, child_frame);
                    if(CGRectIsNull(contained)) contained = CGRectZero;
                    CGFloat containedSize = contained.size.width * contained.size.height;
                    if(containedSize >= screenSize * HMDVCFINDER_ENSSENTIAL_PERCENTAGE) {
                        return CA_locateEssentialChildVC(childVC);
                    }
                }
            }
        }
        else if(allChildViewControllers.count >= 2) {
            NSMutableArray<__kindof UIViewController *> *possibleViewControllers = [NSMutableArray arrayWithCapacity:allChildViewControllers.count];
            NSEnumerator *enumerator = allChildViewControllers.objectEnumerator;
            __kindof UIViewController *eachViewController;
            while ((eachViewController = enumerator.nextObject) != nil) {
                if (eachViewController.isViewLoaded) {
                    // viewcontroller viewDidLoad 的时候才能去判断
                    // 否者直接调用 viewController.view
                    // 使 viewController 的 view 被 load 影响正常的业务
                    __kindof UIView *front_child_view = eachViewController.view;
                    if(!front_child_view.hidden && front_child_view.alpha >= 0.01 && [front_child_view isDescendantOfView:this_view])
                        [possibleViewControllers addObject:eachViewController];
                }
            }
            if(possibleViewControllers.count > 0) {
                __block BOOL errorFlag = NO;
                [possibleViewControllers sortUsingComparator:^NSComparisonResult(__kindof UIViewController *vc1, __kindof UIViewController *vc2) {
                    UIViewCoverageRelationship relationship = UIViewGetCoverageRelationship(vc1.view, vc2.view);
                    if(relationship == UIViewCoverageRelationshipAbove) return NSOrderedAscending;
                    else if(relationship == UIViewCoverageRelationshipBelow) return NSOrderedDescending;
                    errorFlag = YES;
                    return NSOrderedSame;
                }];
                if(!errorFlag) {
                    __block UIViewController *targetViewController = nil;
                    [possibleViewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull eachViewController, NSUInteger idx, BOOL * _Nonnull stop) {
                        __kindof UIView *front_child_view = eachViewController.view;
                        CGRect child_frame = [this_view convertRect:front_child_view.bounds fromView:front_child_view];
                        CGRect contained = CGRectIntersection(bounds, child_frame);
                        if(CGRectIsNull(contained)) contained = CGRectZero;
                        CGFloat containedSize = contained.size.width * contained.size.height;
                        if(containedSize >= screenSize * HMDVCFINDER_ENSSENTIAL_PERCENTAGE) {
                            targetViewController = eachViewController;
                            *stop = YES;
                        }
                        else if(containedSize >= screenSize * HMDVCFINDER_ENSSENTIAL_SUBVIEW_NOT_TORLERANCE_OTHER_PERCENTAGE) *stop = YES;
                    }];
                    if(targetViewController) return CA_locateEssentialChildVC(targetViewController);
                }
                DEBUG_ELSE
            }
        }
    }
    return parentVC;
}

#pragma mark - Supporting function

static UIViewCoverageRelationship UIViewGetCoverageRelationship(__kindof UIView *view1, __kindof UIView *view2) {
    if(view1 == view2) return UIViewCoverageRelationshipEqual;
    if([view2 isDescendantOfView:view1]) return UIViewCoverageRelationshipBelow;
    __kindof UIView *intermediateView = view1;
    __kindof UIView *currentView = view1.superview;
    while(currentView != nil) {
        if([view2 isDescendantOfView:currentView]) {
            if(view2 == currentView) return UIViewCoverageRelationshipAbove;
            __block NSUInteger view1_index = NSUIntegerMax;
            __block NSUInteger view2_index = NSUIntegerMax;
            NSArray<__kindof UIView *> *subviews = currentView.subviews;
            [subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull eachSubview, NSUInteger idx, BOOL * _Nonnull stop) {
                if(eachSubview == intermediateView) view1_index = idx;
                else if([view2 isDescendantOfView:eachSubview]) view2_index = idx;
                if(view1_index != NSUIntegerMax && view2_index != NSUIntegerMax) *stop = YES;
            }];
            if(view1_index == NSUIntegerMax || view2_index == NSUIntegerMax || view1_index == view2_index) {
                DEBUG_POINT
                return UIViewCoverageRelationshipError;
            }
            if(view1_index < view2_index) return UIViewCoverageRelationshipBelow;
            else return UIViewCoverageRelationshipAbove;
        }
        intermediateView = currentView;
        currentView = currentView.superview;
    }
    return UIViewCoverageRelationshipError;
}
