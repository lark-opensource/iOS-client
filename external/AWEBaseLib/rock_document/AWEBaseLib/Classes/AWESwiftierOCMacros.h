//
//  AWESwiftierOCMacros.h
//  AWEBaseLib
//
//  Created by Leon.liu on 01/01/2020.
//

#ifndef AWESwiftierOCMacros_h
#define AWESwiftierOCMacros_h


// let
#if defined(__cplusplus)
#define let auto const
#else
#define let const __auto_type
#endif

// var
#if defined(__cplusplus)
#define var auto
#else
#define var __auto_type
#endif


#endif /* AWESwiftierOCMacros_h */
