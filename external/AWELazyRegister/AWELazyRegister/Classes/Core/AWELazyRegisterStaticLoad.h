//
//  AWELazyRegisterStaticLoad.h
//  AWELazyRegister-Pods-Aweme
//
//  Created by zhufeng on 2021/6/21.
//

#import <Foundation/Foundation.h>
#import "AWELazyRegister.h"

#define AWELazyRegisterModuleStaticLoad "StaticLoad"

/**
Usage:

@implementation HelloManager
 
+(void)myStaticMethod { ... }

AWELazyRegisterStaticLoad()
{
   [HelloManager myStaticMethod];
}

@end
*/
#define AWELazyRegisterStaticLoad() AWELazyRegisterBlock(AWELazyRegisterUniqueKey, AWELazyRegisterModuleStaticLoad)


/**
 Usage:
 
 @implementation HelloManager
 
 AWELazyRegisterStaticLoadClass(HelloManager)
 {
    // code in previous +load
 }
 
 @end
 */
#define AWELazyRegisterStaticLoadClass(ClassName) \
AWELazyRegisterStaticLoad()\
{\
    [ClassName _aweLazyRegisterStaticLoad];\
}\
+(void)_aweLazyRegisterStaticLoad


/**
 Usage:
 
 @implementation UIViewController (XXXX)
 
 AWELazyRegisterStaticLoadClassCategory(UIViewController, XXXX)
 {
    // code in previous +load
 }
 
 @end
 */
#define AWELazyRegisterStaticLoadClassCategory(ClassName,CategoryName) \
AWELazyRegisterStaticLoad()\
{\
    [ClassName _aweLazyRegisterStaticLoad_##CategoryName];\
}\
+(void)_aweLazyRegisterStaticLoad_##CategoryName
