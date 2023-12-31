//
//  HMDLogHelper.m
//  Heimdallr
//
//  Created by kilroy on 2020/12/6.
//
#include "pthread_extended.h"
#import "HMDLogHelper.h"
#import "HMDALogProtocol.h"
#import <BDAlogProtocol/BDAlogProtocol.h>
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_DOCUMENTATION
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <BDALog/BDAgileLog.h>
CLANG_DIAGNOSTIC_POP
#include <sys/types.h>
#include <sys/socket.h>

@interface HMDLogRedirector: NSObject

//only 2 value:STDERR_FILENO(NSLog)/STDOUT_FILENO(printf)
@property (nonatomic, assign) int originalStd;
@property (nonatomic, assign) int stdFd;
@property (nonatomic, assign) pthread_mutex_t log_mutex;
@property (nonatomic, copy) NSString *tag;
@property (atomic, strong) NSPipe* pipe;
@property (atomic, strong) NSFileHandle* readHandle;
@property (nonatomic, nullable, copy) HMDLogRedirectCallback callback;

- (instancetype)initWithOriginalStd:(int)std AndTag:(NSString*)tag NS_DESIGNATED_INITIALIZER;

- (void)redirectToAlog:(BOOL)enable withCallback:(HMDLogRedirectCallback)callback;

@end

@implementation HMDLogRedirector

- (instancetype)init {
    //invalid
    return [self initWithOriginalStd:-1 AndTag:nil];
}

- (instancetype)initWithOriginalStd:(int)std AndTag:(NSString*)tag {
    if (self = [super init]) {
        pthread_mutex_init(&_log_mutex, NULL);
        _originalStd = std;
        _stdFd = -1;
        _tag = tag;
    }
    return self;
}

- (void)redirectNotificationHandle:(NSNotification *)nf {
    __strong typeof(self) strongSelf = self;
    if (strongSelf) {
        NSData *data = [[nf userInfo] objectForKey:NSFileHandleNotificationDataItem];
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (strongSelf.callback) {
            strongSelf.callback(str);
        }
        //write contents to alog file
        [BDALogProtocol setALogWithFileName:@"unknown" funcName:@"unknown" tag:strongSelf.tag line:0 level:kLogLevelDebug format:str];
        
        NSFileHandle *originReadHandle = [nf object];
        if (!strongSelf.readHandle || strongSelf.readHandle != originReadHandle) {
            close([originReadHandle fileDescriptor]);
        }
        
        if (strongSelf.readHandle && strongSelf.pipe) {
            [strongSelf.readHandle readInBackgroundAndNotify];
        }
    }
}

- (void)redirectToAlog:(BOOL)enable withCallback:(HMDLogRedirectCallback)callback {
    alog_set_console_log(false);
    //asking for redirecting std
    if (enable && self.readHandle == nil) {
        pthread_mutex_lock(&_log_mutex);
        self.pipe = [NSPipe pipe];
        self.stdFd = dup(self.originalStd);
        //dup success
        if (self.stdFd != -1) {
            close(self.originalStd);
            //dup2 success
            if (dup2([[self.pipe fileHandleForWriting] fileDescriptor], self.originalStd) != -1) {
                self.readHandle = [self.pipe fileHandleForReading];
                self.callback = callback;
                //add notification
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(redirectNotificationHandle:)
                                                             name:NSFileHandleReadCompletionNotification
                                                           object:self.readHandle];
                [self.readHandle readInBackgroundAndNotify];
                pthread_mutex_unlock(&_log_mutex);
                HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Redirect %d to Alog Successfully", self.originalStd);
                return;
            }
        }
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"Failed to Redirect %d to Alog", self.originalStd);
        return;
    }
    //asking for disabling redirecting std
    if (!enable && self.readHandle != nil) {
        pthread_mutex_lock(&_log_mutex);
        //release pipe's fds
        close([[self.pipe fileHandleForWriting] fileDescriptor]);
        if (dup2(self.stdFd, self.originalStd) != -1) {
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:NSFileHandleReadCompletionNotification
                                                          object:self.readHandle];
            self.readHandle = nil;
            self.pipe = nil;
            self.callback = nil;
            //in case hold mulptible fds in single application lifetime
            close(self.stdFd);
            pthread_mutex_unlock(&_log_mutex);
            HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Recover Redirect %d to Alog Successfully", self.originalStd);
        } else {
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"Failed to Recover Redirect %d to Alog", self.originalStd);
        }
    }
}

@end

@interface HMDLogHelper()

@property (nonatomic,strong) HMDLogRedirector *nslogRedirector;
@property (nonatomic,strong) HMDLogRedirector *printfRedirector;
@property (nonatomic, strong) NSThread *thread;
@end

@implementation HMDLogHelper

+ (instancetype)sharedInstance {
    static HMDLogHelper* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDLogHelper alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _nslogRedirector = [[HMDLogRedirector alloc] initWithOriginalStd:STDERR_FILENO AndTag:@"NSLog"];
        _printfRedirector = [[HMDLogRedirector alloc] initWithOriginalStd:STDOUT_FILENO AndTag:@"printf"];
        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(startRunloop) object:nil];
        [_thread setName:@"com.heimdallr.alog.redirector"];
        [_thread start];
    }
    return self;
}

- (void)startRunloop {
    @autoreleasepool {
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSRunLoopCommonModes];
        [runLoop run];
    }
}

- (void)setRedirectNSLogToAlogEnable:(BOOL)enable {
    [self setRedirectNSLogToAlogEnable:enable withCallback:nil];
}

- (void)setRedirectPrintfToAlogEnable:(BOOL)enable {
    [self setRedirectPrintfToAlogEnable:enable withCallback:nil];
}

- (void)setRedirectNSLogToAlogEnable:(BOOL)enable withCallback:(HMDLogRedirectCallback)callback {
    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Begin to Redirect STDERR to Alog");
    NSMethodSignature *signature = [[self.nslogRedirector class] instanceMethodSignatureForSelector:@selector(redirectToAlog:withCallback:)];
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:signature];
    [inv setTarget:self.nslogRedirector];
    [inv setSelector:@selector(redirectToAlog:withCallback:)];
    [inv setArgument:&(enable) atIndex:2];
    [inv setArgument:&(callback) atIndex:3];
    [inv retainArguments];
    [inv performSelector:@selector(invoke) onThread:_thread withObject:nil waitUntilDone:NO];
}

- (void)setRedirectPrintfToAlogEnable:(BOOL)enable withCallback:(HMDLogRedirectCallback)callback {
    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"Begin to Redirect STDOUT to Alog");
    NSMethodSignature *signature = [[self.printfRedirector class] instanceMethodSignatureForSelector:@selector(redirectToAlog:withCallback:)];
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:signature];
    [inv setTarget:self.printfRedirector];
    [inv setSelector:@selector(redirectToAlog:withCallback:)];
    [inv setArgument:&(enable) atIndex:2];
    [inv setArgument:&(callback) atIndex:3];
    [inv retainArguments];
    [inv performSelector:@selector(invoke) onThread:_thread withObject:nil waitUntilDone:NO];
}

@end

