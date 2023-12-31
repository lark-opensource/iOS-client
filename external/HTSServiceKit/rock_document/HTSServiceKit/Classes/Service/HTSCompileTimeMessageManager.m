//
//  HTSCompileTimeMessageManager.m
//  HTSCompileTimeMessageManager
//
//  Created by Huangwenchen on 2020/03/31.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import "HTSCompileTimeMessageManager.h"
#import "HTSMacro.h"
#import <mach-o/dyld.h>
#import <mach-o/getsect.h>
#import "HTSMessageCenter.h"
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <pthread.h>
#import "HTSServiceCenter.h"

typedef NSMutableArray<NSValue *> HTSMutablePointerArray;
typedef NSMutableDictionary<NSString *, HTSMutablePointerArray *> HTSCompileTimeMessageHash;
typedef unsigned long long HTSUInteger;

#ifndef __LP64__
typedef struct mach_header HTSMachHeader;
#else
typedef struct mach_header_64 HTSMachHeader;
#endif

static HTSCompileTimeMessageHash* _compileTimeHash; 
// Does not support lazy load framework
static void _loadCompileTimeMessageSubscribers(void) __attribute__((no_sanitize("address")))
{
    _compileTimeHash = [[HTSCompileTimeMessageHash alloc] init];
    NSInteger imageCount = _dyld_image_count();
    for (uint32_t idx = 0; idx < imageCount; idx++) {
        HTSMachHeader * mh = (HTSMachHeader *)_dyld_get_image_header(idx);
        unsigned long size = 0;
        _hts_message_pair * data = (_hts_message_pair *)getsectiondata(mh,_HTS_SEGMENT, _HTS_MSG_SECTION, &size);
        if (size == 0)  continue;
        uint32_t count = size / sizeof(_hts_message_pair);
        if (count == 0) continue;
        
        for (NSInteger idy = 0; idy < count; idy++) {
            _hts_message_pair pair = data[idy];
#if __has_feature(address_sanitizer)
            if(pair.protocol_provider == 0 || pair.subscriber_provider == 0) {
                continue;
            }
#endif
            _hts_message_protocol_provider protocolPointer = (_hts_message_protocol_provider)pair.protocol_provider;
            Protocol * protocol = protocolPointer();
            NSString * protocolName = NSStringFromProtocol(protocol);
            HTSMutablePointerArray * pointers = [_compileTimeHash objectForKey:protocolName];
            if (!pointers) {
                pointers = [[HTSMutablePointerArray alloc] init];
                [_compileTimeHash setObject:pointers forKey:protocolName];
            }
            [pointers addObject:[NSValue valueWithPointer:pair.subscriber_provider]];
        }
    }
}

FOUNDATION_EXPORT NSArray * HTSCompileTimeSubscriberForProtocol(Protocol *protocol){
    if (!protocol) {
        return nil;
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _loadCompileTimeMessageSubscribers();
    });
    NSString * protocolName = NSStringFromProtocol(protocol); 
    HTSMutablePointerArray * pointersValues = [_compileTimeHash objectForKey:protocolName];
    if (!pointersValues || pointersValues.count == 0) {
        return nil;
    }
    NSMutableArray * res = [[NSMutableArray alloc] initWithCapacity:pointersValues.count];
    for (NSValue * value in pointersValues) {
        _hts_message_logic_provider pointer = (_hts_message_logic_provider)[value pointerValue];
        id subscriber = pointer();
        if (!subscriber || ![subscriber conformsToProtocol:protocol]) {
            continue;
        }
        [res addObject:subscriber];
    }
    return [res copy];
}

@implementation HTSWeakProxy

+ (instancetype)initWithTarget:(id)target {
    HTSWeakProxy *proxy = [HTSWeakProxy alloc];
    proxy.target = target;
    proxy.targetClassName = NSStringFromClass([target class]);
    return proxy;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    if (_target && [_target respondsToSelector:sel]) {
        return [_target methodSignatureForSelector:sel];
    } else {
        if (!_target){
            NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:"v@:@"];
            return signature;
        } else {
            NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:"v@:@"];
            return signature;
        }
    }
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    SEL sel = invocation.selector;
    if (_target && [_target respondsToSelector:sel]) {
        [invocation invokeWithTarget:_target];
    } else {
        SEL htsSel = nil;
        if (!_target){
            htsSel = @selector(handleNilTarget:);
        } else {
            htsSel = @selector(handleNoSelector:);
        }
        NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:"v@:@"];
        invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:self];
        [invocation setSelector:htsSel];
        NSString *arg = NSStringFromSelector(sel);
        [invocation setArgument:&arg atIndex:2];
        [invocation invokeWithTarget:self];
    }
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [_target respondsToSelector:aSelector];
}

- (void)handleNilTarget:(NSString *)seletor
{
#ifdef DEBUG
#ifdef LITE
        if ([_targetClassName containsString:@"DOUYINLite"] || [_targetClassName containsString:@"Common"]) {
            HTSLog(@"HTSServiceLog: object of \"%@\" class is nil to call method of \"%@\"", _targetClassName, seletor);
        }
#else
        if (![_targetClassName containsString:@"DOUYINLite"] && ![_targetClassName containsString:@"DOUYINHM"]) {
            HTSLog(@"HTSServiceLog: object of \"%@\" class is nil to call method of \"%@\"", _targetClassName, seletor);
        }
#endif
#endif
}

- (void)handleNoSelector:(NSString *)seletor
{
#ifdef DEBUG
#ifdef LITE
        if ([_targetClassName containsString:@"DOUYINLite"] || [_targetClassName containsString:@"Common"]) {
            HTSLog(@"HTSServiceLog: object of \"%@\" class not respondsToSelector of \"%@\"", _targetClassName, seletor);
        }
#else
        if (![_targetClassName containsString:@"DOUYINLite"] && ![_targetClassName containsString:@"DOUYINHM"]) {
            HTSLog(@"HTSServiceLog: object of \"%@\" class not respondsToSelector of \"%@\"", _targetClassName, seletor);
        }
#endif
#endif
}


@end

static HTSCompileTimeMessageHash* _compileTimeAssociateSubscribersHash;
static NSMutableDictionary<NSString *, id> *_subscriber_instances;
static pthread_mutex_t _compileTimelock;

// Does not support lazy load framework
static void _loadCompileTimeMessageAssociateSubscribers(void) __attribute__((no_sanitize("address")))
{
    pthread_mutex_init(&_compileTimelock, NULL);
    _compileTimeAssociateSubscribersHash = [[HTSCompileTimeMessageHash alloc] init];
    _subscriber_instances = [[NSMutableDictionary alloc] init];
    NSInteger imageCount = _dyld_image_count();
    for (uint32_t idx = 0; idx < imageCount; idx++) {
        HTSMachHeader * mh = (HTSMachHeader *)_dyld_get_image_header(idx);
        unsigned long size = 0;
        _hts_message_pair * data = (_hts_message_pair *)getsectiondata(mh,_HTS_SEGMENT, _HTS_MSG_ASSOCIATE_SUBSCRIBER_SECTION, &size);
        if (size == 0)  continue;
        uint32_t count = size / sizeof(_hts_message_pair);
        if (count == 0) continue;
        
        for (NSInteger idy = 0; idy < count; idy++) {
            _hts_message_pair pair = data[idy];
#if __has_feature(address_sanitizer)
            if(pair.protocol_provider == 0 || pair.subscriber_provider == 0) {
                continue;
            }
#endif
            _hts_message_protocol_provider protocolPointer = (_hts_message_protocol_provider)pair.protocol_provider;
            Protocol * protocol = protocolPointer();
            NSString * protocolName = NSStringFromProtocol(protocol);
            HTSMutablePointerArray * pointers = [_compileTimeAssociateSubscribersHash objectForKey:protocolName];
            if (!pointers) {
                pointers = [[HTSMutablePointerArray alloc] init];
                [_compileTimeAssociateSubscribersHash setObject:pointers forKey:protocolName];
            }
            [pointers addObject:[NSValue valueWithPointer:pair.subscriber_provider]];
        }
    }
}

FOUNDATION_EXPORT NSArray * HTSCompileTimeUniqueSubscriberForPublisher(Protocol *protocol, id publisher, BOOL associate){
    NSString * protocolName = NSStringFromProtocol(protocol);
    HTSMutablePointerArray * pointersValues = [_compileTimeAssociateSubscribersHash objectForKey:protocolName];
    if (!pointersValues || pointersValues.count == 0) {
        HTSLog(@"HTSServiceLog: no class conforms to protocol of \"%@\"", NSStringFromProtocol(protocol));
        return nil;
    }
    
    NSMutableArray * res = [[NSMutableArray alloc] initWithCapacity:pointersValues.count];
    for (NSValue * value in pointersValues) {
        _hts_message_logic_provider pointer = (_hts_message_logic_provider)[value pointerValue];
        id subscriber = nil;
        
        NSString *subscriberPointerKey = nil;
        // get subscriber from cache, if subscriber had been dealloc, the target of subscriberWeakProxy will return nil
        // if subscriber is unique, it can only alloc one instance of subscriber class in app life cycle
        subscriberPointerKey = [NSString stringWithFormat:@"%p", pointer];
        
        HTSWeakProxy *subscriberWeakProxy = nil;
        pthread_mutex_lock(&_compileTimelock);
        subscriberWeakProxy = [_subscriber_instances objectForKey:subscriberPointerKey];
        pthread_mutex_unlock(&_compileTimelock);

        id subscriberCache = subscriberWeakProxy.target;
        
        if (!subscriberCache) {
            // no cache then get new instance of subscriber
            subscriber = pointer();
            // remove subscriber cache proxy
            pthread_mutex_lock(&_compileTimelock);
            [_subscriber_instances removeObjectForKey:subscriberPointerKey];
            pthread_mutex_unlock(&_compileTimelock);
        } else {
            subscriber = subscriberCache;
        }
        if (!subscriber || ![subscriber conformsToProtocol:protocol]) {
            continue;
        }
        
        // publisher associated retain subscriber, if all publishers that retain subscriber had been dealloc and subscriber is not a singleton, subscriber will be dealloc
        id associatedSubscriber = objc_getAssociatedObject(publisher, subscriberPointerKey.UTF8String);
        if (!associatedSubscriber && associate) {
            objc_setAssociatedObject(publisher, subscriberPointerKey.UTF8String, subscriber, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        
        if (!subscriberCache){
            // update subscriber caches with weak proxy
            HTSWeakProxy *subscriberWeakProxy = [HTSWeakProxy initWithTarget:subscriber];
            pthread_mutex_lock(&_compileTimelock);
            [_subscriber_instances setObject:subscriberWeakProxy forKey:subscriberPointerKey];
            pthread_mutex_unlock(&_compileTimelock);
        }
        
        [res addObject:subscriber];
    }
    return [res copy];
}

FOUNDATION_EXPORT id HTSCompileTimePairSubscriberForPublisher(Protocol *protocol, id publisher, BOOL associate){

    NSString * protocolName = NSStringFromProtocol(protocol);
    HTSMutablePointerArray * pointersValues = [_compileTimeAssociateSubscribersHash objectForKey:protocolName];
    if (!pointersValues || pointersValues.count == 0) {
        NSString *protocolString = NSStringFromProtocol(protocol);
#ifdef DEBUG
#ifdef LITE
        if ([protocolString containsString:@"DOUYINLite"] || [protocolString containsString:@"Common"]) {
            HTSLog(@"HTSServiceLog: no class conforms to protocol of \"%@\"", protocolString);
        }
#else
        if (![protocolString containsString:@"DOUYINLite"] && ![protocolString containsString:@"DOUYINHM"]) {
            HTSLog(@"HTSServiceLog: no class conforms to protocol of \"%@\"", protocolString);
        }
#endif
#endif
        return nil;
    }
    
    if (pointersValues.count > 1) {
        // if subscriber is pair, one protocol can only bind to one subscriber class, default class is the last subscriber class
        [NSException raise:@"HTSServiceInvalidException" format:@"you can only bind a protocol \"%@\" to one class in pub-sub pair mode", NSStringFromProtocol(protocol)];
    }
        
    NSValue * value = pointersValues.lastObject;
    _hts_message_logic_provider pointer = (_hts_message_logic_provider)[value pointerValue];
    id subscriber = nil;
    
    NSString *subscriberPointerKey = nil;
    // get subscriber from cache, if subscriber had been dealloc, the target of subscriberWeakProxy will return nil
    // if subscriber is not unique, it can only alloc one instance of subscriber class pair with one publisher
    HTSUInteger htsHash = [objc_getAssociatedObject(publisher, _HTS_MSG_HASH) unsignedLongLongValue];
    if (htsHash == 0) {
        htsHash = [[NSDate date] timeIntervalSince1970] * 1000000;
        objc_setAssociatedObject(publisher, _HTS_MSG_HASH, @(htsHash), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    subscriberPointerKey = [NSString stringWithFormat:@"%p_%p_%@",pointer, publisher, @(htsHash)];
    
    HTSWeakProxy *subscriberWeakProxy = nil;
    pthread_mutex_lock(&_compileTimelock);
    subscriberWeakProxy = [_subscriber_instances objectForKey:subscriberPointerKey];
    pthread_mutex_unlock(&_compileTimelock);

    id subscriberCache = subscriberWeakProxy.target;
    
    if (!subscriberCache) {
        // no cache then get new instance of subscriber
        subscriber = pointer();
        // remove subscriber cache proxy
        pthread_mutex_lock(&_compileTimelock);
        [_subscriber_instances removeObjectForKey:subscriberPointerKey];
        pthread_mutex_unlock(&_compileTimelock);
        
        // store weak publisher for subscriber
        if (subscriber && publisher){
            objc_setAssociatedObject(subscriber, _HTS_MSG_WEAK_PUB, publisher, OBJC_ASSOCIATION_ASSIGN);
        }
        
    } else {
        subscriber = subscriberCache;
    }
    if (!subscriber || ![subscriber conformsToProtocol:protocol]) {
        return subscriber;
    }
    
    // publisher associated retain subscriber, if all publishers that retain subscriber had been dealloc and subscriber is not a singleton, subscriber will be dealloc
    id associatedSubscriber = objc_getAssociatedObject(publisher, subscriberPointerKey.UTF8String);
    if (!associatedSubscriber && associate) {
        objc_setAssociatedObject(publisher, subscriberPointerKey.UTF8String, subscriber, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    if (!subscriberCache){
        // update subscriber caches with weak proxy
        HTSWeakProxy *subscriberWeakProxy = [HTSWeakProxy initWithTarget:subscriber];
        pthread_mutex_lock(&_compileTimelock);
        [_subscriber_instances setObject:subscriberWeakProxy forKey:subscriberPointerKey];
        pthread_mutex_unlock(&_compileTimelock);
    }
    return subscriber;
}


FOUNDATION_EXPORT NSArray * HTSCompileTimeSubscriberForPublisher(Protocol *protocol, id publisher, BOOL associate, BOOL subscriber_is_unique){
    if (!protocol) {
        [NSException raise:@"HTSServiceInvalidException" format:@"protocol cannot be nil"];
        return nil;
    }
    if (!publisher) {
        [NSException raise:@"HTSServiceInvalidException" format:@"publisher cannot be nil"];
        return nil;
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _loadCompileTimeMessageAssociateSubscribers();
    });
    
    if (subscriber_is_unique) {
        // handle unique subscriber in all thread
        return HTSCompileTimeUniqueSubscriberForPublisher(protocol, publisher, associate);
    } else {
        // handle pair subscriber in all thread
        id subscriber = HTSCompileTimePairSubscriberForPublisher(protocol, publisher, associate);
        if (subscriber) {
            return [NSArray arrayWithObject:subscriber];
        } else {
            return nil;
        }
    }
}


