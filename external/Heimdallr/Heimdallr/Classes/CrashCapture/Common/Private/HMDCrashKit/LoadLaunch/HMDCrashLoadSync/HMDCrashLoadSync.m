//
//  HMDCrashLoadSync.m
//  Heimdallr
//
//  Created by sunrunwang on 2024/08/08.
//

#import <sys/mman.h>
#import <stdatomic.h>
#import <mach/vm_page_size.h>

#define HMD_USE_DEBUG_ONCE

#import "HMDMacro.h"
#import "HMDInjectedInfo.h"
#import "HMDCrashLoadSync.h"
#import "HMDCrashLoadLogger.h"
#import "HMDCrashLoadProfile.h"
#import "NSDictionary+HMDJSON.h"
#import "HMDCrashLoadLogger+Path.h"
#import "HMDCrashLoadSync+Private.h"
#import "HMDCrashLoadSync_LowLevel.h"

#define HMD_CRASH_LOAD_SYNC_TIME_DELAY 1.0

@interface HMDCrashLoadSync ()

@property(nonatomic, readwrite) BOOL started;

@property(nonatomic, readwrite, nullable) NSString *mirrorPath;

@property(nonatomic, readwrite, nullable) NSString *currentDirectory;

@end

static bool loadLaunchStarting = NO;
static bool loadLaunchStarted  = NO;

@implementation HMDCrashLoadSync {
    
    BOOL _mirrorEnabled;
    NSString * _mirrorPath;
    
    dispatch_queue_t _queue;
    
    void * _mappedAddress;
    size_t _mappedSize;
    
    size_t _lastWrittenSize;
    
    BOOL _mirrorSetup;
}

@dynamic started, starting;

+ (instancetype)sync {
    static HMDCrashLoadSync *sync = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sync = HMDCrashLoadSync.alloc.init;
    });
    return sync;
}

#pragma mark - Starting

- (BOOL)starting {
    bool starting = __atomic_load_n(&loadLaunchStarting, __ATOMIC_ACQUIRE);
    return starting;
}

#pragma mark - Started

- (BOOL)started {
    bool started = __atomic_load_n(&loadLaunchStarted, __ATOMIC_ACQUIRE);
    return started;
}

#pragma mark - Mirror

- (NSString *)mirrorPath {
    DEBUG_RETURN(_mirrorPath);
}

- (void)setMirrorPath:(NSString *)mirrorPath {
    DEBUG_ONCE;
    
    _mirrorPath = mirrorPath;
    __atomic_store_n(&_mirrorEnabled, YES, __ATOMIC_RELEASE);
}

- (void)tackerCallback {
    DEBUG_ONCE;
    
    CLOAD_LOG("[Mirror] receive tracker callback");
    
    BOOL mirrorEnabled = __atomic_load_n(&_mirrorEnabled, __ATOMIC_ACQUIRE);
    if (!mirrorEnabled) return;
    
    _mirrorSetup = YES;
    
    vm_size_t page_size = vm_page_size;
    
    if(page_size < 0x1000) {
        CLOAD_LOG("[Mirror] failed, page_size is less than 4KB");
        DEBUG_RETURN_NONE;
    }
    
    const char * _Nullable rawPath = _mirrorPath.UTF8String;
    
    if(rawPath == nil) {
        CLOAD_LOG("[Mirror] mmap path is nil, tracker can not start mirror");
        DEBUG_RETURN_NONE;
    }
    
    CLOAD_LOG("[Mirror] open mirror.profile at path %s", CLOAD_PATH(_mirrorPath));
    
    int fd = open(rawPath, O_RDWR|O_CREAT, S_IRWXU);
    
    if(fd < 0) {
        CLOAD_LOG("[Mirror] failed, unable to open memory map at %s",
                  CLOAD_PATH(_mirrorPath));
        DEVELOP_DEBUG_RETURN_NONE;
    }
    
    if(ftruncate(fd, page_size) != 0) {
        CLOAD_LOG("[Mirror] failed, unable to truncate file to size %u",
                  (unsigned)page_size);
        
        close(fd);
        DEVELOP_DEBUG_RETURN_NONE;
    }
    
    void * memory_map = mmap(NULL, page_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if(memory_map == MAP_FAILED) {
        CLOAD_LOG("[Mirror] mmap profile file failed, errno %d", errno);
        close(fd);
        DEVELOP_DEBUG_RETURN_NONE;
    }
    
    // mlock(memory_map, page_size);
    
    close(fd);
    
    _queue = dispatch_queue_create("com.heimdallr.crash.loadLaunch.mirror",
                                   DISPATCH_QUEUE_SERIAL);
    
    if(_queue == nil) DEBUG_RETURN_NONE;
    
    DEBUG_ACTION(dispatch_queue_set_specific(_queue, (void *)0xAB143, (void *)0xAB143, NULL));
    
    _mappedAddress = memory_map;
    _mappedSize = page_size;
    
    HMDInjectedInfo * injectedInfo = HMDInjectedInfo.defaultInfo;
    
    if(injectedInfo == nil) DEBUG_RETURN_NONE;
    
    SEL channel_selector = @selector(channel);
    if(![injectedInfo respondsToSelector:channel_selector])
        DEBUG_RETURN_NONE;
    [injectedInfo addObserver:self
                   forKeyPath:NSStringFromSelector(channel_selector)
                      options:NSKeyValueObservingOptionNew
                      context:NULL];
    
    SEL appName_selector = @selector(appName);
    if(![injectedInfo respondsToSelector:appName_selector])
        DEBUG_RETURN_NONE;
    [injectedInfo addObserver:self
                   forKeyPath:NSStringFromSelector(appName_selector)
                      options:NSKeyValueObservingOptionNew
                      context:NULL];
    
    SEL installID_selector = @selector(installID);
    if(![injectedInfo respondsToSelector:installID_selector])
        DEBUG_RETURN_NONE;
    [injectedInfo addObserver:self
                   forKeyPath:NSStringFromSelector(installID_selector)
                      options:NSKeyValueObservingOptionNew
                      context:NULL];
    
    SEL deviceID_selector = @selector(deviceID);
    if(![injectedInfo respondsToSelector:deviceID_selector])
        DEBUG_RETURN_NONE;
    [injectedInfo addObserver:self
                   forKeyPath:NSStringFromSelector(deviceID_selector)
                      options:NSKeyValueObservingOptionNew
                      context:NULL];
    
    SEL userID_selector = @selector(userID);
    if(![injectedInfo respondsToSelector:userID_selector])
        DEBUG_RETURN_NONE;
    [injectedInfo addObserver:self
                   forKeyPath:NSStringFromSelector(userID_selector)
                      options:NSKeyValueObservingOptionNew
                      context:NULL];
    
    SEL scopedDeviceID_selector = @selector(scopedDeviceID);
    if(![injectedInfo respondsToSelector:scopedDeviceID_selector])
        DEBUG_RETURN_NONE;
    [injectedInfo addObserver:self
                   forKeyPath:NSStringFromSelector(scopedDeviceID_selector)
                      options:NSKeyValueObservingOptionNew
                      context:NULL];
    
    SEL scopedUserID_selector = @selector(scopedUserID);
    if(![injectedInfo respondsToSelector:scopedUserID_selector])
        DEBUG_RETURN_NONE;
    [injectedInfo addObserver:self
                   forKeyPath:NSStringFromSelector(scopedUserID_selector)
                      options:NSKeyValueObservingOptionNew
                      context:NULL];
    
    
    CLOAD_LOG("[Mirror] trigger first time mirror saving");
    
    dispatch_async(_queue, ^{   // Must be execute on queue
        [HMDCrashLoadSync.sync writeMirror];
    });
    
}

- (void)dealloc {
    // 其实这里根本不会执行, 只是为了过钟馗检查
    
    if(!_mirrorSetup) return;
    
    HMDInjectedInfo * injectedInfo = HMDInjectedInfo.defaultInfo;
    
    if(injectedInfo == nil) DEBUG_RETURN_NONE;
    
    SEL channel_selector = @selector(channel);
    if(![injectedInfo respondsToSelector:channel_selector])
        DEBUG_RETURN_NONE;
    [injectedInfo removeObserver:self
                      forKeyPath:NSStringFromSelector(channel_selector)];
    
    SEL appName_selector = @selector(appName);
    if(![injectedInfo respondsToSelector:appName_selector])
        DEBUG_RETURN_NONE;
    [injectedInfo removeObserver:self
                      forKeyPath:NSStringFromSelector(appName_selector)];
    
    SEL installID_selector = @selector(installID);
    if(![injectedInfo respondsToSelector:installID_selector])
        DEBUG_RETURN_NONE;
    [injectedInfo removeObserver:self
                      forKeyPath:NSStringFromSelector(installID_selector)];
    
    SEL deviceID_selector = @selector(deviceID);
    if(![injectedInfo respondsToSelector:deviceID_selector])
        DEBUG_RETURN_NONE;
    [injectedInfo removeObserver:self
                      forKeyPath:NSStringFromSelector(deviceID_selector)];
    
    SEL userID_selector = @selector(userID);
    if(![injectedInfo respondsToSelector:userID_selector])
        DEBUG_RETURN_NONE;
    [injectedInfo removeObserver:self
                      forKeyPath:NSStringFromSelector(userID_selector)];
    
    SEL scopedDeviceID_selector = @selector(scopedDeviceID);
    if(![injectedInfo respondsToSelector:scopedDeviceID_selector])
        DEBUG_RETURN_NONE;
    [injectedInfo removeObserver:self
                      forKeyPath:NSStringFromSelector(scopedDeviceID_selector)];
    
    SEL scopedUserID_selector = @selector(scopedUserID);
    if(![injectedInfo respondsToSelector:scopedUserID_selector])
        DEBUG_RETURN_NONE;
    [injectedInfo removeObserver:self
                      forKeyPath:NSStringFromSelector(scopedUserID_selector)];
}

#pragma mark - KVO callback

static atomic_uint saveCount = 0;

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    
    dispatch_time_t time =
    dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC));
    
    unsigned int previousCount =
        atomic_fetch_add_explicit(&saveCount, 1, memory_order_acq_rel);
    
    unsigned int thisTimeCount = previousCount + 1;
    
    CLOAD_LOG("[Mirror] trigger save this time count %u", thisTimeCount);
    
    dispatch_after(time, _queue, ^{
        unsigned int currentCount =
            atomic_load_explicit(&saveCount, memory_order_acquire);
        
        if(thisTimeCount != currentCount) {
            DEBUG_ASSERT(currentCount >= thisTimeCount);
            
            CLOAD_LOG("[Mirror] save cancelled for this time count %u, "
                      "current count %u", thisTimeCount, currentCount);
            
            return;
        }
        
        CLOAD_LOG("[Mirror] save apply for this time count %u", thisTimeCount);
        
        [HMDCrashLoadSync.sync writeMirror];
    });
}

#pragma mark - Write to file


- (void)writeMirror {
    DEBUG_ASSERT(_mirrorEnabled && _mirrorPath != nil);
    DEBUG_ASSERT(_queue != nil);
    DEBUG_ASSERT(_mappedAddress != NULL && _mappedSize == vm_page_size);
    DEBUG_ASSERT(dispatch_get_specific((void *)0xAB143) == (void *)0xAB143);
    
    if(_mappedAddress == NULL) DEBUG_RETURN_NONE;
    
    CLOAD_LOG("[Mirror][Save] starting");
    
    HMDInjectedInfo * injectedInfo = HMDInjectedInfo.defaultInfo;
    
    HMDCrashLoadProfile *profile = HMDCrashLoadProfile.alloc.init;
    
    profile.channel        = injectedInfo.channel;
    profile.appName        = injectedInfo.appName;
    profile.installID      = injectedInfo.installID;
    profile.deviceID       = injectedInfo.deviceID;
    profile.userID         = injectedInfo.userID;
    profile.scopedDeviceID = injectedInfo.scopedDeviceID;
    profile.scopedUserID   = injectedInfo.scopedUserID;
    
    CLOAD_LOG("[Mirror][Save] channel %s, appName %s, installID %s, "
              "deviceID %s, userID %s, scopedDeviceID %s, scopedUserID %s",
              profile.channel.UTF8String, profile.appName.UTF8String,
              profile.installID.UTF8String, profile.deviceID.UTF8String,
              profile.userID.UTF8String, profile.scopedDeviceID.UTF8String,
              profile.scopedUserID.UTF8String);
    
    NSDictionary *dictionary = profile.mirrorDictionary;
    
    if(dictionary == nil) {
        CLOAD_LOG("[Mirror] save failed, unable to convert profile to dictionary");
        return;
    }
    
    NSData *data = [dictionary hmd_jsonData];
    
    if(data == nil) {
        CLOAD_LOG("[Mirror] save failed, unable to convert dictionary to json "
                  "data, content %s", dictionary.description.UTF8String);
        return;
    }
    
    NSUInteger dataLength = data.length;
    
    if(dataLength > _mappedSize) {
        CLOAD_LOG("[Mirror] save failed, data size %u larger than mapped "
                  "size %u", (unsigned)dataLength, (unsigned)_mappedSize);
        DEBUG_RETURN_NONE;
    }
    
    const void * dataBytes = data.bytes;
    if(dataBytes == NULL) DEBUG_RETURN_NONE;
    
    DEBUG_ASSERT(_lastWrittenSize <= _mappedSize);
    
    if(_lastWrittenSize > _mappedSize) {
        memset(_mappedAddress, '\0', _mappedSize);
        _lastWrittenSize = 0;
    }
    
    if(_lastWrittenSize > dataLength) {
        size_t clearSize = _lastWrittenSize - dataLength;
        size_t clearIndex = dataLength;
        memset((uint8_t *)_mappedAddress + clearIndex, '\0', clearSize);
    }
    
    memcpy(_mappedAddress, dataBytes, dataLength);
    
    _lastWrittenSize = dataLength;
    
    CLOAD_LOG("[Mirror][Save] finish");
}

@end

#pragma mark - Low Level

bool HMDCrashLoadSync_starting(void) {
    bool starting = __atomic_load_n(&loadLaunchStarting, __ATOMIC_ACQUIRE);
    return starting;
}

void HMDCrashLoadSync_setStarting(bool starting) {
    DEBUG_ONCE;
    
    DEBUG_ASSERT(!loadLaunchStarting);
    DEBUG_ASSERT(!loadLaunchStarted);
    DEBUG_ASSERT(starting);
    
    __atomic_store_n(&loadLaunchStarting, starting, __ATOMIC_RELEASE);
}

bool HMDCrashLoadSync_started(void) {
    bool started = __atomic_load_n(&loadLaunchStarted, __ATOMIC_ACQUIRE);
    return started;
}


void HMDCrashLoadSync_setStarted(bool started) {
    DEBUG_ONCE;
    
    DEBUG_ASSERT(!loadLaunchStarted);
    DEBUG_ASSERT(started);
    
    __atomic_store_n(&loadLaunchStarted, started, __ATOMIC_RELEASE);
}

void HMDCrashLoadSync_trackerCallback(void) {
    [HMDCrashLoadSync.sync tackerCallback];
}

NSString * _Nullable HMDCrashLoadSync_currentDirectory(void) {
    return HMDCrashLoadSync.sync.currentDirectory;
}
