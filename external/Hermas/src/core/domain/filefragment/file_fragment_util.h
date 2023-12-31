//
//  file_fragment_util.h
//  FFFileFragment
//
//  Created by zhouyang11 on 2022/6/7.
//

#ifndef file_manager_h
#define file_manager_h

#include <stdio.h>
#import "file_fragment_config.h"

#define align_up(x, align) (x+align-1)&(~(align-1))
#define align_down(x, align) x&(~(align-1))

#endif /* file_manager_h */
