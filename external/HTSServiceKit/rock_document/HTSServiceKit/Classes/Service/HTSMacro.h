//
//  HTSMacro.h
//  HTSBootLoader
//
//  Created by Huangwenchen on 2019/11/17.
//  Copyright © 2019 bytedance. All rights reserved.
//

#ifndef HTSBootMacro_h
#define HTSBootMacro_h

#define _HTS_CONCAT_PRIVATE(x,y) x##y
#define _HTS_CONCAT(x,y) _HTS_CONCAT_PRIVATE(x,y)
#define _HTS_TO_STRING_PRIVATE(x) #x
#define _HTS_TO_STRING(x) _HTS_TO_STRING_PRIVATE(x)
#define _HTS_SEGMENT "__DATA"
#define _HTS_LAZY_DELEGATE_SECTION "__HTSLazyDelegate"
#define _HTS_LIFE_CIRCLE_SECTION "__HTSLifeCycle"
#define _HTS_UNIQUE_VAR _HTS_CONCAT(__hts_var_, __COUNTER__)

#ifdef DEBUG
#define HTSLog(...) NSLog(__VA_ARGS__)
#else
#define HTSLog(...)
#endif

#endif /* HTSBootMacro_h */
