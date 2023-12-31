//
//  BDJTAudioException.m
//  Jato
//
//  Created by yuanzhangjing on 2021/12/2.
//

#import "BDJTAudioException.h"
#import <AudioToolbox/AudioToolbox.h>
#import "BDJTFishhook.h"
#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <pthread/introspection.h>
#include <mach/thread_act.h>
#include <mach/thread_status.h>
#include "Jato_Machine_Types.h"
#import <AVFoundation/AVFoundation.h>

static char main_bundle_path[PATH_MAX];
struct options {
    bool fix_all;
    bool fix_executable;
    char **frameworks;
    int framework_count;
    int fix_type;
};

#define FIX_TYPE_DISPOSE_DELAY 0
#define FIX_TYPE_USE_CACHE 1
#define Timer_Dur 10
#define Target_Thread_Name "AVAudioSession Notify Thread"

static struct {
    thread_t mach_th;
    pthread_t pth;
    bool need_deallocate;
} g_th;

static void clear_g_th(void) {
    thread_t t = g_th.mach_th;
    g_th.mach_th = THREAD_NULL;
    if (t != THREAD_NULL && g_th.need_deallocate) {
        __unused kern_return_t kr = mach_port_deallocate(current_task(), t);
        JATO_ASSERT(kr == KERN_SUCCESS);
        g_th.need_deallocate = false;
    }
    g_th.pth = NULL;
}

static thread_t get_target_thread_from_thread_list(void) {
    kern_return_t kr;
    const task_t this_task = mach_task_self();
    thread_act_array_t thread_list;
    mach_msg_type_number_t thread_count;
    kr = task_threads(this_task, &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return THREAD_NULL;
    }
    thread_t t = THREAD_NULL;
    for (mach_msg_type_number_t i = 0; i < thread_count; i++) {
        thread_t thread = thread_list[i];
        integer_t info_data[THREAD_EXTENDED_INFO_COUNT] = {0};
        thread_info_t info = info_data;
        mach_msg_type_number_t out_size = THREAD_EXTENDED_INFO_COUNT;
        kr = thread_info((thread_t)thread, THREAD_EXTENDED_INFO, info, &out_size);
        if(kr == KERN_SUCCESS) {
            thread_extended_info_t data = (thread_extended_info_t)info;
            if (strcmp(Target_Thread_Name, data->pth_name) == 0) {
                t = thread;
            } else {
                kr = mach_port_deallocate(this_task, thread);
                JATO_ASSERT(kr == KERN_SUCCESS)
            }
        }
    }
    
    kr = vm_deallocate(this_task, (vm_address_t)thread_list, sizeof(thread_t) * thread_count);
    JATO_ASSERT(kr == KERN_SUCCESS)
    
    return t;
}

static pthread_introspection_hook_t old_introspection;
static dispatch_queue_t g_thread_update_queue;
#define GET_QUEUE_OR_GLOBAL(queue) (queue?:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
#define GET_THREAD_UPDATE_QUEUE_OR_GLOBAL GET_QUEUE_OR_GLOBAL(g_thread_update_queue)

void my_pthread_introspection_hook(unsigned int event, pthread_t thread, void *addr, size_t size) {
    if (old_introspection) {
        old_introspection(event,thread,addr,size);
    }
    if (event == PTHREAD_INTROSPECTION_THREAD_START) {
        if (g_th.mach_th == THREAD_NULL) {
            dispatch_async(GET_THREAD_UPDATE_QUEUE_OR_GLOBAL, ^{
                if (g_th.mach_th == THREAD_NULL) {
                    char buf[128];
                    int ret = pthread_getname_np(thread, buf, sizeof(buf));
                    if (ret == 0 && strcmp(buf, Target_Thread_Name) == 0) {
                        thread_t t = pthread_mach_thread_np(thread);
                        g_th.mach_th = t;
                        g_th.pth = thread;
                        g_th.need_deallocate = false;
                        JATO_LOG("update target thread in introspection, %d",t);
                    }
                }
            });
        }
    } else if (event == PTHREAD_INTROSPECTION_THREAD_TERMINATE) {
        if (pthread_equal(thread, g_th.pth) != 0) {
            dispatch_async(GET_THREAD_UPDATE_QUEUE_OR_GLOBAL, ^{
                clear_g_th();
                JATO_LOG("clear target thread in introspection");
            });
        }
    }
}

static struct options _options;

@interface BDJTAudioException()
@property (nonatomic,strong) NSMutableDictionary *audioInstanceCache;
@property (nonatomic,strong) NSMutableArray *audioInstancePool;
@property (nonatomic,strong) NSLock *lock;
@property (nonatomic,strong) NSTimer *timer;
@property (nonatomic,strong) dispatch_queue_t queue;
@end

@implementation BDJTAudioException

+ (instancetype)sharedInstance {
    static BDJTAudioException *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[BDJTAudioException alloc] init];
    });
    return instance;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    if (self = [super init]) {
        self.audioInstanceCache = [NSMutableDictionary dictionary];
        self.audioInstancePool = [NSMutableArray array];
        self.lock = [[NSLock alloc] init];
        self.queue = dispatch_queue_create("jato.audio.component.dispose", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)handleInterruption:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    __unused NSNumber *type = [info objectForKey:AVAudioSessionInterruptionTypeKey];
    JATO_LOG("Audio Interruption %s",type.intValue == AVAudioSessionInterruptionTypeBegan?"Began":"End");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), self.queue, ^{
        [self flushIfNeed];
    });
}

#pragma mark - delay

- (void)startTimer {
    JATO_LOG("start timer");
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.timer) {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:Timer_Dur target:self selector:@selector(flushIfNeed) userInfo:nil repeats:YES];
        }
    });
}

- (void)stopTimer {
    JATO_LOG("stop timer");
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.timer) {
            [self.timer invalidate];
            self.timer = nil;
        }
    });
}

- (void)append:(AudioComponentInstance)instance {
    [self.lock lock];
    [self.audioInstancePool addObject:@((uintptr_t)instance)];
    JATO_LOG("append, count:%d instance:%p",(int)self.audioInstancePool.count, instance);
    [self.lock unlock];
}

- (void)flushAll {
    [self.lock lock];
    NSArray *instances = [self.audioInstancePool copy];
    [self.audioInstancePool removeAllObjects];
    [self.lock unlock];
    [instances enumerateObjectsUsingBlock:^(NSNumber *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        AudioComponentInstance instance = (AudioComponentInstance)[obj pointerValue];
        ori_AudioComponentInstanceDispose(instance);
    }];
    JATO_LOG("flush all, count:%d",(int)instances.count);
}

- (void)flushIfNeed {
    dispatch_async(self.queue, ^{
        BOOL ret = NO;
        thread_t t = g_th.mach_th;
        if (t == THREAD_NULL) {
            t = get_target_thread_from_thread_list();
            JATO_LOG("get target thread from thread list, thread = %d",t);
            dispatch_sync(GET_THREAD_UPDATE_QUEUE_OR_GLOBAL, ^{
                clear_g_th();
                g_th.mach_th = t;
                g_th.need_deallocate = true;
                g_th.pth = pthread_from_mach_thread_np(t);
            });
        }
        
        if (t != THREAD_NULL) {
            JATO_START(suspend)
            kern_return_t kr;
            bool top_frame_is_valid;

            mach_msg_type_number_t stateCountBuff = JATO_THREAD_STATE_COUNT;
            jato_thread_state_t state;
            thread_state_t s = (thread_state_t)&state.__ss;
            kr = thread_get_state(t, JATO_THREAD_STATE, s, &stateCountBuff);
            
            if (kr == KERN_SUCCESS) {
                jato_thread_state_t *state_ptr = &state;
                uintptr_t lr = JATO_GET_LR(state_ptr);
                uintptr_t mach_msg_ptr = (uintptr_t)&mach_msg;
                top_frame_is_valid = (lr >= mach_msg_ptr && lr <= (mach_msg_ptr + 256));
#if TARGET_OS_SIMULATOR
                top_frame_is_valid = true;
#endif
                JATO_LOG("target thread is %s",top_frame_is_valid?"available":"busy");
            } else {
                top_frame_is_valid = false;
                JATO_ASSERT(false && "thread_get_state failed");
            }
            
            if (top_frame_is_valid) {
                kr = thread_suspend(t);
                JATO_ASSERT(kr == KERN_SUCCESS && "thread_suspend failed");
                s = (thread_state_t)&state.__ss;
                kr = thread_get_state(t, JATO_THREAD_STATE, s, &stateCountBuff);
                if (kr == KERN_SUCCESS) {
                    jato_thread_state_t *state_ptr = &state;
                    uintptr_t pc = JATO_GET_PC(state_ptr);
                    uintptr_t lr = JATO_GET_LR(state_ptr);
                    uintptr_t mach_msg_ptr = (uintptr_t)&mach_msg;
                    
                    top_frame_is_valid = (lr >= mach_msg_ptr && lr <= (mach_msg_ptr + 256));
#if TARGET_OS_SIMULATOR
                    top_frame_is_valid = true;
#endif
                    JATO_LOG("double check, target thread is %s",top_frame_is_valid?"available":"busy");
                    if (top_frame_is_valid) {
                        uintptr_t fp = JATO_GET_FP(state_ptr);
                        bool should_flush = true;
                        while (JATO_IS_VALID_PTR(fp)) {
                            uintptr_t dest[2];
                            vm_size_t len = (vm_size_t)sizeof(dest);
                            /* Read the registers off the stack via the frame pointer */
                            kr = vm_read_overwrite(mach_task_self(), (vm_address_t)fp, len, (vm_address_t)dest, &len);
                            if (kr == KERN_SUCCESS) {
                                fp = JATO_POINTER_STRIP(dest[0]);
                                pc = JATO_POINTER_STRIP(dest[1]);
                                Dl_info info;
                                if (dladdr((const void *)pc, &info) != 0) {
                                    if (info.dli_fname && suffix(info.dli_fname, "libEmbeddedSystemAUs.dylib")) {
                                        should_flush = false;
                                        JATO_LOG("target thread has pc in libEmbeddedSystemAUs.dylib");
                                        break;
                                    }
                                }
                            } else {
                                break;
                            }
                        }
                        if (should_flush) {
                            JATO_LOG("target thread is available, flush all instances");
                            [self flushAll];
                            ret = YES;
                        }
                    }

                } else {
                    JATO_ASSERT(false && "thread_get_state failed");
                }
                kr = thread_resume(t);
                JATO_ASSERT(kr == KERN_SUCCESS && "thread_resume failed");
            }
            
            JATO_END_AND_LOG(suspend)
        } else {
            JATO_LOG("target thread is NULL, flush all instances");
            [self flushAll];
            ret = YES;
        }
        if (!ret) {
            [self startTimer];
        } else {
            [self stopTimer];
        }
    });
}

#pragma mark - cache

- (AudioComponentInstance)popCache:(NSString *)key {
    AudioComponentInstance instance = NULL;
    [self.lock lock];
    NSMutableArray *arr = [self.audioInstanceCache objectForKey:key];
    if (arr != nil) {
        NSNumber *ptr = [arr lastObject];
        [arr removeLastObject];
        if (ptr) {
            instance = (AudioComponentInstance)[ptr pointerValue];
        }
    }
    JATO_LOG("pop cahce, count:%d instance:%p",(int)arr.count,instance);
    [self.lock unlock];
    return instance;
}

- (void)pushCache:(AudioComponentInstance)instance forKey:(NSString *)key {
    [self.lock lock];
    NSMutableArray *arr = [self.audioInstanceCache objectForKey:key];
    if (arr == nil) {
        arr = [NSMutableArray array];
        [self.audioInstanceCache setObject:arr forKey:key];
    }
    [arr addObject:@((uintptr_t)instance)];
    JATO_LOG("push cahce, count:%d instance:%p",(int)arr.count,instance);
    [self.lock unlock];
}

static NSString * audio_componet_description_key(AudioComponentDescription desc) {
    NSString *key = [NSString stringWithFormat:@"%u-%u-%u-%u-%u",(unsigned int)desc.componentType,(unsigned int)desc.componentSubType,(unsigned int)desc.componentManufacturer,(unsigned int)desc.componentFlags,(unsigned int)desc.componentFlagsMask];
    return key;
}

#pragma mark - image hook

#define JATO(x) __JATO_##x
#define ORI(func) ori_##func
#define REBINDING(func) \
    {#func, JATO(func), (void *)&ORI(func)}

#define HOOK(ret_type,func,...) \
static ret_type (*ORI(func))(__VA_ARGS__);\
static ret_type (JATO(func))(__VA_ARGS__)

HOOK(OSStatus,AudioComponentInstanceNew,AudioComponent inComponent,AudioComponentInstance __nullable * __nonnull outInstance) {
    AudioComponentDescription desc;
    OSStatus s;
    s = AudioComponentGetDescription(inComponent, &desc);
    if (s != noErr) {
        JATO_ASSERT(0&&"audio component get desc error")
        return s;
    }
    NSString *key = audio_componet_description_key(desc);
    AudioComponentInstance instance = [[BDJTAudioException sharedInstance] popCache:key];
    if (instance == NULL) {
        s = ori_AudioComponentInstanceNew(inComponent,&instance);
        JATO_LOG("call ori_AudioComponentInstanceNew, instance:%p",instance);
        if (s != noErr) {
            JATO_ASSERT(0&&"ori_AudioComponentInstanceNew error")
            return s;
        }
    }
    if (outInstance) {
        *outInstance = instance;
    }
    JATO_LOG("call AudioComponentInstanceNew, instance:%p",instance);
    return noErr;
}

HOOK(OSStatus,AudioComponentInstanceDispose,AudioComponentInstance inInstance) {
    JATO_LOG("call AudioComponentInstanceDispose, instance:%p",inInstance);
    if (_options.fix_type == FIX_TYPE_USE_CACHE) {
        OSStatus s;
        AudioComponentDescription desc;
        AudioComponent component = AudioComponentInstanceGetComponent(inInstance);
        s = AudioComponentGetDescription(component, &desc);
        if (s != noErr) {
            JATO_ASSERT(0&&"audio component get desc error")
            return s;
        }
        NSString *key = audio_componet_description_key(desc);
        [[BDJTAudioException sharedInstance] pushCache:inInstance forKey:key];
        JATO_LOG("cache instance, instance:%p",inInstance);
    } else {
        [[BDJTAudioException sharedInstance] dispose:inInstance];
        JATO_LOG("dispose delay, instance:%p",inInstance);
    }
    return noErr;
}

static bool prefix(const char *str, const char *prefix) {
    if (prefix == NULL || str == NULL) {
        return false;
    }
    return strncmp(prefix, str, strlen(prefix)) == 0;
}

static bool suffix(const char *str, const char *suffix) {
    if (suffix == NULL || str == NULL) {
        return false;
    }
    size_t lenstr = strlen(str);
    size_t lensuffix = strlen(suffix);
    if (lensuffix > lenstr)
        return false;
    return strncmp(str + lenstr - lensuffix, suffix, lensuffix) == 0;
}

static void image_add_callback(const struct mach_header *mh, intptr_t vmaddr_slide) {
    Dl_info info;
    
    /* Look up the image info */
    if (dladdr(mh, &info) == 0) {
        return;
    }
    
    if (mh->filetype != MH_EXECUTE) {
        if (!prefix(info.dli_fname, main_bundle_path)) {
            //system frameworks
            return;
        }
    }
    
    if (mh->filetype == MH_EXECUTE) {
        //executable
        if (_options.fix_all || _options.fix_executable) {
            goto end;
        }
        return;
    } else {
        //app frameworks
        if (_options.fix_all) {
            goto end;
        }
        if (_options.framework_count > 0) {
            for (int i = 0; i < _options.framework_count; i++) {
                char *name = _options.frameworks[i];
                if (suffix(info.dli_fname, name)) {
                    goto end;
                }
            }
        }
        return;
    }
    
end:;
    if (_options.fix_type == FIX_TYPE_USE_CACHE) {
        struct bdjt_rebinding r[] = {
            REBINDING(AudioComponentInstanceNew),
            REBINDING(AudioComponentInstanceDispose)
        };
        JATO_LOG("binding new and dispose, %s",info.dli_fname);
        bdjt_rebind_symbols_image((void *)mh, vmaddr_slide, r, sizeof(r)/sizeof(struct bdjt_rebinding));
    } else {
        struct bdjt_rebinding r[] = {
            REBINDING(AudioComponentInstanceDispose)
        };
        JATO_LOG("binding dispose, %s",info.dli_fname);
        bdjt_rebind_symbols_image((void *)mh, vmaddr_slide, r, sizeof(r)/sizeof(struct bdjt_rebinding));
    }
}

- (void)dispose:(AudioComponentInstance)instance {
    if (instance) {
        [self append:instance];
        [self flushIfNeed];
    }
}

+(void)fix:(BDJTAudioExceptionOptions *)options {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        snprintf(main_bundle_path, PATH_MAX, "%s", NSBundle.mainBundle.bundlePath.UTF8String);
        if (options) {
            _options.fix_all = options.fixAll?true:false;
            _options.fix_executable = options.fixExecutable?true:false;
            if (options.fixFrameworks.count) {
                _options.framework_count = (int)options.fixFrameworks.count;
                _options.frameworks = malloc(_options.framework_count * sizeof(char *));
                [options.fixFrameworks enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    _options.frameworks[(int)idx] = strdup(obj.UTF8String);
                }];
            }
            _options.fix_type = (int)options.fixType;
        } else {
            _options.fix_all = true;
            _options.fix_type = FIX_TYPE_DISPOSE_DELAY;
        }
        
        JATO_LOG("image hook, fix_all:%d fix_executable:%d framework_count:%d fix_type:%d",_options.fix_all, _options.fix_executable, _options.framework_count, _options.fix_type);
        
        if (_options.fix_type == FIX_TYPE_DISPOSE_DELAY) {
            g_thread_update_queue = dispatch_queue_create("jato.audio.thread.update", DISPATCH_QUEUE_SERIAL);
            old_introspection = pthread_introspection_hook_install(my_pthread_introspection_hook);

            JATO_LOG("pthread_introspection_hook_install, old_introspection:%p",old_introspection);
            
            [[NSNotificationCenter defaultCenter] addObserver:[BDJTAudioException sharedInstance]
                                                     selector:@selector(handleInterruption:)
                                                         name:AVAudioSessionInterruptionNotification object:nil];
            
            JATO_LOG("add observer for audio interruption");
        }

        _dyld_register_func_for_add_image(image_add_callback);
    });
}

@end
