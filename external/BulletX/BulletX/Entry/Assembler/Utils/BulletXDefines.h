//
//  BulletXDefines.h
//  BulletX-Pods-Aweme
//
//  Created by bill on 2020/9/22.
//

#import <Foundation/Foundation.h>
//#import <BulletX/BulletCoreDefines.h>
#import <ByteDanceKit/UIDevice+BTDAdditions.h>
//#import "BulletXRequestInterceptor.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSString *BulletXEventKey;
typedef NSString *BulletXNotificationKey;
typedef NSString *BulletXDetailLifeCycleEvent;

#pragma mark - ContextInfoKey

#define BDXContextKey NSString *

FOUNDATION_EXPORT BDXContextKey const kBulletContextMetaResourceKey;

#pragma mark - EventKey

FOUNDATION_EXPORT BulletXEventKey const kBulletXEventContainerDidReceiveFirstLoad;

FOUNDATION_EXPORT BulletXEventKey const kBulletXEventContainerDidRender;
FOUNDATION_EXPORT BulletXEventKey const kBulletXEventContainerDidLoadFinished;

FOUNDATION_EXPORT BulletXEventKey const kBulletXEventContainerDidAppear;

FOUNDATION_EXPORT BulletXEventKey const kBulletXEventContainerDidDisappear;

FOUNDATION_EXPORT BulletXEventKey const kBulletXEventAppDidBecomeActive;

FOUNDATION_EXPORT BulletXEventKey const kBulletXEventAppWillResignActive;

#pragma mark - NotificationKey

FOUNDATION_EXPORT BulletXNotificationKey const kBulletXNotificationConfigireStatusBar;

#ifndef BDX_MUTEX_LOCK
#define BDX_MUTEX_LOCK(lock)     \
    pthread_mutex_lock(&(lock)); \
    @onExit { pthread_mutex_unlock(&(lock)); };
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

#define BDX_BLOCK_INVOKE(block, ...) (block ? block(__VA_ARGS__) : 0)

#define UIColorFromRGBA(__rgb__, __alpha__) [UIColor colorWithRed:((float)(((__rgb__)&0xFF0000) >> 16)) / 255.0 green:((float)(((__rgb__)&0xFF00) >> 8)) / 255.0 blue:((float)((__rgb__)&0xFF)) / 255.0 alpha:(__alpha__)]

#ifndef bullet_dispatch_main_async_safe
#define bullet_dispatch_main_async_safe(block) bullet_dispatch_queue_async_safe(dispatch_get_main_queue(), block)
#endif

#ifndef bullet_dispatch_queue_async_safe
#define bullet_dispatch_queue_async_safe(queue, block)                                               \
    if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(queue)) { \
        block();                                                                                     \
    } else {                                                                                         \
        dispatch_async(queue, block);                                                                \
    }
#endif

#define BDX_STATUS_BAR_NORMAL_HEIGHT (20 + BDX_NAVIGATION_BAR_OFFSET)
#define BDX_NAVIGATION_BAR_OFFSET ([UIDevice btd_isIPhoneXSeries] ? (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 4 : 24) : 0)
#define BDX_DynamicCast(x, c) ((c *)([x isKindOfClass:[c class]] ? x : nil))

NS_ASSUME_NONNULL_END
