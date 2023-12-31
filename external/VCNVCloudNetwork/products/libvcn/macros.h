//
//  vcn_macros.h
//  network-1
//
//  Created by thq on 17/2/19.
//  Copyright © 2017年 thq. All rights reserved.
//

#ifndef macros_h
#define macros_h

/**
 * @addtogroup preproc_misc Preprocessor String Macros
 *
 * String manipulation macros
 *
 * @{
 */

#define AV_STRINGIFY(s)         AV_TOSTRING(s)
#define AV_TOSTRING(s) #s

#define AV_GLUE(a, b) a ## b
#define AV_JOIN(a, b) AV_GLUE(a, b)

/**
 * @}
 */

#define AV_PRAGMA(s) _Pragma(#s)

#define FFALIGN(x, a) (((x)+(a)-1)&~((a)-1))


#endif /* macros_h */
