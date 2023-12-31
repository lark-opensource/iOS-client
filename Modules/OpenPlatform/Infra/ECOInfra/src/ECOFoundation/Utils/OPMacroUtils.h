//
//  OPMacroUtils.h
//  OPFoundation
//
//  Created by Nicholas Tau on 2020/12/21.
//

#ifndef OPMacroUtils_h
#define OPMacroUtils_h

#pragma mark - StrongSelf & WeakSelf
/*-----------------------------------------------*/
//    StrongSelf & WeakSelf - Self 强弱引用相关
/*-----------------------------------------------*/
#ifndef WeakSelf
    #define WeakSelf __weak typeof(self) wself = self
#endif

#ifndef StrongSelf
    #define StrongSelf __strong typeof(wself) self = wself;
#endif

#ifndef StrongSelfIfNilReturn
    #define StrongSelfIfNilReturn \
    __strong typeof(wself) self = wself;\
    if (!self) {\
        return;\
    }
#endif

#ifndef StrongSelfIfNotNil
    #define StrongSelfIfNotNil(...) \
    __strong typeof(wself) self = wself;\
    if (self) {\
        __VA_ARGS__;\
    }
#endif

#define WeakObject(obj) __weak typeof(obj) weak##obj = obj
#define StrongObject(obj) __strong typeof(obj) obj = weak##obj
#define StrongObjectIfNilReturn(obj) \
StrongObject(obj);\
if (!obj) {\
    return;\
}

#endif /* OPMacroUtils_h */
