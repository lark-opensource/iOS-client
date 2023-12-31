//
//  DVEFoundationInject.h
//  DVEFoundationKit
//
//  Created by Lincoln on 2022/2/14.
//

#ifndef DVEFoundationInject_h
#define DVEFoundationInject_h

#import <IESInject/IESInject.h>

#define DVEDIContainer IESContainer
#define DVEDIServiceProvider IESServiceProvider
#define DVEDIStaticContainer IESStaticContainer

#define DVEProvides(proto) IESProvides(proto)
#define DVEProvidesWeakObject(proto) IESProvidesWeakObject(proto)
#define DVEProvidesSingleton(proto) IESProvidesSingleton(proto)

#define DVEOptionalInline(provider, proto) IESOptionalInline(provider, proto)
#define DVEAutoInline(provider, proto) IESAutoInline(provider, proto)

#define DVEOptionalInject(provider, property, proto) IESOptionalInject(provider, property, proto)
#define DVEAutoInject(provider, property, proto) IESAutoInject(provider, property, proto)

#define DVEInjectScopeType          IESInjectScopeType
#define DVEInjectScopeTypeNone      IESInjectScopeTypeNone
#define DVEInjectScopeTypeNormal    IESInjectScopeTypeNormal
#define DVEInjectScopeTypeWeak      IESInjectScopeTypeWeak
#define DVEInjectScopeTypeSingleton IESInjectScopeTypeSingleton


#endif /* DVEFoundationInject_h */
