//
//  c
//  Hello
//
//  Created by brent.shu on 2019/10/21.
//  Copyright © 2019 brent.shu. All rights reserved.
//

#ifndef ThreadManager_h
#define ThreadManager_h

#import <functional>

namespace MemoryGraph {

struct ThreadSuspender {
    bool is_suspended;
    
    ThreadSuspender(const char *file_identify, std::function<bool ()> lockChecker);
    
    ~ThreadSuspender();
    
    void resume();
};

} // MemoryGraph

#endif /* ThreadManager_h */
