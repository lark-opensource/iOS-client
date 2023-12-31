//
//  HMDNetworkSpeed.m
//  Heimdallr
//
//  Created by sunrunwang on 2019/2/14.
//

#include <stdbool.h>
#include <sys/socket.h>
#include <stdio.h>
#include <stddef.h>
#include <net/if.h>
#include <ifaddrs.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <stdlib.h>
#include <net/if_dl.h>
#include <string.h>

#include "pthread_extended.h"
#include <objc/message.h>
#include <float.h>
#import "HMDMacro.h"
#import "HMDNetworkSpeedManager.h"
#import "HMDReference.h"
#import "NSArray+HMDSafe.h"

#define HMDNetworkSpeedIntervalDefault          0.2     // mostly don't change this
#define HMDNetworkSpeedAverageTimeDefault       1       // mostly don't change this
#define HMDNetworkSpeedIntervalLimit            0.02    // interval should no less than this value
#define HMDNetworkSpeedPreciousArrayMaxCount    42      // max is NSUIntegerMax, and no less that 2

#pragma mark - C level functionarity

// Description: (essential function)
// HMDNetworkSpeedGetCurrentUploadBytes get the current uploaded bytes from
// WLAN("en0") port on your device based on FreeBSD name rule and compatitable
// with most unix-based system, name begin with "en" && LINK-layer
// Return value:
// all bytes since the network card start up, you may devided to time to get
// the current internet speed accurrately
static u_int32_t HMDNetworkSpeedGetCurrentWLANUploadBytes(struct ifaddrs * _Nonnull networkInterfaceList);

// Description: (essential function)
// HMDNetworkSpeedGetCurrentDownloadBytes get the current download bytes from
// WLAN("en0") port on your device based on FreeBSD name rule and compatitable
// with most unix-based system, name begin with "en" && LINK-layer
// Return value:
// all bytes since the network card start up, you may devided to time to get
// the current internet speed accurrately
static u_int32_t HMDNetworkSpeedGetCurrentWLANDownloadBytes(struct ifaddrs * _Nonnull networkInterfaceList);

// Description: (essential function)
// HMDNetworkSpeedGetCurrentUploadBytes get the current uploaded bytes from
// Cellular("pdp_ip") port on your device based on FreeBSD name rule and compatitable
// with most unix-based system, name begin with "en" && LINK-layer
// Return value:
// all bytes since the network card start up, you may devided to time to get
// the current internet speed accurrately
static u_int32_t HMDNetworkSpeedGetCurrentCellularUploadBytes(struct ifaddrs * _Nonnull networkInterfaceList);

// Description: (essential function)
// HMDNetworkSpeedGetCurrentDownloadBytes get the current download bytes from
// Cellular("pdp_ip") port on your device based on FreeBSD name rule and compatitable
// with most unix-based system, name begin with "en" && LINK-layer
// Return value:
// all bytes since the network card start up, you may devided to time to get
// the current internet speed accurrately
static u_int32_t HMDNetworkSpeedGetCurrentCellularDownloadBytes(struct ifaddrs * _Nonnull networkInterfaceList);

// Description: (essential function)
// HMDNetworkSpeedIsWLANAvailable check if current WLAN is connected and ready to
// send/receive messages by checking "en0" interface and IP4/IP6 address
static bool HMDNetworkSpeedIsWLANAvailable(struct ifaddrs * _Nonnull networkInterfaceList);

// Description: (essential function)
// HMDNetworkSpeedIsCellularAvailable check if current cellular is connected and ready to
// send/receive messages by checking "pdp_ip0" interface and IP4/IP6 address
static bool HMDNetworkSpeedIsCellularAvailable(struct ifaddrs * _Nonnull networkInterfaceList);

#ifdef DEBUG
// Description: (debug function)
// display_networkInterface displays current internet interfaces to stdout
// currently only the IP4 IP6 LINK address is correctly displayed
// "PTP addr" means pointer-to-pointer broadcast address
static void HMDNetworkSpeed_display_networkInterface(void);
#endif

#pragma mark - Objective-C functionarity

@interface HMDNetworkSpeedData ()
@property(nonatomic, assign, readwrite) CGFloat uploadSpeed_WIFI;
@property(nonatomic, assign, readwrite) CGFloat downloadSpeed_WIFI;
@property(nonatomic, assign, readwrite) CGFloat uploadSpeed_cellular;
@property(nonatomic, assign, readwrite) CGFloat downloadSpeed_cellular;
@property(nonatomic, assign, readwrite) NSTimeInterval actualAverageTime;
@property(nonatomic, assign, readwrite, getter=isCellularAvailable) BOOL cellularAvailable;
@property(nonatomic, assign, readwrite, getter=isWIFIAvailable) BOOL WIFIAvailable;
@end

@interface HMDNetworkSpeedManager ()
@property(nonatomic, assign, readwrite) CGFloat uploadSpeed_WIFI;   // In bytes
@property(nonatomic, assign, readwrite) CGFloat downloadSpeed_WIFI;
@property(nonatomic, assign, readwrite) CGFloat uploadSpeed_cellular;
@property(nonatomic, assign, readwrite) CGFloat downloadSpeed_cellular;
@property(nonatomic, assign, readwrite, getter=isCellularAvailable) BOOL cellularAvailable;
@property(nonatomic, assign, readwrite, getter=isWIFIAvailable) BOOL WIFIAvailable;
@end

@implementation HMDNetworkSpeedManager {
    pthread_mutex_t _mutex;
    dispatch_source_t _timer;
    NSMutableArray<MDNetworkSpeedDataCallback> *_blockArray;
    NSMutableArray<NSNumber *> *_uploadBytesArray_WIFI;
    NSMutableArray<NSNumber *> *_downloadBytesArray_WIFI;
    NSMutableArray<NSNumber *> *_uploadBytesArray_cellular;
    NSMutableArray<NSNumber *> *_downloadBytesArray_cellular;
    NSMutableArray<NSNumber *> *_dataTimeArray;
}

@synthesize interval = _interval,   // OC safety (为了兼容安全)
 intendedAverageTime = _intendedAverageTime,
              repeat = _repeat;

@dynamic started;

- (instancetype)init {
    if(self = [self initWithInterval:HMDNetworkSpeedIntervalDefault
                 intendedAverageTime:HMDNetworkSpeedAverageTimeDefault
                              repeat:YES]) {
        // empty body to match case (compiler auto optimized)
    }
    return self;
}

- (instancetype)initWithInterval:(CGFloat)interval
             intendedAverageTime:(CGFloat)intendedAverageTime
                          repeat:(BOOL)repeat {
    if(self = [super init]) {
        pthread_mutexattr_t attr;
        pthread_mutexattr_init(&attr);
        pthread_mutex_init(&_mutex, &attr);
        pthread_mutexattr_destroy(&attr);
        
        if(isnan(interval) || isinf(interval)) {
            interval = HMDNetworkSpeedIntervalDefault;
            DEBUG_POINT;
        }
        
        if(isnan(intendedAverageTime) || isinf(intendedAverageTime)) {
            intendedAverageTime = HMDNetworkSpeedAverageTimeDefault;
            DEBUG_POINT;
        }
        
        if(interval < HMDNetworkSpeedIntervalLimit)
             _interval = HMDNetworkSpeedIntervalLimit;
        else _interval = interval;
        
        if(intendedAverageTime < _interval)
             _intendedAverageTime = _interval;
        else _intendedAverageTime = intendedAverageTime;
        
        _repeat = repeat;
        
        _blockArray = [NSMutableArray array];
        
        _uploadBytesArray_WIFI = [NSMutableArray array];
        _downloadBytesArray_WIFI = [NSMutableArray array];
        _uploadBytesArray_cellular = [NSMutableArray array];
        _downloadBytesArray_cellular = [NSMutableArray array];
        _dataTimeArray = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc {
    pthread_mutex_lock(&_mutex);
    [_blockArray removeAllObjects];
    if(_timer != nil) {
        [self removeTimer_async];
    }
    pthread_mutex_unlock(&_mutex);
}

+ (void)averageSpeedOverTimeDuration:(NSTimeInterval)duration
                   withBlockNoRepeat:(MDNetworkSpeedDataCallback)userCallback {
    if(userCallback == nil) DEBUG_RETURN_NONE;
    
    HMDNetworkSpeedManager *manager = [[HMDNetworkSpeedManager alloc]
                                       initWithInterval:duration
                                       intendedAverageTime:duration
                                       repeat:NO];
    
    void *castObject = (__bridge void *)manager;
    HMDRetainRaw(castObject);
    [manager addRegisterWithBlock:^(HMDNetworkSpeedData *data) {
        userCallback(data);
        HMDReleaseRaw(castObject);
    }];
}

- (BOOL)repeat {
    pthread_mutex_lock(&_mutex);
    BOOL result = _repeat;
    pthread_mutex_unlock(&_mutex);
    return result;
}

- (void)setRepeat:(BOOL)repeat {
    pthread_mutex_lock(&_mutex);
    if(_timer == nil)
        _repeat = repeat;
    pthread_mutex_unlock(&_mutex);
}

- (CGFloat)interval {
    pthread_mutex_lock(&_mutex);
    CGFloat result = _interval;
    pthread_mutex_unlock(&_mutex);
    return result;
}

- (void)setInterval:(CGFloat)intervals {
    if(intervals < HMDNetworkSpeedIntervalLimit)
        intervals = HMDNetworkSpeedIntervalLimit;
    pthread_mutex_lock(&_mutex);
    if(_timer == nil)
        _interval = intervals;
    pthread_mutex_unlock(&_mutex);
}

- (CGFloat)intendedAverageTime {
    pthread_mutex_lock(&_mutex);
    CGFloat result = _intendedAverageTime;
    pthread_mutex_unlock(&_mutex);
    return result;
}

- (void)setIntendedAverageTime:(CGFloat)averageTime {
    pthread_mutex_lock(&_mutex);
    if(_timer == nil) {
        if(averageTime < _interval)
            _intendedAverageTime = _interval;
        else
            _intendedAverageTime = averageTime;
    }
    pthread_mutex_unlock(&_mutex);
}

- (BOOL)isStarted {
    BOOL result;
    pthread_mutex_lock(&_mutex);
    result = _timer != nil;
    pthread_mutex_unlock(&_mutex);
    return result;
}

#pragma mark - Main access function

- (id)addRegisterWithBlock:(MDNetworkSpeedDataCallback)block {
    NSAssert(block != nil, @"addRegisterWithBlock: nil");
    if(block == nil) return nil;
    
    pthread_mutex_lock(&_mutex);
    if([_blockArray containsObject:block]) {
        pthread_mutex_unlock(&_mutex);
        return nil;
    }
    [_blockArray addObject:block];
    if(_timer == nil) [self addTimerAndCleanDataArray_async];
    pthread_mutex_unlock(&_mutex);
    return block;
}


- (void)removeRegistedBlock:(id)blockIndetifier {
    NSAssert(blockIndetifier != nil, @"removeRegistedBlock: nil");
    if(blockIndetifier == nil) return;
    
    pthread_mutex_lock(&_mutex);
    
    BOOL hasBlock = NO;
    
    for(id eachBlock in _blockArray)
        if(eachBlock == blockIndetifier) {
            hasBlock = YES;
            break;
        }
    
    if(hasBlock) [_blockArray removeObject:blockIndetifier];
    
    if(_blockArray.count == 0 && _timer != nil)
        [self removeTimer_async];
    
    pthread_mutex_unlock(&_mutex);
}

- (void)removeAllRegistedBlock {
    pthread_mutex_lock(&_mutex);
    
    [_blockArray removeAllObjects];
    if(_timer != nil)
        [self removeTimer_async];
    
    pthread_mutex_unlock(&_mutex);
}

- (void)timerCallback {
    pthread_mutex_lock(&_mutex);
    
    if(_blockArray.count == 0) {
        DEBUG_ASSERT(_timer == nil);
        pthread_mutex_unlock(&_mutex);
        return;
    }
    
    NSArray *blockArray = [_blockArray copy];
    if(!_repeat) {
        [_blockArray removeAllObjects];
        [self removeTimer_async];
    }
    
    [self updateSpeedInformation_async];
    
    NSTimeInterval timeRange = _dataTimeArray.lastObject.doubleValue - _dataTimeArray.firstObject.doubleValue;
    
    pthread_mutex_unlock(&_mutex);
    
    HMDNetworkSpeedData *data = [[HMDNetworkSpeedData alloc] init];
    data.uploadSpeed_WIFI       = self.uploadSpeed_WIFI;
    data.downloadSpeed_WIFI     = self.downloadSpeed_WIFI;
    data.uploadSpeed_cellular   = self.uploadSpeed_cellular;
    data.downloadSpeed_cellular = self.downloadSpeed_cellular;
    data.WIFIAvailable          = self.WIFIAvailable;
    data.cellularAvailable      = self.cellularAvailable;
    
    if(timeRange <= 0.0) data.actualAverageTime = 0.0;
    else data.actualAverageTime = timeRange;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        for(MDNetworkSpeedDataCallback eachBlock in blockArray)
            eachBlock(data);
    });
}

#pragma mark - Asynchronized method (needs lock before call and can't lock anymore)

- (void)addTimerAndCleanDataArray_async {
    if (_timer != nil) DEBUG_RETURN_NONE;
    
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, DISPATCH_TARGET_QUEUE_DEFAULT);
    
    dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, _interval * NSEC_PER_SEC);
    dispatch_source_set_timer(_timer, startTime, _interval * NSEC_PER_SEC, _interval * NSEC_PER_SEC);
    
    @weakify(self);
    dispatch_source_set_event_handler(_timer, ^{
        @strongify(self);
        
        [self timerCallback];
    });
    
    [self cleanDataAndSetTheFirstObject_async];
    
    dispatch_resume(_timer);
}

- (void)removeTimer_async {
    if(_timer == nil) DEBUG_RETURN_NONE;
    
    dispatch_source_cancel(_timer);
    _timer = nil;
}

- (void)cleanDataAndSetTheFirstObject_async {
    [_uploadBytesArray_WIFI removeAllObjects];
    [_downloadBytesArray_WIFI removeAllObjects];
    [_uploadBytesArray_cellular removeAllObjects];
    [_downloadBytesArray_cellular removeAllObjects];
    [_dataTimeArray removeAllObjects];
    
    NSTimeInterval currentTime = CFAbsoluteTimeGetCurrent();
    
    struct ifaddrs *networkInterfaceList;
    getifaddrs(&networkInterfaceList);
    
    NSUInteger wlanUpload = HMDNetworkSpeedGetCurrentWLANUploadBytes(networkInterfaceList);
    NSUInteger wlanDownload = HMDNetworkSpeedGetCurrentWLANDownloadBytes(networkInterfaceList);
    NSUInteger cellularUpload = HMDNetworkSpeedGetCurrentCellularUploadBytes(networkInterfaceList);
    NSUInteger cellularDownload = HMDNetworkSpeedGetCurrentCellularDownloadBytes(networkInterfaceList);
    
    freeifaddrs(networkInterfaceList);
    
    [_uploadBytesArray_WIFI hmd_addObject:[NSNumber numberWithUnsignedInteger:wlanUpload]];
    [_downloadBytesArray_WIFI hmd_addObject:[NSNumber numberWithUnsignedInteger:wlanDownload]];
    [_uploadBytesArray_cellular hmd_addObject:[NSNumber numberWithUnsignedInteger:cellularUpload]];
    [_downloadBytesArray_cellular hmd_addObject:[NSNumber numberWithUnsignedInteger:cellularDownload]];
    [_dataTimeArray hmd_addObject:[NSNumber numberWithDouble:currentTime]];
}

- (void)updateSpeedInformation_async {
    
    struct ifaddrs *networkInterfaceList;
    getifaddrs(&networkInterfaceList);
    
    /* Decide WIFI/cellular logic */
    BOOL isWLANAvailable = HMDNetworkSpeedIsWLANAvailable(networkInterfaceList);
    BOOL isCellularAvailable = HMDNetworkSpeedIsCellularAvailable(networkInterfaceList);
    
    /* Speed logic */
    NSUInteger wlanUpload = HMDNetworkSpeedGetCurrentWLANUploadBytes(networkInterfaceList);
    NSUInteger cellularUpload = HMDNetworkSpeedGetCurrentCellularUploadBytes(networkInterfaceList);
    NSUInteger wlanDownload = HMDNetworkSpeedGetCurrentWLANDownloadBytes(networkInterfaceList);
    NSUInteger cellularDownload = HMDNetworkSpeedGetCurrentCellularDownloadBytes(networkInterfaceList);
    
    freeifaddrs(networkInterfaceList);
    
    NSTimeInterval currentTime = CFAbsoluteTimeGetCurrent();
    
    self.WIFIAvailable = isWLANAvailable;
    self.cellularAvailable = isCellularAvailable;
    
    NSUInteger previousCount = _dataTimeArray.count;
    NSUInteger previousBeginTime = [_dataTimeArray.firstObject doubleValue];
    
    if(currentTime - previousBeginTime > _intendedAverageTime || previousCount + 1 > HMDNetworkSpeedPreciousArrayMaxCount)
        for(size_t index = 0; index + 1 < previousCount; index++) {
            if(currentTime - [_dataTimeArray[0] unsignedIntegerValue] > _intendedAverageTime) {
                [_uploadBytesArray_WIFI removeObjectAtIndex:0];
                [_downloadBytesArray_WIFI removeObjectAtIndex:0];
                [_uploadBytesArray_cellular removeObjectAtIndex:0];
                [_downloadBytesArray_cellular removeObjectAtIndex:0];
                [_dataTimeArray removeObjectAtIndex:0];
            }
            else break;
        }
    [_uploadBytesArray_WIFI hmd_addObject:[NSNumber numberWithUnsignedInteger:wlanUpload]];
    [_downloadBytesArray_WIFI hmd_addObject:[NSNumber numberWithUnsignedInteger:wlanDownload]];
    [_uploadBytesArray_cellular hmd_addObject:[NSNumber numberWithUnsignedInteger:cellularUpload]];
    [_downloadBytesArray_cellular hmd_addObject:[NSNumber numberWithUnsignedInteger:cellularDownload]];
    
    [_dataTimeArray hmd_addObject:[NSNumber numberWithDouble:currentTime]];
    
    NSTimeInterval averageInterval = currentTime - _dataTimeArray.firstObject.doubleValue;
    
    if(averageInterval == 0) {
        self.uploadSpeed_WIFI = DBL_MAX;
        self.downloadSpeed_WIFI = DBL_MAX;
        self.uploadSpeed_cellular = DBL_MAX;
        self.downloadSpeed_cellular = DBL_MAX;
    }
    else {
        self.uploadSpeed_WIFI = (wlanUpload - _uploadBytesArray_WIFI.firstObject.unsignedIntegerValue) / averageInterval;
        self.downloadSpeed_WIFI = (wlanDownload - _downloadBytesArray_WIFI.firstObject.unsignedIntegerValue) / averageInterval;
        self.uploadSpeed_cellular = (cellularUpload - _uploadBytesArray_cellular.firstObject.unsignedIntegerValue) / averageInterval;
        self.downloadSpeed_cellular = (cellularDownload - _downloadBytesArray_cellular.firstObject.unsignedIntegerValue) / averageInterval;
    }
}

#pragma mark - The rest

@end

@implementation HMDNetworkSpeedData // 返回数据类

+ (NSString *)stringlizationOfSpeed:(CGFloat)speed {
    unsigned long transferredSpeed;
    if(speed > ULONG_MAX) transferredSpeed = ULONG_MAX;
    else transferredSpeed = speed;
    
    if(transferredSpeed / HMD_KB == 0)
        return [NSString stringWithFormat:@"%lu B/s", (unsigned long)transferredSpeed];
    else if(transferredSpeed / HMD_MB == 0) {    // 1024 * 1024
        if(transferredSpeed / HMD_KB < 10)
            return [NSString stringWithFormat:@"%.1f KB/s", (double)transferredSpeed/HMD_KB];
        else
            return [NSString stringWithFormat:@"%lu KB/s", (unsigned long)(transferredSpeed/HMD_KB)];
    }
    else {
        if(transferredSpeed / HMD_MB < 10)
            return [NSString stringWithFormat:@"%.1f MB/s", (double)transferredSpeed/HMD_MB];
        else
            return [NSString stringWithFormat:@"%lu MB/s", (unsigned long)(transferredSpeed/HMD_MB)];
    }
}

@end

#ifdef DEBUG
static const char *address_to_readable_string(struct sockaddr *addr);
#endif

#pragma mark - Easy access function (essential part)

// Description: (essential function)
// HMDNetworkSpeedGetCurrentUploadBytes get the current uploaded bytes from
// all ethenet ports on your device based on FreeBSD name rule and compatitable
// with most unix-based system, name begin with "en" && LINK-layer
// Return value:
// all bytes since the network card start up, you may devided to time to get
// the current internet speed accurrately
static u_int32_t HMDNetworkSpeedGetCurrentWLANUploadBytes(struct ifaddrs * _Nonnull networkInterfaceList) {
    DEBUG_ASSERT(networkInterfaceList != NULL);
    struct ifaddrs *current = networkInterfaceList;
    u_int32_t result = 0;
    while(current != NULL) {
        if(current->ifa_addr != NULL &&
           current->ifa_addr->sa_family == AF_LINK &&
           strncmp("en0", current->ifa_name, 3) == 0 &&
           current->ifa_data != NULL) {
            struct if_data *data = current->ifa_data;
            result += data->ifi_obytes;
        }
        current = current -> ifa_next;
    }
    return result;
}

// Description: (essential function)
// HMDNetworkSpeedGetCurrentDownloadBytes get the current download bytes from
// all ethenet ports on your device based on FreeBSD name rule and compatitable
// with most unix-based system, name begin with "en" && LINK-layer
// Return value:
// all bytes since the network card start up, you may devided to time to get
// the current internet speed accurrately
static u_int32_t HMDNetworkSpeedGetCurrentWLANDownloadBytes(struct ifaddrs * _Nonnull networkInterfaceList) {
    DEBUG_ASSERT(networkInterfaceList != NULL);
    struct ifaddrs *current = networkInterfaceList;
    u_int32_t result = 0;
    while(current != NULL) {
        if(current->ifa_addr != NULL &&
           current->ifa_addr->sa_family == AF_LINK &&
           strncmp("en0", current->ifa_name, 3) == 0 &&
           current->ifa_data != NULL) {
            struct if_data *data = current->ifa_data;
            result += data->ifi_ibytes;
        }
        current = current -> ifa_next;
    }
    return result;
}

// Description: (essential function)
// HMDNetworkSpeedGetCurrentUploadBytes get the current uploaded bytes from
// all Cellular("pdp_ip") ports on your device based on FreeBSD name rule and compatitable
// with most unix-based system, name begin with "en" && LINK-layer
// Return value:
// all bytes since the network card start up, you may devided to time to get
// the current internet speed accurrately
static u_int32_t HMDNetworkSpeedGetCurrentCellularUploadBytes(struct ifaddrs * _Nonnull networkInterfaceList) {
    DEBUG_ASSERT(networkInterfaceList != NULL);
    struct ifaddrs *current = networkInterfaceList;
    u_int32_t result = 0;
    while(current != NULL) {
        if(current->ifa_addr != NULL &&
           current->ifa_addr->sa_family == AF_LINK &&
           strncmp("pdp_ip0", current->ifa_name, 7) == 0 &&
           current->ifa_data != NULL) {
            struct if_data *data = current->ifa_data;
            result += data->ifi_obytes;
        }
        current = current -> ifa_next;
    }
    return result;
}

// Description: (essential function)
// HMDNetworkSpeedGetCurrentDownloadBytes get the current download bytes from
// all Cellular("pdp_ip") ports on your device based on FreeBSD name rule and compatitable
// with most unix-based system, name begin with "en" && LINK-layer
// Return value:
// all bytes since the network card start up, you may devided to time to get
// the current internet speed accurrately
static u_int32_t HMDNetworkSpeedGetCurrentCellularDownloadBytes(struct ifaddrs * _Nonnull networkInterfaceList) {
    DEBUG_ASSERT(networkInterfaceList != NULL);
    struct ifaddrs *current = networkInterfaceList;
    u_int32_t result = 0;
    while(current != NULL) {
        if(current->ifa_addr != NULL &&
           current->ifa_addr->sa_family == AF_LINK &&
           strncmp("pdp_ip0", current->ifa_name, 7) == 0 &&
           current->ifa_data != NULL) {
            struct if_data *data = current->ifa_data;
            result += data->ifi_ibytes;
        }
        current = current -> ifa_next;
    }
    return result;
}
// Description: (essential function)
// HMDNetworkSpeedIsWLANAvailable check if current WLAN is connected and ready to
// send/receive messages by checking "en0" interface and IP4/IP6 address
static bool HMDNetworkSpeedIsWLANAvailable(struct ifaddrs * _Nonnull networkInterfaceList) {
    DEBUG_ASSERT(networkInterfaceList != NULL);
    struct ifaddrs *current = networkInterfaceList;
    bool result = false;
    while(current != NULL) {
        if(strncmp("en0", current->ifa_name, 3) == 0 &&
           current->ifa_addr != NULL &&
           (current->ifa_addr->sa_family == AF_INET || current->ifa_addr->sa_family == AF_INET6)) {
            result = true;
            break;
        }
        current = current -> ifa_next;
    }
    return result;
}

// Description: (essential function)
// HMDNetworkSpeedIsCellularAvailable check if current cellular is connected and ready to
// send/receive messages by checking "pdp_ip0" interface and IP4/IP6 address
static bool HMDNetworkSpeedIsCellularAvailable(struct ifaddrs * _Nonnull networkInterfaceList) {
    DEBUG_ASSERT(networkInterfaceList != NULL);
    struct ifaddrs *current = networkInterfaceList;
    bool result = false;
    while(current != NULL) {
        if(strncmp("pdp_ip0", current->ifa_name, 7) == 0 &&
           current->ifa_addr != NULL &&
           (current->ifa_addr->sa_family == AF_INET || current->ifa_addr->sa_family == AF_INET6)) {
            result = true;
            break;
        }
        current = current -> ifa_next;
    }
    return result;
}


#pragma mark - Understanding

// NO1 UNIX interface
//
// #include <sys/types.h>
// #include <ifaddrs.h>
// int getifaddrs(struct ifaddrs **ifap);
// void freeifaddrs(struct ifaddrs *ifa);

// NO2 struct ifaddrs
//struct ifaddrs {
//    struct ifaddrs  *ifa_next;          Next item in list
//    char            *ifa_name;          Name of interface
//    unsigned int     ifa_flags;         Flags from SIOCGIFFLAGS
//    struct sockaddr *ifa_addr;          Address of interface
//    struct sockaddr *ifa_netmask;       Netmask of interface
//    union {
//        struct sockaddr *ifu_broadaddr; Broadcast address
//        struct sockaddr *ifu_dstaddr    Point-to-point destination address
//    } ifa_ifu;
//    void            *ifa_data;          Address-specific data
//};

/*
 ifa_flags are or combination of below macro
 
 IFF_UP           interface is up (running)
 IFF_BROADCAST    broadcast address valid
 IFF_DEBUG        turn on debugging
 IFF_LOOPBACK     is a loopback net (allow local network 127.0.0.1)
 IFF_POINTOPOINT  interface is point-to-point link
 IFF_NOTRAILERS   obsolete: avoid use of trailers
 IFF_RUNNING      resources allocated
 IFF_NOARP        no Address Resolution Protocol
 IFF_PROMISC      receive all packets (not filter un-used pack)
 IFF_ALLMULTI     receive all multicast packets
 IFF_OACTIVE      transmission in progress (on active)
 IFF_SIMPLEX      can't hear own transmissions
 IFF_LINK0        per link layer defined bit
 IFF_LINK1        per link layer defined bit
 IFF_LINK2        per link layer defined bit
 IFF_ALTPHYS      use alternate physical connection
 IFF_MULTICAST    supports multicast
 */

// NO3 struct ifa_data (struct if_data)
//struct if_data {
//    // generic interface information
//    u_char       ifi_type;          ethernet, tokenring, etc
//    u_char       ifi_typelen;       Length of frame type id
//    u_char       ifi_physical;      e.g., AUI, Thinnet, 10base-T, etc
//    u_char       ifi_addrlen;       media address length
//    u_char       ifi_hdrlen;        media header length
//    u_char       ifi_recvquota;     polling quota for receive intrs
//    u_char       ifi_xmitquota;     polling quota for xmit intrs
//    u_char       ifi_unused1;       for future use
//    u_int32_t    ifi_mtu;           maximum transmission unit
//    u_int32_t    ifi_metric;        routing metric (external only)
//    u_int32_t    ifi_baudrate;      linespeed
//
//    // volatile statistics
//    u_int32_t    ifi_ipackets;      packets received on interface
//    u_int32_t    ifi_ierrors;       input errors on interface
//    u_int32_t    ifi_opackets;      packets sent on interface
//    u_int32_t    ifi_oerrors;       output errors on interface
//    u_int32_t    ifi_collisions;    collisions on csma interfaces
//    u_int32_t    ifi_ibytes;        total number of octets received
//    u_int32_t    ifi_obytes;        total number of octets sent
//    u_int32_t    ifi_imcasts;       packets received via multicast
//    u_int32_t    ifi_omcasts;       packets sent via multicast
//    u_int32_t    ifi_iqdrops;       dropped on input, this interface
//    u_int32_t    ifi_noproto;       destined for unsupported protocol
//    u_int32_t    ifi_recvtiming;    usec spent receiving when timing
//    u_int32_t    ifi_xmittiming;    usec spent xmitting when timing
//    struct IF_DATA_TIMEVAL ifi_lastchange;   time of last administrative change
//    u_int32_t    ifi_unused2;       used to be the default_proto
//    u_int32_t    ifi_hwassist;      HW offload capabilities
//    u_int32_t    ifi_reserved1;     for future use
//    u_int32_t    ifi_reserved2;     for future use
//};

#pragma mark - Debugging

#ifdef DEBUG
// Description: (debug function)
// display_networkInterface displays current internet interfaces to stdout
// currently only the IP4 IP6 LINK address is correctly displayed
// "PTP addr" means pointer-to-pointer broadcast address
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_UNUSED_FUNCTION
void HMDNetworkSpeed_display_networkInterface(void) {
    struct ifaddrs *networkInterfaceList, *current;
    getifaddrs(&networkInterfaceList);
    current = networkInterfaceList;
    while(current != NULL) {
        if(strncmp("en", current->ifa_name, 2) == 0)
            fprintf(stdout, "     Type: enthenet\n");
        else if(strncmp("lo", current->ifa_name, 2) == 0)
            fprintf(stdout, "     Type: loopback (local 127.0.0.1)\n");
        else if(strncmp("awd", current->ifa_name, 3) == 0)
            fprintf(stdout, "     Type: apple wireless direct Link\n");
        else if(strncmp("utun", current->ifa_name, 3) == 0)
            fprintf(stdout, "     Type: virtual interface\n");
        else
            fprintf(stdout, "     Type: unkown google yourself\n");
        fprintf(stdout, "     Name: %s\n", current->ifa_name);
        fprintf(stdout, "     Flag: %u\n", current->ifa_flags);
        fprintf(stdout, "  Address: %s\n",
                address_to_readable_string(current->ifa_addr));
        fprintf(stdout, "     Mask: %s\n",
                address_to_readable_string(current->ifa_netmask));
        if(current->ifa_flags & IFF_POINTOPOINT)
            fprintf(stdout, " PTP addr: %s\n",
                    address_to_readable_string(current->ifa_dstaddr));
        else if(current->ifa_flags & IFF_BROADCAST)
            fprintf(stdout, "Broadcast: %s\n",
                    address_to_readable_string(current->ifa_broadaddr));
        struct if_data *data = current->ifa_data;
        if(data != NULL) {
            fprintf(stdout, " Pack rec: %u\n", data->ifi_ipackets);
            fprintf(stdout, " Pack sed: %u\n", data->ifi_opackets);
            fprintf(stdout, "  Receive: %u bytes\n", data->ifi_ibytes);
            fprintf(stdout, "     Send: %u bytes\n", data->ifi_obytes);
        }
        if((current = current -> ifa_next) != NULL) putc('\n', stdout);
    }
    fprintf(stdout, "---End---\n");
    freeifaddrs(networkInterfaceList);
}
CLANG_DIAGNOSTIC_POP
// Description: (debug function)
// address_to_readable_string accept one struct sockaddr as an input, based on
// addr->sa_family to decide the way to display the address
// currently only the IP4 IP6 LINK address is correctly generated
// Return Value:
// return value is static allocated value and is cleared by later call, so multi
// thread is un-safe, this function is only intended for debugging
static const char *address_to_readable_string(struct sockaddr *addr) {
    if(addr == NULL) return "[NULL]";
    static char *result = NULL;
    char n;
    if(addr->sa_family == AF_INET) {
        char temp[INET_ADDRSTRLEN];
        struct sockaddr_in *ip4 = (struct sockaddr_in *)addr;
        int length = snprintf(&n, 1, "[IP4] %s(%u)",
                              inet_ntop(addr->sa_family, addr, temp, INET_ADDRSTRLEN),
                              ip4->sin_port);
        if(result != NULL) free(result);
        if((result = malloc(length + 1)) != NULL) {
            snprintf(result, length + 1, "[IP4] %s(%u)",
                     inet_ntop(addr->sa_family, addr, temp, INET_ADDRSTRLEN),
                     ip4->sin_port);
            return result;
        }
        return "address_to_string ip4 address allocation failed";
    }
    else if(addr->sa_family == AF_INET6) {
        char temp[INET6_ADDRSTRLEN];
        struct sockaddr_in6 *ip6 = (struct sockaddr_in6 *)addr;
        int length = snprintf(&n, 1, "[IP6] %s(%u)",
                              inet_ntop(addr->sa_family, addr, temp, INET6_ADDRSTRLEN),
                              ip6->sin6_port);
        if(result != NULL) free(result);
        if((result = malloc(length + 1)) != NULL) {
            snprintf(result, length + 1, "[IP6] %s(%u)",
                     inet_ntop(addr->sa_family, addr, temp, INET6_ADDRSTRLEN),
                     ip6->sin6_port);
            return result;
        }
        return "address_to_string ip6 address allocation failed";
    }
    else if(addr->sa_family == AF_LINK) {
        //        struct sockaddr_dl {
        //            u_char    sdl_len;        Total length of sockaddr
        //            u_char    sdl_family;     AF_LINK
        //            u_short    sdl_index;     if != 0, system given index for interface
        //            u_char    sdl_type;       interface type
        //            u_char    sdl_nlen;       interface name length, no trailing 0 reqd.
        //            u_char    sdl_alen;       link level address length
        //            u_char    sdl_slen;       link layer selector length
        //            char    sdl_data[12];     minimum work area, can be larger;
        //                                      contains both if name and ll address
        struct sockaddr_dl *link = (struct sockaddr_dl *)addr;
        int length = strlen("[LINK] ");
        if(link->sdl_alen == 0)
            length += strlen("null");
        else
            length += link->sdl_alen * 3 - 1;
        
        if(result != NULL) free(result);
        if((result = malloc(length + 1)) != NULL) {
            snprintf(result, length + 1, "[LINK] ");
            if(link->sdl_alen == 0)
                snprintf(result + strlen("[LINK] "),
                         length + 1 - strlen("[LINK] "), "null");
            else {
                size_t stringIndex = strlen("[LINK] ");
                for(size_t index = 0; index < link->sdl_alen; index++) {
                    snprintf(result+stringIndex, 3, "%02.2X",
                             *(const char *)(link->sdl_data + link->sdl_nlen + index));
                    if(index + 1 < link->sdl_alen) {
                        result[stringIndex + 2] = ':';
                        stringIndex += 3;
                    }
                    else
                        stringIndex += 2;
                }
            }
            return result;
        }
        return "address_to_string link address allocation failed";
    }
    else {
        int length = snprintf(&n, 1, "(%u)", addr->sa_family);
        if(result != NULL) free(result);
        if((result = malloc(length + 1)) != NULL) {
            snprintf(result, length + 1, "(%u)", addr->sa_family);
            return result;
        }
        return "address_to_string unkown address allocation failed";
    }
}
#endif

