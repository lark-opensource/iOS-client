//
//  AWEMemoryGraphGenerator.m
//  Hello
//
//  Created by brent.shu on 2019/10/20.
//  Copyright © 2019 brent.shu. All rights reserved.
//

#import "AWEMemoryGraphGenerator.h"
#import "AWEMemoryGraphUtils.hpp"
#import "ThreadManager.hpp"
#import "AWEMemoryGraphBuilder.hpp"
#import "MemoryGraphVMHelper.hpp"
#import "AWEMemoryGraphErrorDefines.hpp"
#import "AWEMachOImageHelper.hpp"
#import "AWEMemoryGraphTimeChecker.hpp"

#import <mach/mach.h>
#import <mutex>
#import <unordered_map>
#import <stdio.h>

extern "C" __attribute__ ((weak)) size_t slardar_malloc_physical_memory_usage(void) {
    return 0;
}

bool mg_os_version_bigger_or_equal_to_15_4;

using namespace MemoryGraph;

static const size_t OTHER_MEMORY_USAGE              = 1024 * 1024 * 10;
static const size_t DEFAULT_MEMORY_LIMIT            = 1024 * 1024 * 100;
static const size_t BYTES_PER_MEGA                  = 1024 * 1024;

static BOOL inited                                  = NO;
static std::mutex *map_lock                         = nullptr;
static std::mutex *generate_lock                    = nullptr;
static NSMapTable<NSString *, NSLock *> *file_locks = nil;

@implementation AWEMemoryGraphGenerateRequest {
@public NSString        *_path;
@public NSNumber        *_maxMemoryUsage;
@public NSNumber        *_maxFileSize;
@public BOOL            _useNaiveVersion;
@public LockSafeChecker _checker;
@public BOOL            _doCppSymbolic;
@public NSMutableDictionary *_extraConfiguration;
@public NSUInteger      _timeOutDuration;
@public uint64_t        _memoryUsageBeforeSuspend;
@public ThreadNameParser _threadParser;
}

- (void)dealloc {
    [_path release];
    [_maxMemoryUsage release];
    [_maxFileSize release];
    [_checker release];
    [_jsonOutput release];
    [_extraConfiguration release];
    
    [super dealloc];
}

@end

@implementation AWEMemoryGraphGenerator

#pragma mark - Override

+ (void)initialize
{
    map_lock = new std::mutex;
    generate_lock = new std::mutex;
    file_locks = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory capacity:0];
    inited = YES;
    if(@available(iOS 15.4, *)) {
        mg_os_version_bigger_or_equal_to_15_4 = true;
    }else {
        mg_os_version_bigger_or_equal_to_15_4 = false;
    }
}

#pragma mark - Public

+ (void)generateMemoryGraphWithRequest:(AWEMemoryGraphGenerateRequest *)request error:(NSError **)err_output degrade:(AWEMemoryGraphDegradeType*)degrade_type {
    
    if (request.memoryUsageBeforeSuspend == 0) {
        request.memoryUsageBeforeSuspend =  MemoryGraph::physicalfootprint();
    }
    
    auto err_handler = [&](const Error &err) {
        if (err_output) {
            NSString *desc = [NSString stringWithUTF8String:err.description().c_str()];
            NSError *new_err =
            [NSError errorWithDomain:@"MemoryGraph"
                                code:err.type()
                            userInfo:@{NSLocalizedFailureReasonErrorKey: desc, NSLocalizedDescriptionKey: desc}];
            *err_output = new_err;
        }
    };
    
    BOOL is_arch_supported = NO;
    #ifdef __LP64__
        is_arch_supported = YES;
    #endif
    if (!is_arch_supported) {
        err_handler(Error(ErrorType::SystemOrDeviceNotSupported, "generator 32bit arch not supported"));
        return ;
    }
    
    BOOL is_system_supported = NO;
    if(@available(iOS 10.0, *)) {
        is_system_supported = YES;
    }
    if (!is_system_supported) {
        err_handler(Error(ErrorType::SystemOrDeviceNotSupported, "generator not supported os version"));
        return ;
    }
    
    if (!inited) {
        err_handler(Error(ErrorType::LogicalError, "generator lock are uninitiated"));
        return;
    }
    
    if (!request.path.UTF8String) {
        err_handler(Error(ErrorType::LogicalError, "generator required a utf8 path"));
        return;
    }
    
    auto file_lock = [self lockPath:request.path];
    generate_lock->lock();
    
    auto threadParser = [&] (thread_t port) -> ZONE_STRING {
        if (request->_threadParser) {
            NSString * threadName = request->_threadParser(port);
            return ZONE_STRING(threadName.UTF8String);
        }
        return "";
    };
    
    auto builder = new Builder(request.path.UTF8String, request.maxFileSize.unsignedLongLongValue * BYTES_PER_MEGA, threadParser);//@note:对m_xxx_writer进行初始化
    
    Cleaner c([&](){
        if (builder) delete builder;
        generate_lock->unlock();
        [file_lock unlock];
    });
    
    if (!builder->err().is_ok) {
        err_handler(builder->err());
        return ;
    }
    
    Error error;
    char m_ctx[50];
    memset(m_ctx, 0, 50);
    auto timestamp = [NSDate date].timeIntervalSince1970;
    {
        bool should_calculate_slardar_malloc_memory = [[request->_extraConfiguration objectForKey:@"shouldCalculateSlardarMallocMemory"] boolValue];
        
        auto ctx = ContextManager();//@note:is_degrade_version初始化为false
        BOOL do_leak_node_calibration = [[request->_extraConfiguration objectForKey:@"enableLeakNodeCalibration"] boolValue];
        ctx.init_none_suspend_required_info(do_leak_node_calibration);//@note:非挂起状态初始化上下文
        
        // do msg send before suspend
        size_t mem_limit =
        request.maxMemoryUsage.unsignedLongLongValue * BYTES_PER_MEGA > OTHER_MEMORY_USAGE ?
        request.maxMemoryUsage.unsignedLongLongValue * BYTES_PER_MEGA - OTHER_MEMORY_USAGE :
        DEFAULT_MEMORY_LIMIT - OTHER_MEMORY_USAGE;
        
        const char *file_uuid = [[request->_extraConfiguration objectForKey:@"fileUuid"] UTF8String]?:"";
        // suspend begin
        auto suspender = ThreadSuspender(file_uuid, [&]() {
            return request->_checker ? request->_checker() : true;
        });
        MemoryGraphTimeChecker.startCheckWithMaxTime(request->_timeOutDuration?:8);
        if (!suspender.is_suspended) {
            err_handler(Error(ErrorType::SuspendFailed, "generator suspend failed"));
            return ;
        }
        
        auto footprintAfterSuspend = MemoryGraph::physicalfootprint()+(should_calculate_slardar_malloc_memory?slardar_malloc_physical_memory_usage():0);
        if (footprintAfterSuspend < request->_memoryUsageBeforeSuspend && request->_memoryUsageBeforeSuspend - footprintAfterSuspend > 200 * BYTES_PER_MEGA) {
            err_handler(Error(ErrorType::MemoryDoubleCheckFail, "memory double check diff too much"));
            return;
        }
        ctx.init_suspend_required_info(request->_useNaiveVersion, mem_limit, request->_doCppSymbolic);//@note:线程挂起之后初始化上下文

        if (MemoryGraphTimeChecker.isTimeOut) {
            const char *sourceStr = MemoryGraphTimeChecker.errstr.c_str();
            memcpy((void*)m_ctx, sourceStr, strlen(sourceStr));
            error = Error(ErrorType::TimeOutError, m_ctx);
        } else {
            BOOL is_degrade = YES;
            if(ctx.is_degrade_version) {
                *degrade_type = DegradeTypeNodeOverSize;
            }
            else if(request->_useNaiveVersion) {
                *degrade_type = DegradeTypeMemoryIssue;
            }
            else {
                *degrade_type = DegradeTypeNone;
                is_degrade = NO;
            }
            
            builder->build(timestamp, footprintAfterSuspend, suspender, is_degrade);
            if (MemoryGraphTimeChecker.isTimeOut) {
                const char *sourceStr = MemoryGraphTimeChecker.errstr.c_str();
                memcpy((void*)m_ctx, sourceStr, strlen(sourceStr));
                error = Error(ErrorType::TimeOutError, m_ctx);
            } else {
                if (!builder->err().is_ok) {
                    memcpy((void*)m_ctx, builder->err().m_ctx, strlen(builder->err().m_ctx));
                    error = Error(builder->err().type(), m_ctx);
                }
            }
        }
    }
    if (!error.is_ok) {
        err_handler(error);
        delete builder;
        builder = nullptr;
        [[NSFileManager defaultManager] removeItemAtPath:request.path error:NULL];
    } else if (request.jsonOutput) {
        builder->result(request.jsonOutput);
    }
}

+ (BOOL)checkIfHasGraphUnderPath:(NSString *)path {
    if (!inited || !path.UTF8String) return NO;
    
    auto lock = [self lockPath:path];
    Cleaner c([&](){
        [lock unlock];
    });
    
    NSString *file = [self p_graphMetaPathWithBasePath:path];
    GraphMeta meta = {0};
    Reader reader(file.UTF8String);
    if (!reader.err().is_ok || !reader.readBytes(0, sizeof(GraphMeta), &meta) || !meta.is_valid) {
        return NO;
    }
    return YES;
}

#pragma mark - Private

+ (NSString *)p_graphMetaPathWithBasePath:(NSString *)path
{
    return path ? [path stringByAppendingPathComponent:META_PATH] : nil;
}

+ (NSString *)p_graphStrPathWithBasePath:(NSString *)path
{
    return path ? [path stringByAppendingPathComponent:STR_PATH] : nil;
}

+ (NSString *)p_graphMainPathWithBasePath:(NSString *)path
{
    return path ? [path stringByAppendingPathComponent:MAIN_PATH] : nil;
}

+ (NSLock *)lockPath:(NSString *)path
{
    if (!path) return nil;
    map_lock->lock();
    auto lock = [file_locks objectForKey:path];
    if (!lock) {
        lock = [[[NSLock alloc] init] autorelease];
        [file_locks setObject:lock forKey:path];
    }
    map_lock->unlock();
    [lock lock];
    return lock;
}

@end
