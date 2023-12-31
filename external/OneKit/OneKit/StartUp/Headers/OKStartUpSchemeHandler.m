//
//  OKStartUpSchemeHandler.m
//  OKStartUp
//
//  Created by bob on 2020/1/14.
//

#import "OKStartUpSchemeHandler.h"
#import "OKStartUpScheduler.h"
#import "OKMacros.h"

@interface OKStartUpSchemeHandler ()

@property (nonatomic, strong) NSMutableSet<id<OKSchemeHandler>> *handlers;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@end

@implementation OKStartUpSchemeHandler

+ (instancetype)sharedHandler {
    static OKStartUpSchemeHandler *handler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        handler = [self new];
    });

    return handler;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.handlers = [NSMutableSet new];
        self.semaphore = dispatch_semaphore_create(1);
    }

    return self;
}

- (void)registerHandler:(id<OKSchemeHandler>)handler {
    if (handler == nil) {
        return;
    }
    OK_Lock(self.semaphore);
    [self.handlers addObject:handler];
    OK_Unlock(self.semaphore)
}

- (void)unregisterHandler:(id<OKSchemeHandler>)handler {
    if (handler == nil) {
        return;
    }
    OK_Lock(self.semaphore);
    [self.handlers removeObject:handler];
    OK_Unlock(self.semaphore)
}

- (BOOL)canHandleURL:(NSURL *)URL options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    if (URL == nil || URL.absoluteString.length < 1) {
        return NO;
    }
    
    BOOL can = NO;
    OK_Lock(self.semaphore);
    for (id<OKSchemeHandler> handler in self.handlers) {
        if ([handler canHandleURL:URL options:options]) {
            can = YES;
            break;
        }
    }
    OK_Unlock(self.semaphore)
    return can;
}

- (BOOL)handleURL:(NSURL *)URL
      application:(UIApplication *)application
            scene:(nullable id)scene
          options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    
    if (URL == nil || URL.absoluteString.length < 1) {
        return NO;
    }
    
    BOOL handled = NO;
    OK_Lock(self.semaphore);
    
    for (id<OKSchemeHandler> handler in self.handlers) {
        if ([handler canHandleURL:URL options:options]) {
            handled = [handler handleURL:URL application:application scene:scene options:options];
            if (handled) {
                break;
            }
        }
    }
    OK_Unlock(self.semaphore)
    
    return handled;
}

@end
