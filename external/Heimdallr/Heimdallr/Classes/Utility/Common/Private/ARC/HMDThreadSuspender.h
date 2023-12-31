//
//  c
//  Hello
//
//  Created by zhouyang11 on 2021/12/3.
//  Copyright © 2021 zhouyang11. All rights reserved.
//

#ifndef hmd_thread_suspender_h
#define hmd_thread_suspender_h

namespace HMDThreadSuspender {

struct ThreadSuspender {
    bool is_suspended;
    
    ThreadSuspender();
    
    ~ThreadSuspender();
    
    void resume();
};

} // ThreadSuspender

#endif /* hmd_thread_suspender_h */
