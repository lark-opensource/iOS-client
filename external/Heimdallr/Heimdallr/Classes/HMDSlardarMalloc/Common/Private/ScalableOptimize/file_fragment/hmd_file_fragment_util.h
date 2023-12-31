//
//  file_fragment_util.h
//  FFFileFragment
//
//  Created by zhouyang11 on 2022/6/7.
//

#ifndef file_manager_h
#define file_manager_h

#define align_up(x, align) (x+align-1)&(~(align-1))
#define align_down(x, align) x&(~(align-1))

#define likely_if(x) if(__builtin_expect(x,1))
#define unlikely_if(x) if(__builtin_expect(x,0))

#include <stdio.h>

namespace HMDMemoryAllocator {
const char* mmap_file_tmp_path(const char* identifier);
}

#endif /* file_manager_h */
