//
//  HMDNetworkTraffic.m
//  Heimdallr
//
//  Created by fengyadong on 2018/4/25.
//

#import "HMDNetworkTraffic.h"
#include <ifaddrs.h>
#include <sys/socket.h>
#include <net/if.h>
#include <arpa/inet.h>

#define IOS_CELLULAR    @"pdp_ip0"
#define IOS_WIFI        @"en0"

hmd_IOBytes hmd_getFlowIOBytes(void) {
    struct ifaddrs *ifa_list= NULL, *ifa;
    hmd_IOBytes flow = {0,0,0,0,0,0};
    if (getifaddrs(&ifa_list)== -1) {
        return flow;
    }
    for (ifa = ifa_list; ifa; ifa = ifa->ifa_next) {
        if (AF_LINK != ifa->ifa_addr->sa_family)
            continue;
        if (!(ifa->ifa_flags& IFF_UP) &&!(ifa->ifa_flags & IFF_RUNNING))
            continue;
        if (ifa->ifa_data == 0)
            continue;
        if (strcmp(ifa->ifa_name,"en0") == 0) {
            // wifi
            struct if_data *if_data = (struct if_data*)ifa->ifa_data;
            flow.wifiReceived += if_data->ifi_ibytes;
            flow.wifiSent  += if_data->ifi_obytes;
        }else if (strcmp(ifa->ifa_name, "pdp_ip0") == 0) {
            struct if_data *if_data = (struct if_data *)ifa->ifa_data;
            flow.cellularReceived  += if_data->ifi_ibytes;
            flow.cellularSent += if_data->ifi_obytes;
        }
    }
    flow.totalReceived = flow.wifiReceived + flow.cellularReceived;
    flow.totalSent = flow.wifiSent + flow.cellularSent;
    freeifaddrs(ifa_list);
    return flow;
}
