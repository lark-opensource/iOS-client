//
//  AWEDTAdapter.h
//  AWEBaseLib
//
//  Created by 陈煜钏 on 2020/3/29.
//

#ifndef AWEDTAdapter_h
#define AWEDTAdapter_h

#define _AWEAdapterProtocolName(__className)    __className##Adapter

#define _AWEDefineAdapter(__protocol)       protocol __protocol <NSObject>

#define AWEDefineAdapter(__className)       _AWEDefineAdapter(_AWEAdapterProtocolName(__className))

#define _AWEConfirmsToAdapter(__className, __protocol)  \
interface __className(Adapter)<__protocol>              \
@end

#define AWEConfirmsToAdapter(__className)   _AWEConfirmsToAdapter(__className, _AWEAdapterProtocolName(__className))

#define _AWEAdapterProtocolName_categoryName(__className,__categoryName)    __className##__categoryName##Adapter

#define AWEDefineDTAdapter(__className,__categoryName)       _AWEDefineAdapter(_AWEAdapterProtocolName_categoryName(__className,__categoryName))

#define _AWEConfirmsToDTAdapter(__className,__categoryName, __protocol)  \
interface __className(__categoryName##_Adapter)<__protocol>              \
@end

#define AWEConfirmsToDTAdapter(__className,__categoryName)   _AWEConfirmsToDTAdapter(__className, __categoryName,_AWEAdapterProtocolName_categoryName(__className,__categoryName))

#define throwAbstractMethodException \
throw [NSException exceptionWithName:NSInternalInconsistencyException \
reason:[NSString stringWithFormat:@"%@ in %@ is defined as an abstract method which should be implemented", NSStringFromSelector(_cmd), NSStringFromClass([self class])] \
     userInfo:nil];

#define AWE_AVAILABLE_DY
#define AWE_AVAILABLE_DY_BEGIN
#define AWE_AVAILABLE_DY_END

// ANOTATION: ONLY USED IN I18N(MUSICALLY/TIKTOK)
#define AWE_AVAILABLE_MT
#define AWE_AVAILABLE_MT_BEGIN
#define AWE_AVAILABLE_MT_END

#endif /* AWEDTAdapter_h */
