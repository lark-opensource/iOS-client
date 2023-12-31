//
//  BDPowerLogURLSessionMonitor.m
//  Jato
//
//  Created by ByteDance on 2022/10/14.
//

#import "BDPowerLogURLSessionMonitor.h"
#import <KVOController/KVOController.h>
#import <Stinger/Stinger.h>
#import "BDPowerLogUtility.h"
#import "NSURLSessionTask+BDPowerLog.h"
#import "BDPowerLogNetEvent.h"
#import "BDPowerLogURLSessionDelegate.h"
#import <objc/runtime.h>
#define CHECK_MONITOR_ENABLE if(!self->_flags.enable)return;
#define CHECK_METRICS_ENABLE if(!self->_flags.enable_urlsession_metrics)return;
#define GET_MONITOR_ENABLE(a) (a->_flags.enable)
#define GET_METRICS_ENABLE(a) (a->_flags.enable_urlsession_metrics)
typedef void (^BDPLURLSessionDataCompletionHandler)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error);
typedef void (^BDPLURLSessionDownloadCompletionHandler)(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error);

@interface BDPowerLogURLSessionMonitor()
{
    NSMutableSet *_urlsessionClasses;
    NSRecursiveLock *_urlsessionClassLock;
    
    struct {
        int enable : 1;
        int enable_urlsession_metrics : 1;
    }_flags;
    BDPowerLogURLSessionDelegate *_urlsessionDelegate;
    
    NSRecursiveLock *_hookLock;
}
@end

@implementation BDPowerLogURLSessionMonitor

+ (BDPowerLogURLSessionMonitor *)sharedInstance {
    static dispatch_once_t onceToken;
    static BDPowerLogURLSessionMonitor *instance;
    dispatch_once(&onceToken, ^{
        instance = [[BDPowerLogURLSessionMonitor alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _urlsessionClasses = [NSMutableSet set];
        _urlsessionClassLock = [[NSRecursiveLock alloc] init];
        
        _urlsessionDelegate = [[BDPowerLogURLSessionDelegate alloc] init];
        
        _hookLock = [[NSRecursiveLock alloc] init];
    }
    return self;
}

#pragma mark - previously

- (void)_addURLSessionTask:(NSURLSessionTask *)task {
    CHECK_MONITOR_ENABLE
    
    if (GET_METRICS_ENABLE(self))return;
    
    if (!task) {
        return;
    }
    
    long long ts = bd_powerlog_current_ts();
    BDPowerLogNetEvent *event = [[BDPowerLogNetEvent alloc] init];
    event.startTime = ts;
    event.endTime = ts;
    event.sysTime = bd_powerlog_current_sys_ts();
    event.sendBytes = 0;
    event.recvBytes = 0;
#ifdef BD_POWERLOG_DEBUG
    event.info = task.originalRequest.URL.absoluteString;
#endif
    [self addNetEvent:event];
}

- (void)_hookTaskResume {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSError *error = nil;
        WEAK_SELF
        [NSURLSessionTask st_hookInstanceMethod:@selector(resume) withOptions:STOptionAfter usingBlock:^(id<StingerParams> params){
            STRONG_SELF
            if (strongSelf) {
                NSURLSessionTask *task = [params slf];
                if (task) {
                    [strongSelf _addURLSessionTask:task];
                }
            }
        } error:&error];
    });
}

#pragma mark - detail metrics

#pragma mark - session

- (void)_hookURLSessionSharedSession:(Class)cls {
    WEAK_SELF
    SEL sel = @selector(sharedSession);
    IMP originIMP = bd_pl_get_imp_for_class_sel(cls, sel);
    bd_pl_set_block_for_class_sel(cls, sel, ^(id obj){
        NSURLSession *sharedSession = ((NSURLSession *(*)(id, SEL))originIMP)(obj, sel);
        STRONG_SELF
        if (strongSelf) {
            if ([sharedSession isProxy]) {
                NSCAssert(NO, @"URLSession %@ is Proxy",sharedSession);
            } else {
                [strongSelf _performURLSessionHook:[sharedSession class]];
            }
        }
        return sharedSession;
    });
}

- (void)_hookURLSessionSharedSessionWithConfiguration:(Class)cls {
    WEAK_SELF
    SEL sel = @selector(sessionWithConfiguration:);
    IMP originIMP = bd_pl_get_imp_for_class_sel(cls, sel);
    bd_pl_set_block_for_class_sel(cls, sel, ^(id obj, NSURLSessionConfiguration *configuration){
        NSURLSession *sharedSession = ((NSURLSession *(*)(id, SEL, NSURLSessionConfiguration *))originIMP)(obj, sel, configuration);
        STRONG_SELF
        if (strongSelf) {
            if ([sharedSession isProxy]) {
                NSCAssert(NO, @"URLSession %@ is Proxy",sharedSession);
            } else {
                [strongSelf _performURLSessionHook:[sharedSession class]];
            }
        }
        return sharedSession;
    });
}

- (void)_performURLSessionDelegateHook:(id<NSURLSessionDelegate>)delegate {
    NSCAssert(delegate, @"delegate is NULL");
    if (!delegate) return;
    
    if ([delegate isProxy]) {
        NSCAssert(NO, @"delegate %@ is Proxy",delegate);
    } else {
        Class delegateClass = delegate.class;
        [_hookLock lock];
        if (![BDPLGetAssociation(delegateClass, @"bd_pl_hooked") boolValue]) {
            NSError *error = nil;
            SEL sel = @selector(URLSession:task:didCompleteWithError:);
            if([delegateClass instancesRespondToSelector:sel]) {
                IMP originIMP = bd_pl_get_imp_for_sel(delegateClass, sel);
                WEAK_SELF
                bd_pl_set_block_for_sel(delegateClass, sel, ^(id obj, NSURLSession *session, NSURLSessionTask *task, NSError *error){
                    STRONG_SELF
                    if (strongSelf) {
                        [strongSelf _taskEnd:task];
                    }
                    typedef NSURLSession *(*IMP_TYPE)(id, SEL, NSURLSession *, NSURLSessionTask *, NSError *);
                    ((IMP_TYPE)originIMP)(obj, sel, session, task, error);
                });
            } else {
                IMP targetIMP = bd_pl_get_imp_for_sel(BDPowerLogURLSessionDelegate.class, sel);
                Method method = class_getInstanceMethod(BDPowerLogURLSessionDelegate.class, sel);
                if (targetIMP && method) {
                    const char *typeCodings = method_getTypeEncoding(method);
                    if (typeCodings)
                        class_addMethod(delegateClass, sel, targetIMP, typeCodings);
                }
            }
            BDPLSetAssociation(delegateClass, @"bd_pl_hooked", @YES, OBJC_ASSOCIATION_RETAIN);
            BDPL_DEBUG_LOG_TAG(NET, @"hook finished %@",NSStringFromClass(delegateClass));
        }
        [_hookLock unlock];
    }
}

- (void)_hookURLSessionSharedSessionWithConfigurationDelegate:(Class)cls {
    WEAK_SELF
    SEL sel = @selector(sessionWithConfiguration:delegate:delegateQueue:);
    IMP originIMP = bd_pl_get_imp_for_class_sel(cls, sel);
    bd_pl_set_block_for_class_sel(cls, sel, ^(id obj, NSURLSessionConfiguration *configuration, id<NSURLSessionDelegate> delegate, NSOperationQueue *delegateQueue){
        typedef NSURLSession *(*IMP_TYPE)(id, SEL, NSURLSessionConfiguration *, id<NSURLSessionDelegate>, NSOperationQueue *);
        STRONG_SELF
        NSURLSession *sharedSession = nil;
        if (strongSelf && GET_MONITOR_ENABLE(strongSelf) && GET_METRICS_ENABLE(strongSelf)) {
            if (delegate) {
                if (strongSelf)
                    [strongSelf _performURLSessionDelegateHook:delegate];
            } else {
                if (strongSelf) {
                    delegate = strongSelf->_urlsessionDelegate;
                }
            }
            sharedSession = ((IMP_TYPE)originIMP)(obj, sel, configuration, delegate, delegateQueue);
            if (strongSelf) {
                if ([sharedSession isProxy]) {
                    NSCAssert(NO, @"URLSession %@ is Proxy",sharedSession);
                } else {
                    [strongSelf _performURLSessionHook:[sharedSession class]];
                }
            }
        } else {
            sharedSession = ((IMP_TYPE)originIMP)(obj, sel, configuration, delegate, delegateQueue);
        }
        return sharedSession;
    });
}

#pragma mark - data task

#define HOOK_DELEGATE_OF_SESSION(s) \
{\
if (GET_MONITOR_ENABLE(strongSelf) && GET_METRICS_ENABLE(strongSelf) && [obj isKindOfClass:NSURLSession.class]) {\
    id<NSURLSessionDelegate> delegate = [(NSURLSession *)obj delegate];\
    if (delegate)\
        [strongSelf _performURLSessionDelegateHook:delegate];\
}\
}

- (void)_hookDataTaskWithURL:(Class)cls {
    WEAK_SELF
    SEL sel = @selector(dataTaskWithURL:);
    IMP originIMP = bd_pl_get_imp_for_sel(cls, sel);
    bd_pl_set_block_for_sel(cls, sel, ^(id obj, NSURL *url){
        typedef NSURLSessionDataTask *(*IMP_TYPE)(id, SEL, NSURL *);
        NSURLSessionDataTask *task = ((IMP_TYPE)originIMP)(obj, sel, url);
        STRONG_SELF
        if (strongSelf) {
            HOOK_DELEGATE_OF_SESSION(obj)
            [strongSelf _taskInit:task];
        }
        return task;
    });
}

- (void)_hookDataTaskWithURLCompletionHandler:(Class)cls {
    WEAK_SELF
    SEL sel = @selector(dataTaskWithURL:completionHandler:);
    IMP originIMP = bd_pl_get_imp_for_sel(cls, sel);
    bd_pl_set_block_for_sel(cls, sel, ^(id obj, NSURL *url, BDPLURLSessionDataCompletionHandler completionHandler){
        typedef NSURLSessionDataTask *(*IMP_TYPE)(id, SEL, NSURL *, BDPLURLSessionDataCompletionHandler);
        STRONG_SELF
        if (strongSelf && GET_MONITOR_ENABLE(strongSelf) && GET_METRICS_ENABLE(strongSelf)) {
            BDPLURLSessionDataCompletionHandler wrapperHandler = nil;
            __block NSURLSessionDataTask *task = nil;
            if (completionHandler) {
                wrapperHandler = ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                    STRONG_SELF
                    if (strongSelf) {
                        [strongSelf _taskEnd:task];
                    }
                    completionHandler(data,response,error);
                };
            }
            task = ((IMP_TYPE)originIMP)(obj, sel, url, wrapperHandler);
            if (strongSelf) {
                [strongSelf _taskInit:task];
            }
            return task;
        } else {
            return ((IMP_TYPE)originIMP)(obj, sel, url, completionHandler);
        }
    });
}

- (void)_hookDataTaskWithRequest:(Class)cls {
    WEAK_SELF
    SEL sel = @selector(dataTaskWithRequest:);
    IMP originIMP = bd_pl_get_imp_for_sel(cls, sel);
    bd_pl_set_block_for_sel(cls, sel, ^(id obj, NSURLRequest *request){
        typedef NSURLSessionDataTask *(*IMP_TYPE)(id, SEL, NSURLRequest *);
        NSURLSessionDataTask *task = ((IMP_TYPE)originIMP)(obj, sel, request);
        STRONG_SELF
        if (strongSelf) {
            HOOK_DELEGATE_OF_SESSION(obj)
            [strongSelf _taskInit:task];
        }
        return task;
    });
}

- (void)_hookDataTaskWithRequestCompletionHandler:(Class)cls {
    WEAK_SELF
    SEL sel = @selector(dataTaskWithRequest:completionHandler:);
    IMP originIMP = bd_pl_get_imp_for_sel(cls, sel);
    bd_pl_set_block_for_sel(cls, sel, ^(id obj, NSURLRequest *request, BDPLURLSessionDataCompletionHandler completionHandler){
        typedef NSURLSessionDataTask *(*IMP_TYPE)(id, SEL, NSURLRequest *request, BDPLURLSessionDataCompletionHandler);
        STRONG_SELF
        if (strongSelf && GET_MONITOR_ENABLE(self) && GET_METRICS_ENABLE(self)) {
            BDPLURLSessionDataCompletionHandler wrapperHandler = nil;
            __block NSURLSessionDataTask *task = nil;
            if (completionHandler) {
                wrapperHandler = ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                    STRONG_SELF
                    if (strongSelf) {
                        [strongSelf _taskEnd:task];
                    }
                    completionHandler(data,response,error);
                };
            }
            task = ((IMP_TYPE)originIMP)(obj, sel, request, wrapperHandler);
            if (strongSelf) {
                [strongSelf _taskInit:task];
            }
            return task;
        } else {
            return ((IMP_TYPE)originIMP)(obj, sel, request, completionHandler);
        }
    });
}

#pragma mark - upload task

- (void)_hookUploadTaskWithRequestFromFile:(Class)cls {
    WEAK_SELF
    SEL sel = @selector(uploadTaskWithRequest:fromFile:);
    IMP originIMP = bd_pl_get_imp_for_sel(cls, sel);
    bd_pl_set_block_for_sel(cls, sel, ^(id obj, NSURLRequest *request, NSURL *fileURL){
        typedef NSURLSessionUploadTask *(*IMP_TYPE)(id, SEL,NSURLRequest *, NSURL *);
        NSURLSessionUploadTask *task = ((IMP_TYPE)originIMP)(obj, sel, request, fileURL);
        STRONG_SELF
        if (strongSelf) {
            HOOK_DELEGATE_OF_SESSION(obj)
            [strongSelf _taskInit:task];
        }
        return task;
    });
}

- (void)_hookUploadTaskWithRequestFromFileCompletionHandler:(Class)cls {
    WEAK_SELF
    SEL sel = @selector(uploadTaskWithRequest:fromFile:completionHandler:);
    IMP originIMP = bd_pl_get_imp_for_sel(cls, sel);
    bd_pl_set_block_for_sel(cls, sel, ^(id obj, NSURLRequest *request, NSURL *fileURL, BDPLURLSessionDataCompletionHandler completionHandler){
        typedef NSURLSessionUploadTask *(*IMP_TYPE)(id, SEL, NSURLRequest *, NSURL *, BDPLURLSessionDataCompletionHandler);
        STRONG_SELF
        if (strongSelf && GET_MONITOR_ENABLE(strongSelf) && GET_METRICS_ENABLE(strongSelf)) {
            BDPLURLSessionDataCompletionHandler wrapperHandler = nil;
            __block NSURLSessionUploadTask *task = nil;
            if (completionHandler) {
                wrapperHandler = ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                    STRONG_SELF
                    if (strongSelf) {
                        [strongSelf _taskEnd:task];
                    }
                    completionHandler(data,response,error);
                };
            }
            task = ((IMP_TYPE)originIMP)(obj, sel, request, fileURL, wrapperHandler);
            if (strongSelf) {
                [strongSelf _taskInit:task];
            }
            return task;
        } else {
            return ((IMP_TYPE)originIMP)(obj, sel, request, fileURL, completionHandler);
        }
    });
}

- (void)_hookUploadTaskWithRequestFromData:(Class)cls {
    WEAK_SELF
    SEL sel = @selector(uploadTaskWithRequest:fromData:);
    IMP originIMP = bd_pl_get_imp_for_sel(cls, sel);
    bd_pl_set_block_for_sel(cls, sel, ^(id obj, NSURLRequest *request, NSData *bodyData){
        typedef NSURLSessionUploadTask *(*IMP_TYPE)(id, SEL,NSURLRequest *, NSData *);
        NSURLSessionUploadTask *task = ((IMP_TYPE)originIMP)(obj, sel, request, bodyData);
        STRONG_SELF
        if (strongSelf) {
            HOOK_DELEGATE_OF_SESSION(obj)
            [strongSelf _taskInit:task];
        }
        return task;
    });
}

- (void)_hookUploadTaskWithRequestFromDataCompletionHandler:(Class)cls {
    WEAK_SELF
    SEL sel = @selector(uploadTaskWithRequest:fromData:completionHandler:);
    IMP originIMP = bd_pl_get_imp_for_sel(cls, sel);
    bd_pl_set_block_for_sel(cls, sel, ^(id obj, NSURLRequest *request, NSData *bodyData, BDPLURLSessionDataCompletionHandler completionHandler){
        typedef NSURLSessionUploadTask *(*IMP_TYPE)(id, SEL, NSURLRequest *, NSData *, BDPLURLSessionDataCompletionHandler);
        STRONG_SELF
        if (strongSelf && GET_MONITOR_ENABLE(strongSelf) && GET_METRICS_ENABLE(strongSelf)) {
            BDPLURLSessionDataCompletionHandler wrapperHandler = nil;
            __block NSURLSessionUploadTask *task = nil;
            if (completionHandler) {
                wrapperHandler = ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                    STRONG_SELF
                    if (strongSelf) {
                        [strongSelf _taskEnd:task];
                    }
                    completionHandler(data,response,error);
                };
            }
            task = ((IMP_TYPE)originIMP)(obj, sel, request, bodyData, wrapperHandler);
            STRONG_SELF
            if (strongSelf) {
                [strongSelf _taskInit:task];
            }
            return task;
        } else {
            return ((IMP_TYPE)originIMP)(obj, sel, request, bodyData, completionHandler);
        }
    });
}

- (void)_hookUploadTaskWithStreamedRequest:(Class)cls {
    WEAK_SELF
    SEL sel = @selector(uploadTaskWithStreamedRequest:);
    IMP originIMP = bd_pl_get_imp_for_sel(cls, sel);
    bd_pl_set_block_for_sel(cls, sel, ^(id obj, NSURLRequest *request){
        typedef NSURLSessionUploadTask *(*IMP_TYPE)(id, SEL,NSURLRequest *);
        NSURLSessionUploadTask *task = ((IMP_TYPE)originIMP)(obj, sel, request);
        STRONG_SELF
        if (strongSelf) {
            HOOK_DELEGATE_OF_SESSION(obj)
            [strongSelf _taskInit:task];
        }
        return task;
    });
}

#pragma mark - download task

- (void)_hookDownloadTaskWithURL:(Class)cls {
    WEAK_SELF
    SEL sel = @selector(downloadTaskWithURL:);
    IMP originIMP = bd_pl_get_imp_for_sel(cls, sel);
    bd_pl_set_block_for_sel(cls, sel, ^(id obj, NSURL *url){
        typedef NSURLSessionUploadTask *(*IMP_TYPE)(id, SEL, NSURL *);
        NSURLSessionUploadTask *task = ((IMP_TYPE)originIMP)(obj, sel, url);
        STRONG_SELF
        if (strongSelf) {
            HOOK_DELEGATE_OF_SESSION(obj)
            [strongSelf _taskInit:task];
        }
        return task;
    });
}

- (void)_hookDownloadTaskWithURLCompletionHandler:(Class)cls {
    WEAK_SELF
    SEL sel = @selector(downloadTaskWithURL:completionHandler:);
    IMP originIMP = bd_pl_get_imp_for_sel(cls, sel);
    bd_pl_set_block_for_sel(cls, sel, ^(id obj, NSURL *url, BDPLURLSessionDownloadCompletionHandler completionHandler){
        typedef NSURLSessionUploadTask *(*IMP_TYPE)(id, SEL, NSURL *, BDPLURLSessionDownloadCompletionHandler);
        STRONG_SELF
        if (strongSelf && GET_MONITOR_ENABLE(strongSelf) && GET_METRICS_ENABLE(strongSelf)) {
            BDPLURLSessionDownloadCompletionHandler wrapperHandler = nil;
            __block NSURLSessionUploadTask *task = nil;
            if (completionHandler) {
                wrapperHandler = ^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                    STRONG_SELF
                    if (strongSelf) {
                        [strongSelf _taskEnd:task];
                    }
                    completionHandler(location,response,error);
                };
            }
            task = ((IMP_TYPE)originIMP)(obj, sel, url, wrapperHandler);
            STRONG_SELF
            if (strongSelf) {
                [strongSelf _taskInit:task];
            }
            return task;
        } else {
            return ((IMP_TYPE)originIMP)(obj, sel, url, completionHandler);
        }
    });
}

- (void)_hookDownloadTaskWithRequest:(Class)cls {
    WEAK_SELF
    SEL sel = @selector(downloadTaskWithRequest:);
    IMP originIMP = bd_pl_get_imp_for_sel(cls, sel);
    bd_pl_set_block_for_sel(cls, sel, ^(id obj, NSURLRequest *request){
        typedef NSURLSessionUploadTask *(*IMP_TYPE)(id, SEL, NSURLRequest *);
        NSURLSessionUploadTask *task = ((IMP_TYPE)originIMP)(obj, sel, request);
        STRONG_SELF
        if (strongSelf) {
            HOOK_DELEGATE_OF_SESSION(obj)
            [strongSelf _taskInit:task];
        }
        return task;
    });
}

- (void)_hookDownloadTaskWithRequestCompletionHandler:(Class)cls {
    WEAK_SELF
    SEL sel = @selector(downloadTaskWithRequest:completionHandler:);
    IMP originIMP = bd_pl_get_imp_for_sel(cls, sel);
    bd_pl_set_block_for_sel(cls, sel, ^(id obj, NSURLRequest *request, BDPLURLSessionDownloadCompletionHandler completionHandler){
        typedef NSURLSessionUploadTask *(*IMP_TYPE)(id, SEL, NSURLRequest *, BDPLURLSessionDownloadCompletionHandler);
        STRONG_SELF
        if (strongSelf && GET_MONITOR_ENABLE(strongSelf) && GET_METRICS_ENABLE(strongSelf)) {
            BDPLURLSessionDownloadCompletionHandler wrapperHandler = nil;
            __block NSURLSessionUploadTask *task = nil;
            if (completionHandler) {
                wrapperHandler = ^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                    STRONG_SELF
                    if (strongSelf) {
                        [strongSelf _taskEnd:task];
                    }
                    completionHandler(location,response,error);
                };
            }
            task = ((IMP_TYPE)originIMP)(obj, sel, request, wrapperHandler);
            STRONG_SELF
            if (strongSelf) {
                [strongSelf _taskInit:task];
            }
            return task;
        } else {
            return ((IMP_TYPE)originIMP)(obj, sel, request, completionHandler);
        }
    });
}

#pragma mark - hook

- (void)_performURLSessionHook:(Class)cls {
    CHECK_METRICS_ENABLE
    if (![cls isSubclassOfClass:NSURLSession.class]) {
        return;
    }
    BOOL hasClass = NO;
    [_urlsessionClassLock lock];
    hasClass = [_urlsessionClasses containsObject:cls];
    if (!hasClass) {
        [_urlsessionClasses addObject:cls];
    }
    [_urlsessionClassLock unlock];
    if (hasClass) return;
    
    [_hookLock lock];
    
    [self _hookURLSessionSharedSession:cls];
    [self _hookURLSessionSharedSessionWithConfiguration:cls];
    [self _hookURLSessionSharedSessionWithConfigurationDelegate:cls];
    
    [self _hookDataTaskWithURL:cls]; //✅
    [self _hookDataTaskWithURLCompletionHandler:cls]; //✅
    [self _hookDataTaskWithRequest:cls]; //✅
    [self _hookDataTaskWithRequestCompletionHandler:cls]; //✅
    
    [self _hookUploadTaskWithRequestFromFile:cls]; //✅
    [self _hookUploadTaskWithRequestFromFileCompletionHandler:cls]; //✅
    [self _hookUploadTaskWithRequestFromData:cls]; //✅
    [self _hookUploadTaskWithRequestFromDataCompletionHandler:cls]; //✅
    [self _hookUploadTaskWithStreamedRequest:cls]; //✅
    
    [self _hookDownloadTaskWithURL:cls]; //✅
    [self _hookDownloadTaskWithURLCompletionHandler:cls]; //✅
    [self _hookDownloadTaskWithRequest:cls]; //✅
    [self _hookDownloadTaskWithRequestCompletionHandler:cls]; //✅
    
    [_hookLock unlock];

    BDPL_DEBUG_LOG_TAG(NET,@"hook finished %@",NSStringFromClass(cls));
}

- (void)_performURLSessionTaskHook {
    Class cls = NSURLSessionTask.class;
    SEL sel = @selector(resume);
    IMP originIMP = bd_pl_get_imp_for_sel(cls, sel);
    WEAK_SELF
    bd_pl_set_block_for_sel(cls, sel, ^(NSURLSessionTask *task){
        typedef void(*IMP_TYPE)(id, SEL);
        ((IMP_TYPE)originIMP)(task, sel);
        STRONG_SELF
        if (strongSelf) {
            [strongSelf _taskStart:task];
        }
    });
}

- (void)_hookForURLSession {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self _performURLSessionTaskHook];
        [self _performURLSessionHook:NSURLSession.class];
    });
}

- (void)_updateHook {
    CHECK_MONITOR_ENABLE
    if (_enableURLSessionMetrics) {
        BDPL_DEBUG_LOG_TAG(NET,@"enable urlsession metrics");
        _flags.enable_urlsession_metrics = true;
        [self _hookForURLSession];
    } else {
        BDPL_DEBUG_LOG_TAG(NET,@"disable urlsession metrics");
        _flags.enable_urlsession_metrics = false;
        [self _hookTaskResume];
    }
}

#pragma mark - event

- (void)_taskInit:(NSURLSessionTask *)task {
    CHECK_MONITOR_ENABLE
    CHECK_METRICS_ENABLE
    if (task.bd_pl_initTime == 0) {
        task.bd_pl_initTime = bd_powerlog_current_ts();
        BDPL_DEBUG_LOG_TAG(NET,@"task init %@ %@",task,task.originalRequest.URL);
    }
}

- (void)_taskStart:(NSURLSessionTask *)task {
    CHECK_MONITOR_ENABLE
    CHECK_METRICS_ENABLE
    if (task.bd_pl_startTime == 0) {
        task.bd_pl_startTime = bd_powerlog_current_ts();
        BDPL_DEBUG_LOG_TAG(NET,@"task start %@ %@",task,task.originalRequest.URL);
    }
}

- (void)_taskEnd:(NSURLSessionTask *)task {
    CHECK_MONITOR_ENABLE
    CHECK_METRICS_ENABLE
    if (task.bd_pl_endTime == 0) {
        task.bd_pl_endTime = bd_powerlog_current_ts();
        BDPL_DEBUG_LOG_TAG(NET,@"task end %@ %@",task,task.originalRequest.URL);
        [self _collectTask:task];
    }
}

- (void)_collectTask:(NSURLSessionTask *)task {
    BDPowerLogNetEvent *event = [[BDPowerLogNetEvent alloc] init];
    long long startTime = task.bd_pl_startTime;
    if (startTime == 0)
        startTime = task.bd_pl_initTime;
    if (startTime == 0)
        startTime = task.bd_pl_endTime;
    event.startTime = startTime;
    event.endTime = task.bd_pl_endTime;
    event.sysTime = bd_powerlog_current_sys_ts();
    event.sendBytes = task.countOfBytesSent;
    event.recvBytes = task.countOfBytesReceived;
#ifdef BD_POWERLOG_DEBUG
    event.info = task.originalRequest.URL.absoluteString;
#endif
    [self addNetEvent:event];
}

- (void)addNetEvent:(BDPowerLogNetEvent *)netEvent {
    if ([self.delegate respondsToSelector:@selector(netEventGenerate:)]) {
        [self.delegate netEventGenerate:netEvent];
    }
}

#pragma mark - public

- (void)setEnableURLSessionMetrics:(BOOL)enableURLSessionMetrics {
    if (_enableURLSessionMetrics != enableURLSessionMetrics) {
        _enableURLSessionMetrics = enableURLSessionMetrics;
        [self _updateHook];
    }
}

- (void)start {
    BDPL_DEBUG_LOG_TAG(NET,@"start urlsession monitor");
    _flags.enable = true;
    [self _updateHook];
}

- (void)stop {
    BDPL_DEBUG_LOG_TAG(NET,@"stop urlsession monitor");
    _flags.enable = false;
}

@end
