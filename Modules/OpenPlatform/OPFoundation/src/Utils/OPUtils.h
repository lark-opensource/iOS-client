//
//  OPUtils.h
//  OPFoundation
//
//  Created by yinyuan on 2020/12/16.
//

#import <UIKit/UIKit.h>
#import <ECOInfra/OPMacroUtils.h>

/// Returns If Array is Empty or Invalid
FOUNDATION_EXTERN BOOL OPIsEmptyArray(NSArray * _Nullable array);

/// Returns If String is Empty or Invalid
FOUNDATION_EXTERN BOOL OPIsEmptyString(NSString * _Nullable string);

/// Returns If Dictionary is Empty or Invalid
FOUNDATION_EXTERN BOOL OPIsEmptyDictionary(NSDictionary * _Nullable dict);

/// Returns NSArray Absolutely (Include Nil or Invalid Class)
FOUNDATION_EXTERN NSArray * _Nonnull OPSafeArray(NSArray * _Nullable array);

/// Returns NSString Absolutely (Include Nil or Invalid Class)
FOUNDATION_EXTERN NSString * _Nonnull OPSafeString(NSString * _Nullable string);

/// Returns NSDictionary Absolutely (Include Nil or Invalid Class)
FOUNDATION_EXTERN NSDictionary * _Nonnull OPSafeDictionary(NSDictionary * _Nullable dict);

/// Returns Dark Mode
FOUNDATION_EXTERN BOOL OPIsDarkMode(void);

