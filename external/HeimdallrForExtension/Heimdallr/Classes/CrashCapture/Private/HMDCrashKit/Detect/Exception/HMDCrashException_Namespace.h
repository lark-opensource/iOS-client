//
//  HMDCrashException_Namespace.h
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/12.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#ifndef HMDCrashException_Namespace_h
#define HMDCrashException_Namespace_h

#define create_exception        HMDCrashExceptionLogCreate
#define open_exception          HMDCrashExceptionLogOpen
#define basic_info              HMDCrashExceptionLogBasicInfo
#define begin_threads           HMDCrashExceptionLogBeginThreadsCollection
#define begin_thread            HMDCrashExceptionLogBeginOneThread
#define begin_register          HMDCrashExceptionLogBeginRegister
#define register_info           HMDCrashExceptionLogRegisterInfo
#define end_register            HMDCrashExceptionLogEndRegister
#define begin_backtrace         HMDCrashExceptionLogBeginBacktrace
#define backtrace_address       HMDCrashExceptionLogBacktraceAddress
#define backtrace_batch         HMDCrashExceptionLogBacktraceBatch
#define end_backtrace           HMDCrashExceptionLogEndBacktrace
#define end_thread              HMDCrashExceptionLogEndOneThread
#define end_threads             HMDCrashExceptionLogEndThreadsCollection
#define begin_dispatch_name     HMDCrashExceptionLogBeginDispatchName
#define write_dispatch_name     HMDCrashExceptionLogWriteDispatchName
#define end_dispatch_name       HMDCrashExceptionLogEndDispatchName

#define begin_runtime_info      HMDCrashExceptionLogBeginRuntimeInfo
#define write_runtime_sel       HMDCrashExceptionLogWriteRuntimeSelector
#define begin_crash_infos       HMDCrashExceptionLogBeginCrashInfos
#define write_crash_info        HMDCrashExceptionLogWriteCrashInfo
#define end_crash_infos         HMDCrashExceptionLogEndCrashInfos
#define end_runtime_info        HMDCrashExceptionLogEndRuntimeInfo

#define begin_pthread_name      HMDCrashExceptionLogBeginPthreadName
#define write_pthread_name      HMDCrashExceptionLogWritePthreadName
#define end_pthread_name        HMDCrashExceptionLogEndPthreadName
#define process_stats           HMDCrashExceptionLogProcessStats
#define write_storage           HMDCrashExceptionLogWriteStorage
#define close_exception         HMDCrashExceptionclose_exception

#endif /* HMDCrashException_Namespace_h */
