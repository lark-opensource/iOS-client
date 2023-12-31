//
//  LKLoadableManager.h
//  BootManager
//
//  Created by sniperj on 2021/4/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    appMain,
    didFinishLaunch,
    runloopIdle,
    afterFirstRender
} LoadableState;

@interface LKLoadableManager : NSObject

+ (void)run:(LoadableState)state;
+ (void)makeWillFinishLaunchingTime;
+ (CFTimeInterval)getWillFinishLaunchingTime;

@end

NS_ASSUME_NONNULL_END
