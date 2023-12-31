//
//  BDDYCUtils.h
//  BDDynamically
//
//  Created by zuopengliu on 29/8/2018.
//

#import <Foundation/Foundation.h>
#import "BDDYCMacros.h"
#import "BDQuaterbackConfigProtocol.h"


BDDYC_EXTERN_C_BEGIN


/**
 Method swizzling
 */
BDDYC_EXTERN void BDDYCSwapClassMethods(Class cls, SEL original, SEL replacement);

BDDYC_EXTERN void BDDYCSwapInstanceMethods(Class cls, SEL original, SEL replacement);

#if BDAweme
__attribute__((objc_runtime_name("AWECFUproarious")))
#elif BDNews
__attribute__((objc_runtime_name("TTDMoss")))
#elif BDHotSoon
__attribute__((objc_runtime_name("HTSDOstrich")))
#elif BDDefault
__attribute__((objc_runtime_name("BDDWaterSpinach")))
#endif
@interface BDDYCUtils : NSObject
+ (NSDictionary *)appInfo;
+ (void)updateAppInfoWithAppVersion:(NSString *)appVersion channel:(NSString *)channel;
+ (BOOL)isValidPatchWithConfig:(id<BDQuaterbackConfigProtocol>)config needStrictCheck:(BOOL)needStrictCheck;
@end

BDDYC_EXTERN_C_END
