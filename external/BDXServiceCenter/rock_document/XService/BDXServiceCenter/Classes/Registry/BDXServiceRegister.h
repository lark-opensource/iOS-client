//
//  BDXServiceRegister.h
//  BDXServiceManager-Pods-Aweme
//
//  Created by bill on 2021/3/1.
//

#ifndef BDXServiceRegister_h
#define BDXServiceRegister_h

#import "BDXServiceManager.h"

#ifndef BDXSERVICE_CONCAT
#define BDXSERVICE_CONCAT2(A, B) A##B
#define BDXSERVICE_CONCAT(A, B) BDXSERVICE_CONCAT2(A, B)
#endif

/*
 * You can use @BDXSERVICE_REGISTER to specify a BDXServiceManagerMethod will be
 * registered into BDXServiceManager instance automatically. This annotation
 * should only be used for BDXServiceManager subclasses, and before the
 * @implementation code fragment in the .m file. e.g.: BDXResourceLoaderService
 * is a subclass of BDXServiceManager, in BDXResourceLoaderService.m
 * // ...import headers...
 * @BDXSERVICE_REGISTER(BDXResourceLoaderService)
 * @implmentation BDXResourceLoaderService
 * //...
 * @end
 */

#ifndef BDXSERVICE_REGISTER
#define BDXSERVICE_REGISTER(clsName)                                                                                                           \
    interface BDXServiceManager(clsName) @end @implementation BDXServiceManager(clsName)                                                       \
    +(NSString *)BDXSERVICE_CONCAT(__bdxservice_auto_register_serivce__, BDXSERVICE_CONCAT(clsName, BDXSERVICE_CONCAT(__LINE__, __COUNTER__))) \
    {                                                                                                                                          \
        return @ #clsName;                                                                                                                     \
    }                                                                                                                                          \
    @end
#endif

#endif /* BDXServiceRegister_h */
