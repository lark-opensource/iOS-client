//
//  BDALogAssert.h
//  BDALog
//
//  Created by kilroy on 2022/4/13.
//

#ifndef BDALogAssert_h
#define BDALogAssert_h

#include <stdio.h>
#include <assert.h>

#ifdef DEBUG
#define BDALOG_ASSERT(e) assert(e)
#else
#define BDALOG_ASSERT(e)
#endif

#endif /* BDALogAssert_h */
