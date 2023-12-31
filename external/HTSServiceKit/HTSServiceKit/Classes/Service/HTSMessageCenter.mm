//
//  HTSMessageCenter.m
//  LiveStreaming
//
//  Created by denggang on 16/7/13.
//  Copyright © 2016年 Bytedance. All rights reserved.
//

#import "HTSMessageCenter.h"
#import <objc/runtime.h>
#import <vector>
#import <pthread.h>
#import "HTSCompileTimeMessageManager.h"

void hts_register_message(Protocol * prot, id obj) {
    HTSMessage *msg = [GET_SERVICE(HTSMessageCenter) getMessage:prot];
    if (msg) {[msg registerMessage:obj];}
}

void hts_unregister_message(Protocol * prot, id obj){
    HTSMessage *msg = [GET_SERVICE(HTSMessageCenter) getMessage:prot];
    if (msg) {[msg unregisterMessage:obj];}
}

void safe_call_message(Protocol *prot, SEL sel, HTS_EXEC_BLOCK block) {
    HTSMessage *msg = [GET_SERVICE(HTSMessageCenter) getMessage:prot];
    if (msg) {
        NSArray *arr = [msg getObserverListForMessageKey:prot];
        for (id obj in arr) {
            if ([obj respondsToSelector:sel]) {
                block(obj);
            }
        }
    }
}

void hts_register_key_message(Protocol * prot, id key, id obj){
    HTSMessage *msg = [GET_SERVICE(HTSMessageCenter) getMessage:prot];
    if (msg) {
        [msg registerMessage:obj forKey:key];
    }
}

void hts_unregister_key_message(Protocol * prot, id key, id obj){
    HTSMessage *msg = [GET_SERVICE(HTSMessageCenter) getMessage:prot];
    if (msg) {
        [msg unregisterMessage:obj forKey:key];
    }
}

void hts_unregister_all_key_message(Protocol * prot, id obj){
    HTSMessage *msg  = [GET_SERVICE(HTSMessageCenter) getMessage:prot];
    if (msg) {
        [msg unregisterKeyMessage:obj];
    }
}

void safe_call_key_message(Protocol *prot, SEL sel, id key, HTS_EXEC_BLOCK block){
    HTSMessage *msg = [GET_SERVICE(HTSMessageCenter) getMessage:prot];
    if (msg) {
       NSArray *arr = [msg getKeyMessageList:key];
        for (id obj in arr) {
            if ([obj respondsToSelector:sel]) {
                block(obj);
            }
        }
    }
}

void thread_safe_call_key_message(Protocol *prot, SEL sel, id key, HTS_EXEC_BLOCK block){
    HTS_EXEC_BLOCK in_block = [block copy];
    if ([NSThread isMainThread]) {
          safe_call_key_message(prot, sel, key, in_block);
      } else {
          dispatch_sync(dispatch_get_main_queue(), ^{
              safe_call_key_message(prot, sel, key, in_block);
          });
      }
}

void thread_safe_call_message(Protocol *prot, SEL sel, HTS_EXEC_BLOCK block)
{
    HTS_EXEC_BLOCK in_block = [block copy];
    if ([NSThread isMainThread]) {
        safe_call_message(prot, sel, in_block);
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            safe_call_message(prot, sel, in_block);
        });
    }
}

@interface HTSMessage (){
    HTSMessageKey p_messageKey;

    HTSMessageHash *p_hashObserver;
    HTSMessageHash *p_hashKeyObserver;
    
    pthread_mutex_t lock;
}

@end

@implementation HTSMessage

- (instancetype)initWithKey:(HTSMessageKey)oKey
{
    self = [super init];
    if(self) {
        pthread_mutex_init(&lock, NULL);
        p_hashObserver = nil;
        p_hashKeyObserver = nil;
        p_messageKey = oKey;
    }
    return self;
}

- (void)dealloc
{
    pthread_mutex_destroy(&lock);
}

- (BOOL)registerMessage:(id)oObserver
{
    if ([oObserver conformsToProtocol:p_messageKey] == NO) {
        return NO;
    }
    
    pthread_mutex_lock(&lock);
    if (p_hashObserver == nil) {
        p_hashObserver = [[HTSMessageHash alloc] init];
    }
    
    [p_hashObserver registerMessage:oObserver forKey:NSStringFromProtocol(p_messageKey)];

    pthread_mutex_unlock(&lock);
    
    return YES;
}

- (BOOL)registerMessage:(id)oObserver forKey:(id)nsKey
{
    if ([oObserver conformsToProtocol:p_messageKey] == NO) {
        return NO;
    }
    
    pthread_mutex_lock(&lock);
    
    if (p_hashKeyObserver == nil) {
        p_hashKeyObserver = [[HTSMessageHash alloc] init];
    }
    
    [p_hashKeyObserver registerMessage:oObserver forKey:nsKey];
    
    pthread_mutex_unlock(&lock);
    
    return YES;
}

- (void)unregisterMessage:(id)oObserver
{
    pthread_mutex_lock(&lock);
    [p_hashObserver unregisterKeyMessage:oObserver];
    pthread_mutex_unlock(&lock);
}

- (void)unregisterMessage:(id)oObserver forKey:(id)nsKey
{
    pthread_mutex_lock(&lock);
    [p_hashKeyObserver unregisterMessage:oObserver forKey:nsKey];
    pthread_mutex_unlock(&lock);
}

- (void)unregisterKeyMessage:(id)oObserver
{
    pthread_mutex_lock(&lock);
    [p_hashKeyObserver unregisterKeyMessage:oObserver];
    pthread_mutex_unlock(&lock);
}

FOUNDATION_EXPORT NSArray * HTSCompileTimeSubscriberForProtocol(Protocol *protocol);
- (NSArray *)getObserverListForMessageKey:(HTSMessageKey) nsKey
{
    NSArray *runtimeList = nil;
    pthread_mutex_lock(&lock);
    runtimeList = [[p_hashObserver getKeyMessageList:NSStringFromProtocol(nsKey)] copy];
    pthread_mutex_unlock(&lock);

    NSMutableArray *res = [[NSMutableArray alloc] initWithArray:runtimeList ?: @[]];
    NSArray *compileTimeList = HTSCompileTimeSubscriberForProtocol(p_messageKey) ?: @[];
    [res addObjectsFromArray:compileTimeList];
    return [res copy];
}

- (NSArray *)getKeyMessageList:(id) nsKey
{
    NSArray *result = nil;
    pthread_mutex_lock(&lock);
    result = [[p_hashKeyObserver getKeyMessageList:nsKey] copy];
    pthread_mutex_unlock(&lock);
    return result ?: @[];
}

- (NSString *)description 
{
    return [NSString stringWithFormat:@"%@ => {\n%@,\nkey_message:\n%@\n}",NSStringFromProtocol(p_messageKey),p_hashObserver,p_hashKeyObserver];
}

@end

@interface HTSMessageCenter ()
{
    NSMutableDictionary *p_messageHash;
    pthread_mutex_t lock;
}

@end

@implementation HTSMessageCenter

// HTSMessageCenter 需要线程安全
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (instancetype)init
{
    if(self = [super init]) {
        pthread_mutex_init(&lock, NULL);
        self.isServicePersistent = YES;
        /*
         HTSMessageKey p_messageKey; (protocol)
         HTSMessageHash *p_hashObserver;  -- {protocol_name: [instance1,instance2,instance3]}
         HTSMessageHash *p_hashKeyObserver; -- {hash_key: [instance1,instance2,instance3]}
         */
        p_messageHash = [[NSMutableDictionary alloc] init];
    }
    return self;
}
#pragma clang diagnostic pop

- (void)dealloc
{
    pthread_mutex_destroy(&lock);
}

- (HTSMessage *)getMessage:(HTSMessageKey) oKey
{
    HTSMessage *message = nil;
    
    pthread_mutex_lock(&lock);
    NSString *key = NSStringFromProtocol(oKey);
    message = [p_messageHash objectForKey:key];
    if (message == nil) {
        message = [[HTSMessage alloc] initWithKey:oKey];
        [p_messageHash setObject:message forKey:key];
    }
    
    pthread_mutex_unlock(&lock);
    return message;
}

@end


#pragma mark - for pub-sub

FOUNDATION_EXPORT NSArray * HTSCompileTimeSubscriberForPublisher(Protocol *protocol, id publisher, BOOL associate, BOOL subscriber_is_unique);

NSArray * safe_publish_message(id publisher, Protocol *prot, HTS_EXEC_BLOCK block, BOOL assciate_subscriber, BOOL subscriber_is_unique)
{
    NSMutableArray *objs = [[NSMutableArray alloc] init];
    if (prot) {
        NSArray *arr = HTSCompileTimeSubscriberForPublisher(prot, publisher, assciate_subscriber, subscriber_is_unique) ?: @[];
        for (id obj in arr) {
            [objs addObject:obj];
            if (block) {
                block(obj);
            }
        }
    }
    return [objs copy];
}

NSArray * thread_safe_publish_message(id publisher, Protocol *prot, HTS_EXEC_BLOCK block, BOOL assciate_subscriber,BOOL subscriber_is_unique)
{
    HTS_EXEC_BLOCK in_block = [block copy];
    __block NSArray *objs = [NSArray array];
    if ([NSThread isMainThread]) {
        objs = safe_publish_message(publisher, prot, in_block, assciate_subscriber, subscriber_is_unique);
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            objs = safe_publish_message(publisher, prot, in_block, assciate_subscriber, subscriber_is_unique);
        });
    }
    return objs;
}

NSArray * safe_publish_message_in_unique(id publisher, Protocol *prot, HTS_EXEC_BLOCK block, BOOL assciate_subscriber, BOOL subscriber_is_unique)
{
    NSMutableArray *objs = [[NSMutableArray alloc] init];
    if (prot) {
        NSArray *arr = HTSCompileTimeSubscriberForPublisher(prot, publisher, assciate_subscriber, subscriber_is_unique) ?: @[];
        for (id obj in arr) {
            NSString *key = [NSStringFromProtocol(prot) stringByAppendingString:@([publisher hash]).stringValue];
            key = [key stringByAppendingString:@([obj hash]).stringValue];
            HTSWeakProxy *subscriberProxy = [[NSThread currentThread].threadDictionary objectForKey:key];
            if (!subscriberProxy.target){
                [[NSThread currentThread].threadDictionary removeObjectForKey:key];
                subscriberProxy = [HTSWeakProxy initWithTarget:obj];
                [[NSThread currentThread].threadDictionary setObject:subscriberProxy forKey:key];
            }
            [objs addObject:subscriberProxy];
            if (block) {
                block(subscriberProxy);
            }
        }
    }
    return [objs copy];
}

NSArray * thread_safe_publish_message_in_unique(id publisher, Protocol *prot, HTS_EXEC_BLOCK block, BOOL assciate_subscriber,BOOL subscriber_is_unique)
{
    HTS_EXEC_BLOCK in_block = [block copy];
    __block NSArray *objs = [NSArray array];
    if ([NSThread isMainThread]) {
        objs = safe_publish_message_in_unique(publisher, prot, in_block, assciate_subscriber, subscriber_is_unique);
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            objs = safe_publish_message_in_unique(publisher, prot, in_block, assciate_subscriber, subscriber_is_unique);
        });
    }
    return objs;
}

id safe_publish_message_in_pair(id publisher, Protocol *prot)
{
    NSString *key = [NSStringFromProtocol(prot) stringByAppendingString:@([publisher hash]).stringValue];
    HTSWeakProxy *subscriberProxy = [[NSThread currentThread].threadDictionary objectForKey:key];
    if (subscriberProxy.target){
        return subscriberProxy;
    } else {
        [[NSThread currentThread].threadDictionary removeObjectForKey:key];
        NSArray *objs = safe_publish_message(publisher, prot, nil, YES, NO);
        id obj = objs.lastObject;
        if (obj) {
            HTSWeakProxy *newSubscriberProxy = [HTSWeakProxy initWithTarget:obj];
            [[NSThread currentThread].threadDictionary setObject:newSubscriberProxy forKey:key];
            return newSubscriberProxy;
        } else {
            return nil;
        }
    }
}

id thread_safe_publish_message_in_pair(id publisher, Protocol *prot)
{
    __block id obj = nil;
    if ([NSThread isMainThread]) {
        obj = safe_publish_message_in_pair(publisher, prot);
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            obj = safe_publish_message_in_pair(publisher, prot);
        });
    }
    return obj;
}

id safe_get_publisher_in_pair(id subscriber)
{
    id obj = nil;
    if ([subscriber isKindOfClass:[HTSWeakProxy class]]){
        obj = [(HTSWeakProxy *)subscriber target];
    } else {
        obj = subscriber;
    }
    if (obj){
        return objc_getAssociatedObject(obj, _HTS_MSG_WEAK_PUB);
    } else {
        return nil;
    }
}

id thread_safe_get_publisher_in_pair(id subscriber)
{
    __block id publisher = nil;
    if ([NSThread isMainThread]) {
        publisher = safe_get_publisher_in_pair(subscriber);
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            publisher = safe_get_publisher_in_pair(subscriber);
        });
    }
    return publisher;
}
