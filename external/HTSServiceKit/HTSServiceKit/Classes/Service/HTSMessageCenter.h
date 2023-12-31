//
//  HTSMessageCenter.h
//  LiveStreaming
//
//  Created by denggang on 16/7/13.
//  Copyright © 2016年 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HTSServiceCenter.h"
#import "HTSMessageHash.h"
#import "HTSServiceKitDefines.h"
#import "HTSCompileTimeMessageManager.h"
#import "HTSCompileTimeNotificationManager.h"

@interface HTSMessage : NSObject

- (instancetype)initWithKey:(HTSMessageKey)oKey;
- (BOOL)registerMessage:(id)oObserver;
- (void)unregisterMessage:(id)oObserver;
- (NSArray *)getObserverListForMessageKey:(HTSMessageKey)nsKey;

- (BOOL)registerMessage:(id)oObserver forKey:(id)nsKey;
- (void)unregisterMessage:(id)oObserver forKey:(id)nsKey;
- (void)unregisterKeyMessage:(id)oObserver;
- (NSArray *)getKeyMessageList:(id)nsKey;

@end

@interface HTSMessageCenter : HTSService <HTSService>

- (HTSMessage *)getMessage:(HTSMessageKey)key;

@end

#ifndef HTS_MESSAGE_CENTER_H
#define HTS_MESSAGE_CENTER_H

FOUNDATION_EXTERN void hts_register_message(Protocol * prot, id obj);
FOUNDATION_EXTERN void hts_unregister_message(Protocol * prot, id obj);

#define REGISTER_MESSAGE(message, obj)    \
{ \
    hts_register_message(@protocol(message), obj);\
}

#define UNREGISTER_MESSAGE(message, obj)    \
{ \
   hts_unregister_message(@protocol(message), obj);\
}
typedef void (^HTS_EXEC_BLOCK)(id obj);
FOUNDATION_EXTERN void safe_call_message(Protocol *prot, SEL sel, HTS_EXEC_BLOCK block);
FOUNDATION_EXTERN void thread_safe_call_message(Protocol *prot, SEL sel, HTS_EXEC_BLOCK block);

#define SAFECALL_MESSAGE(message, sel, func)    \
{ \
    HTS_EXEC_BLOCK block= ^(id obj) {\
        [obj func]; \
    };\
    safe_call_message(@protocol(message), sel, [block copy]);\
}

#define THREAD_SAFECALL_MESSAGE(message, sel, func) \
{ \
    HTS_EXEC_BLOCK block= ^(id obj) {\
       [obj func]; \
   };\
    thread_safe_call_message(@protocol(message), sel, [block copy]);\
}


FOUNDATION_EXTERN void hts_register_key_message(Protocol * prot, id key, id obj);
FOUNDATION_EXTERN void hts_unregister_key_message(Protocol * prot, id key, id obj);
FOUNDATION_EXTERN void hts_unregister_all_key_message(Protocol * prot, id obj);
#define REGISTER_KEY_MESSAGE(message, key, obj) \
{ \
    hts_register_key_message(@protocol(message), key, obj);\
}

#define UNREGISTER_KEY_MESSAGE(message, key, obj)    \
{ \
    hts_unregister_key_message(@protocol(message), key, obj);\
}

#define UNREGISTER_ALL_KEY_MESSAGE(message, obj) \
{ \
    hts_unregister_all_key_message(@protocol(message),obj);\
}

FOUNDATION_EXTERN void safe_call_key_message(Protocol *prot, SEL sel, id key, HTS_EXEC_BLOCK block);
FOUNDATION_EXTERN void thread_safe_call_key_message(Protocol *prot, SEL sel, id key, HTS_EXEC_BLOCK block);

#define SAFECALL_KEY_MESSAGE(message, key, sel, func)    \
{ \
   HTS_EXEC_BLOCK block= ^(id obj) {\
          [obj func]; \
      };\
  safe_call_key_message(@protocol(message), sel, key, [block copy]);\
}

#define THREAD_SAFECALL_KEY_MESSAGE(message, key, sel, func) \
{ \
    HTS_EXEC_BLOCK block= ^(id obj) {\
         [obj func]; \
     };\
 thread_safe_call_key_message(@protocol(message), sel, key, [block copy]);\
}

/**
 Unique Subcriber <— Multiple Publishers (subscriber can receive messages from multiple publishers)
 
 publish a message to a unique subscriber at runtime，if subscriber is not exist, it will create subscriber instance and decide to associate to publishers。
 Note：The first time message is dispatched，MessageCenter will call the C function to return  a unique subscriber instance, subscriber will assosiate to publisher instance，so subscriber's life cycle is managered by all the publishers assosiate with subscriber instance, if all the publishers is dealloc, subscriber will dealloc。you can subscribe multiple deference message to one subscriber. if subscriber instance is exist, it will not create a new subscriber until subscriber dealloc.
 Example:
  1、publish message in any thread if you want to associate a subcriber to publisher
    PUB_MSG_ASSOCIATE_UNQ_SUB(AWEFeedContainerAudioMessage, stopAudio:YES);
 
  2、publish  message in main thread if you want to associate a subcriber to publisher
    THREAD_SAFE_PUB_MSG_ASSOCIATE_UNQ_SUB(AWEFeedContainerAudioMessage, stopAudio:YES);
 
  3、publish message in any thread if you don't want to associate a subcriber to publisher，such as publisher is a singleton
    PUB_MSG_TO_UNQ_SUB(AWEFeedContainerAudioMessage, stopAudio:YES);

**/

FOUNDATION_EXTERN NSArray * safe_publish_message_in_unique(id publisher, Protocol *prot, HTS_EXEC_BLOCK block, BOOL assciate_subscriber, BOOL subscriber_is_unique);
FOUNDATION_EXTERN NSArray * thread_safe_publish_message_in_unique(id publisher, Protocol *prot, HTS_EXEC_BLOCK block, BOOL assciate_subscriber, BOOL subscriber_is_unique);


// Publish a message and associate a unique subscriber to publisher in any thread (always not a singleton)
#define PUB_MSG_ASSOCIATE_UNQ_SUB(message, func)    \
{ \
    HTS_EXEC_BLOCK block= ^(id<message> obj) {\
        [obj func]; \
    };\
    safe_publish_message_in_unique(self, @protocol(message), [block copy], YES, YES);\
}

// Publish a message and associate a unique subscriber to publisher in main thread (always not a singleton)
#define THREAD_SAFE_PUB_MSG_ASSOCIATE_UNQ_SUB(message, func) \
{ \
    HTS_EXEC_BLOCK block= ^(id<message> obj) {\
       [obj func]; \
   };\
    thread_safe_publish_message_in_unique(self, @protocol(message), [block copy], YES, YES);\
}

// Publish a message and not associate a unique subscriber to publisher in any thread (such as subscriber is a singleton or publisher self)
#define PUB_MSG_TO_UNQ_SUB(message, func)    \
{ \
    HTS_EXEC_BLOCK block= ^(id<message> obj) {\
        [obj func]; \
    };\
    safe_publish_message_in_unique(self, @protocol(message), [block copy], NO, YES);\
}

// Publish a message and not associate a unique subscriber to publisher in main thread (such as subscriber is a singleton or publisher self)
#define THREAD_SAFE_PUB_MSG_TO_UNQ_SUB(message, func) \
{ \
    HTS_EXEC_BLOCK block= ^(id<message> obj) {\
       [obj func]; \
   };\
    thread_safe_publish_message_in_unique(self, @protocol(message), [block copy], NO, YES);\
}

/**
 Pair Subcriber  <—  One Publisher (subscriber can only receive messages from one publisher)
 
 publish a message to  subscriber at runtime，if subscriber is not exist, it will create subscriber instance and associate to publisher。
 Note：The first time message is dispatched，MessageCenter will call the C function to return  a  subscriber instance, subscriber will assosiate to publisher instance，so subscriber's life cycle is managered by the publisher assosiate with subscriber instance, if the publisher is dealloc, subscriber will dealloc。you can subscribe multiple deference message to one subscriber. if subscriber instance assosiate with publisher is exist, it will not create a new subscriber until subscriber dealloc.
 Example:
  1、publish message in any thread if you want a pair of  subcriber and publisher
  [PUB_MSG_TO_PAIR_SUB( obj,  AWEFeedContainerAudioMessage)  stopAudio:YES];
 
  2、publish  message in main thread if you  want a pair of  subcriber and publisher
  [THREAD_SAFE_PUB_MSG_TO_PAIR_SUB(obj, AWEFeedContainerAudioMessage) stopAudio:YES];

**/

FOUNDATION_EXTERN id safe_publish_message_in_pair(id publisher, Protocol *prot);
FOUNDATION_EXTERN id thread_safe_publish_message_in_pair(id publisher, Protocol *prot);
FOUNDATION_EXTERN id safe_get_publisher_in_pair(id subscriber);
FOUNDATION_EXTERN id thread_safe_get_publisher_in_pair(id subscriber);

// Publish a message and associate a subscriber to publisher in any thread, subscriber and publisher pair for life
#define PUB_MSG_TO_PAIR_SUB(publisher, message)   \
(id<message>)safe_publish_message_in_pair(publisher, @protocol(message))

// Publish a message and associate a subscriber to publisher in main thread, subscriber and publisher pair for life
#define THREAD_SAFE_PUB_MSG_TO_PAIR_SUB(publisher, message) \
(id<message>)thread_safe_publish_message_in_pair(publisher, @protocol(message))


#endif //HTS_MESSAGE_CENTER_H
