//
//  HMDMainRunloopMonitorV2.h
//  Pods
//
//  Created by ByteDance on 2023/9/6.
//

#import "HMDRunloopMonitor.h"

#ifndef HMDMainRunloopMonitorV2_h
#define HMDMainRunloopMonitorV2_h

class HMDMainRunloopMonitorV2 : public HMDRunloopMonitor {
    
public:
    // function
    static HMDMainRunloopMonitorV2* _Nonnull getInstance(void) {
        static HMDMainRunloopMonitorV2 *instance;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            instance = new HMDMainRunloopMonitorV2();
        });
        return instance;
    }
    
    bool isUITrackingRunloopMode(void);
    
private:
    
    HMDMainRunloopMonitorV2();
    
        
};


#endif /* HMDMainRunloopMonitorV2_h */
