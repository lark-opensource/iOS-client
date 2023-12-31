//
//  BDBitcodeVM.h
//  BDBitcodeVM
//
//  Created by zuopengliu on 7/5/2018.
//

#import <UIKit/UIKit.h>

//! Project version number for BDBitcodeVM.
FOUNDATION_EXPORT double BDBitcodeVMVersionNumber;

//! Project version string for BDBitcodeVM.
FOUNDATION_EXPORT const unsigned char BDBitcodeVMVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <BDBitcodeVM/PublicHeader.h>

#if __has_include(<Brady/BDBradyEngine.h>)
#import <Brady/BDBradyEngine.h>
#elif __has_include(<BDBradyEngine.h>)
#import <BDBradyEngine.h>
#endif
