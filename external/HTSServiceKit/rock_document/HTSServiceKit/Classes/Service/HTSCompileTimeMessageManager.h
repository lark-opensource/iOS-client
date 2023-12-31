//
//  HTSCompileTimeMessageManager.h
//  HTSCompileTimeMessageManager
//
//  Created by Huangwenchen on 2020/03/31.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HTSMacro.h"
#import "metamacros.h"
#import <objc/runtime.h>

// For HTS_MESSAGE_SUBSCRIBER
#define _HTS_MSG_SECTION               "__HTSMsg"
#define _HTS_MSG_PROTOCOL_METHOD        _HTS_CONCAT(__hts_message_protocol_provider_, __LINE__)
#define _HTS_MSG_LOGIC_METHOD           _HTS_CONCAT(__hts_message_logic_provider_, __LINE__)
#define _HTS_MSG_UNIQUE_VAR             _HTS_CONCAT(__hts_message_var_, __COUNTER__)


#define _HTS_MSG_ASSOCIATE_SUBSCRIBER_SECTION              "__HTSMsgAsc"
#define _HTS_MSG_ASSOCIATE_PROTOCOL_METHOD(_index_)         _HTS_CONCAT(_HTS_MSG_PROTOCOL_METHOD, _index_)
#define _HTS_MSG_ASSOCIATE_LOGIC_METHOD                     _HTS_CONCAT(__hts_message_associate_logic_provider_, __LINE__)
#define _HTS_MSG_HASH                   "_hts_msg_hash"
#define _HTS_MSG_WEAK_PUB               "_hts_msg_weak_publisher"


// For HTS_MESSAGE_ASSOCIATE_SUBSCRIBER
#define HTS_MESSAGE_FOR_EACH(INDEX, ARG) ARG,
#define _HTS_MUTIPLE_MESSAGES(...) metamacro_foreach(HTS_MESSAGE_FOR_EACH,,__VA_ARGS__)
#define HTS_MUTIPLE_MESSAGES(...) _HTS_MUTIPLE_MESSAGES(__VA_ARGS__) NSObject

#define HTS_MSG_PROTOCOL_METHOD_FOR_EACH(INDEX,CONTEXT,ARG)\
static Protocol *_HTS_MSG_ASSOCIATE_PROTOCOL_METHOD(INDEX)(void){\
    return @protocol(ARG);\
}\
__attribute((used, section(_HTS_SEGMENT "," _HTS_MSG_ASSOCIATE_SUBSCRIBER_SECTION ))) static _hts_message_pair _HTS_MSG_UNIQUE_VAR = \
{\
&_HTS_MSG_ASSOCIATE_PROTOCOL_METHOD(INDEX),\
&_HTS_MSG_ASSOCIATE_LOGIC_METHOD,\
};

#define HTS_MSG_MUTIPLE_PROTOCOL_METHODS(...) \
    metamacro_foreach_cxt(HTS_MSG_PROTOCOL_METHOD_FOR_EACH,,,__VA_ARGS__)

@interface HTSWeakProxy : NSProxy

@property (nonatomic, weak) id target;
@property (nonatomic, strong) NSString *targetClassName;

+ (instancetype)initWithTarget:(id)target;

@end

typedef struct{
    void * protocol_provider;
    void * subscriber_provider;
}_hts_message_pair;

typedef Protocol*(*_hts_message_protocol_provider)(void);
typedef id(*_hts_message_logic_provider)(void);

//这里的C方法会做二进制重排来提高第一次访问性能，用C方法不用字符串的原因是有自动补全

/**
 Register a message subscriber at compile time。
 Note：Every time message is dispatched，MessageCenter will call the C function to return a ”fresh“ subscriber, no strong reference，so it is your responsibility to manage subscriber's life cycle。
 Example:
 
    HTS_MESSAGE_SUBSCRIBER(AWEAppBytedSettingMessage){
        return [AWEGurdManager sharedManager]; //Most time you will return a singleton here
    }
**/
#define HTS_MESSAGE_SUBSCRIBER(protocol_name) static id<protocol_name> _HTS_MSG_LOGIC_METHOD(void);\
static Protocol *_HTS_MSG_PROTOCOL_METHOD(void){\
    return @protocol(protocol_name);\
}\
__attribute((used, section(_HTS_SEGMENT "," _HTS_MSG_SECTION ))) static _hts_message_pair _HTS_MSG_UNIQUE_VAR = \
{\
&_HTS_MSG_PROTOCOL_METHOD,\
&_HTS_MSG_LOGIC_METHOD,\
};\
static id<protocol_name> _HTS_MSG_LOGIC_METHOD(void)

/**
 Register a message subscriber at compile time，and associate to publishers in runtime。
 Note：The first time message is dispatched，MessageCenter will call the C function to return a  subscriber instance, subscriber will assosiate  to publisher instance，so  subscriber's life cycle is managered by all the publishers assosiate with subscriber instance, if all the publishers is dealloc, subscriber will dealloc。you can subscribe multiple deference message to one subscriber
 Example:
    1、subscribe one message
    HTS_MESSAGE_ASSOCIATE_SUBSCRIBER( AWEStopVideoMessage ){
        return  [[AWEFeedInteractionView alloc]  init];
    }
    2、subscribe mutiple message
    HTS_MESSAGE_ASSOCIATE_SUBSCRIBER(AWEStopAudioMessage, AWEAppBytedSettingMessage)
         return  [[AWEFeedInteractionView alloc]  init];
    }
**/
#define HTS_MESSAGE_ASSOCIATE_SUBSCRIBER(...) \
static id<HTS_MUTIPLE_MESSAGES(__VA_ARGS__)> _HTS_MSG_ASSOCIATE_LOGIC_METHOD(void);\
HTS_MSG_MUTIPLE_PROTOCOL_METHODS(__VA_ARGS__)\
static id<HTS_MUTIPLE_MESSAGES(__VA_ARGS__)> _HTS_MSG_ASSOCIATE_LOGIC_METHOD(void)


