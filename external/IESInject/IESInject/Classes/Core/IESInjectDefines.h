//
//  IESInjectDefines.h
//  Pods
//
//  Created by bytedance on 2020/2/10.
//

#ifndef IESInjectDefines_h
#define IESInjectDefines_h

#import <Foundation/Foundation.h>

#define IESProvides(proto, ...) IESProvidesTranslate(proto, ##__VA_ARGS__, 5, 4, 3, 2, 1)
#define IESProvidesTranslate(proto1, proto2, proto3, proto4, proto5, num, ...) IESProvides##num(proto1, proto2, proto3, proto4, proto5)
#define IESProvides1(proto1, proto2, proto3, proto4, proto5)  - (id<proto1>)provide:(id)p proto1:(id)p1
#define IESProvides2(proto1, proto2, proto3, proto4, proto5)  - (id<proto1, proto2>)multiProvide:(id)p proto1:(id)p1 proto2:(id)p2
#define IESProvides3(proto1, proto2, proto3, proto4, proto5)  - (id<proto1, proto2, proto3>)multiProvide:(id)p proto1:(id)p1 proto2:(id)p2 proto3:(id)p3
#define IESProvides4(proto1, proto2, proto3, proto4, proto5)  - (id<proto1, proto2, proto3, proto4>)multiProvide:(id)p proto1:(id)p1 proto2:(id)p2 proto3:(id)p3 proto4:(id)p4
#define IESProvides5(proto1, proto2, proto3, proto4, proto5)  - (id<proto1, proto2, proto3, proto4, proto5>)multiProvide:(id)p proto1:(id)p1 proto2:(id)p2 proto3:(id)p3 proto4:(id)p4 proto5:(id)p5

#define IESProvidesWeakObject(proto, ...) IESProvidesWeakObjectTranslate(proto, ##__VA_ARGS__, 5, 4, 3, 2, 1)
#define IESProvidesWeakObjectTranslate(proto1, proto2, proto3, proto4, proto5, num, ...) IESProvidesWeakObject##num(proto1, proto2, proto3, proto4, proto5)
#define IESProvidesWeakObject1(proto1, proto2, proto3, proto4, proto5)  - (id<proto1>)provideWeakObject:(id)p proto1:(id)p1
#define IESProvidesWeakObject2(proto1, proto2, proto3, proto4, proto5)  - (id<proto1, proto2>)multiProvideWeakObject:(id)p proto1:(id)p1 proto2:(id)p2
#define IESProvidesWeakObject3(proto1, proto2, proto3, proto4, proto5)  - (id<proto1, proto2, proto3>)multiProvideWeakObject:(id)p proto1:(id)p1 proto2:(id)p2 proto3:(id)p3
#define IESProvidesWeakObject4(proto1, proto2, proto3, proto4, proto5)  - (id<proto1, proto2, proto3, proto4>)multiProvideWeakObject:(id)p proto1:(id)p1 proto2:(id)p2 proto3:(id)p3 proto4:(id)p4
#define IESProvidesWeakObject5(proto1, proto2, proto3, proto4, proto5)  - (id<proto1, proto2, proto3, proto4, proto5>)multiProvideWeakObject:(id)p proto1:(id)p1 proto2:(id)p2 proto3:(id)p3 proto4:(id)p4 proto5:(id)p5

#define IESProvidesSingleton(proto, ...) IESProvidesSingletonTranslate(proto, ##__VA_ARGS__, 5, 4, 3, 2, 1)
#define IESProvidesSingletonTranslate(proto1, proto2, proto3, proto4, proto5, num, ...) IESProvidesSingleton##num(proto1, proto2, proto3, proto4, proto5)
#define IESProvidesSingleton1(proto1, proto2, proto3, proto4, proto5)  - (id<proto1>)provideSingleton:(id)p proto1:(id)p1
#define IESProvidesSingleton2(proto1, proto2, proto3, proto4, proto5)  - (id<proto1, proto2>)multiProvideSingleton:(id)p proto1:(id)p1 proto2:(id)p2
#define IESProvidesSingleton3(proto1, proto2, proto3, proto4, proto5)  - (id<proto1, proto2, proto3>)multiProvideSingleton:(id)p proto1:(id)p1 proto2:(id)p2 proto3:(id)p3
#define IESProvidesSingleton4(proto1, proto2, proto3, proto4, proto5)  - (id<proto1, proto2, proto3, proto4>)multiProvideSingleton:(id)p proto1:(id)p1 proto2:(id)p2 proto3:(id)p3 proto4:(id)p4
#define IESProvidesSingleton5(proto1, proto2, proto3, proto4, proto5)  - (id<proto1, proto2, proto3, proto4, proto5>)multiProvideSingleton:(id)p proto1:(id)p1 proto2:(id)p2 proto3:(id)p3 proto4:(id)p4 proto5:(id)p5


#define IESAutoInlineNonnull(obj, provider, proto) \
^(){ \
    return obj; \
}() \

#define IESOptionalInline(provider, proto) (id<proto>)[provider resolveObject:@protocol(proto)]
#define IESRequiredInline(provider, proto) (id<proto>)IESAutoInlineNonnull([provider resolveObject:@protocol(proto)], provider, proto)
#define IESAutoInline(provider, proto) IESRequiredInline(provider, proto)

#define IESOptionalInject(provider, property, proto) -(id<proto>)property  { \
if (!_##property) {\
_##property = [provider resolveObject:@protocol(proto)]; \
}\
return _##property;\
}

#define IESRequiredInject(provider, property, proto) -(id<proto>)property  { \
if (!_##property) {\
_##property = [provider resolveObject:@protocol(proto)]; \
}\
return _##property;\
}

#define IESAutoInject(provider, property, proto) IESRequiredInject(provider, property, proto)

#ifndef IESRequiredInjectClass
#define IESRequiredInjectClass(provider, property, cls) -(cls *)property  { \
if (!_##property) {\
_##property = [provider resolveObject:NSClassFromString(@#cls)]; \
}\
return _##property;\
}
#endif

#define IESAutoResponseTo(provider, proto, block) [provider provideBlockNeedServiceResponse:block forProtocol:@protocol(proto)]

#endif /* IESInjectDefines_h */
