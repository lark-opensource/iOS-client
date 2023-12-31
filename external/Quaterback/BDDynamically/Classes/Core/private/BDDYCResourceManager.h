//
//  BDDYCResourceManager.h
//  BDDynamically
//
//  Created by zuopengliu on 29/8/2018.
//

#import <Foundation/Foundation.h>



NS_ASSUME_NONNULL_BEGIN

#if BDAweme
__attribute__((objc_runtime_name("AWECFRescript")))
#elif BDNews
__attribute__((objc_runtime_name("TTDBrackenFem")))
#elif BDHotSoon
__attribute__((objc_runtime_name("HTSDBigCamel")))
#elif BDDefault
__attribute__((objc_runtime_name("BDDCelery")))
#endif
@interface BDDYCResourceManager : NSObject

@end


NS_ASSUME_NONNULL_END
