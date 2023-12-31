//
//  HMDNetworkTraffic.h
//  Heimdallr
//
//  Created by fengyadong on 2018/1/23.
//

#import <Foundation/Foundation.h>

typedef struct {
    u_int32_t wifiSent;
    u_int32_t wifiReceived;
    u_int32_t cellularSent;
    u_int32_t cellularReceived;
    u_int32_t totalSent;
    u_int32_t totalReceived;
}hmd_IOBytes;

#ifdef __cplusplus
extern "C" {
#endif
/**
 获取系统网络流量
 */
extern hmd_IOBytes hmd_getFlowIOBytes(void);
#ifdef __cplusplus
    }
#endif
