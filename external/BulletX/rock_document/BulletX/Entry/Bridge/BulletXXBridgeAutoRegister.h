//
//  BulletXXBridgeAutoRegister.h
//  BulletX-Pods-Aweme
//
//  Created by bill on 2020/12/6.
//

#ifndef BulletXXBridgeAutoRegister_h
#define BulletXXBridgeAutoRegister_h

#import <BDXBridgeKit/BDXBridge.h>

#ifndef BDX_BDXBRIDGE_CONCAT
#define BDX_BDXBRIDGE_CONCAT2(A, B) A##B
#define BDX_BDXBRIDGE_CONCAT(A, B) BDX_BDXBRIDGE_CONCAT2(A, B)
#endif

/*
 * You can use @BDXBRIDGE_REGISTER_BDX_METHOD to specify a BDXBridgeMethod will
 * be registered into BDXBridge instance automatically. This annotation should
 * only be used for BDXBridgeMethod subclasses, and before the @implementation
 * code fragment in the .m file. e.g.: XXXBridgeAppInfoMethod is a subclass of
 * BDXBridgeMethod, in XXXBridgeAppInfoMethod.m
 * // ...import headers...
 * @BDXBRIDGE_REGISTER_BDX_METHOD(XXXBridgeAppInfoMethod)
 * @implmentation XXXBridgeAppInfoMethod
 * //...
 * @end
 */

#ifndef BDXBRIDGE_REGISTER_BDX_METHOD
#define BDXBRIDGE_REGISTER_BDX_METHOD(clsName)                                                                                                      \
    interface BDXBridge(clsName) @end @implementation BDXBridge(clsName)                                                                            \
    +(NSString *)BDX_BDXBRIDGE_CONCAT(__bdxbridge_bullet_auto_method__, BDX_BDXBRIDGE_CONCAT(clsName, BDX_BDXBRIDGE_CONCAT(__LINE__, __COUNTER__))) \
    {                                                                                                                                               \
        return @ #clsName;                                                                                                                          \
    }                                                                                                                                               \
    @end
#endif

#endif /* BulletXXBridgeAutoRegister_h */
