//
//  IESGurdDelegateDispatcherManager.m
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/5.
//

#import "IESGurdDelegateDispatcherManager.h"

#import "IESGurdDelegateDispatcher.h"

@interface IESGurdDelegateDispatcherManager ()
//NSString : Protocol name
@property (nonatomic, strong) NSMutableDictionary<NSString *, IESGurdDelegateDispatcher *> *dispatcherDictionary;

@end

@implementation IESGurdDelegateDispatcherManager

+ (instancetype)sharedManager
{
    static IESGurdDelegateDispatcherManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

#pragma mark - Public

- (id)dispatcherForProtocol:(Protocol *)protocol
{
    return [self dispatcherForProtocol:protocol createIfNeeded:NO];
}

- (void)registerDelegate:(id)delegate forProtocol:(Protocol *)protocol
{
    IESGurdDelegateDispatcher *dispatcher = [self dispatcherForProtocol:protocol createIfNeeded:YES];
    [dispatcher registerDelegate:delegate];
}

- (void)unregisterDelegate:(id)delegate forProtocol:(Protocol *)protocol
{
    IESGurdDelegateDispatcher *dispatcher = [self dispatcherForProtocol:protocol createIfNeeded:NO];
    [dispatcher unregisterDelegate:delegate];
}

#pragma mark - Private

- (IESGurdDelegateDispatcher *)dispatcherForProtocol:(Protocol *)protocol createIfNeeded:(BOOL)createIfNeeded
{
    __block IESGurdDelegateDispatcher *dispatcher = nil;
    @synchronized (self) {
        NSString *protocolName = NSStringFromProtocol(protocol);
        dispatcher = self.dispatcherDictionary[protocolName];
        if (!dispatcher && createIfNeeded) {
            dispatcher = [IESGurdDelegateDispatcher dispatcherWithProtocol:protocol];
            self.dispatcherDictionary[protocolName] = dispatcher;
        }
    }
    return dispatcher;
}

#pragma mark - Getter

- (NSMutableDictionary<NSString *, IESGurdDelegateDispatcher *> *)dispatcherDictionary
{
    if (!_dispatcherDictionary) {
        _dispatcherDictionary = [NSMutableDictionary dictionary];
    }
    return _dispatcherDictionary;
}

@end
