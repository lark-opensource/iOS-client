//
//  AWELazyRegisterPremain.h
//  AWELazyRegister
//
//  Created by Qingyao Li on 2020/1/3.
//

#import <Foundation/Foundation.h>
#import "AWELazyRegister.h"

#define AWELazyRegisterModulePremain "PremainCode"

/**
Usage:

@implementation HelloManager
 
+(void)myStaticMethod { ... }

AWELazyRegisterPremain()
{
   [HelloManager myStaticMethod];
}

@end
*/
#define AWELazyRegisterPremain() AWELazyRegisterBlock(AWELazyRegisterUniqueKey, AWELazyRegisterModulePremain)


/**
 Usage:
 
 @implementation HelloManager
 
 AWELazyRegisterPremainClass(HelloManager)
 {
    // code in previous +load
 }
 
 @end
 */
#define AWELazyRegisterPremainClass(ClassName) \
AWELazyRegisterPremain()\
{\
    [ClassName _aweLazyRegisterLoad];\
}\
+(void)_aweLazyRegisterLoad


/**
 Usage:
 
 @implementation UIViewController (XXXX)
 
 AWELazyRegisterPremainClassCategory(UIViewController, XXXX)
 {
    // code in previous +load
 }
 
 @end
 */
#define AWELazyRegisterPremainClassCategory(ClassName,CategoryName) \
AWELazyRegisterPremain()\
{\
    [ClassName _aweLazyRegisterLoad_##CategoryName];\
}\
+(void)_aweLazyRegisterLoad_##CategoryName
