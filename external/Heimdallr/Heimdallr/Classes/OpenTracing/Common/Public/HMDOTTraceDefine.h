//
//  HMDOTTraceDefine.h
//  Heimdallr
//
//  Created by fengyadong on 2020/3/26.
//

#ifndef HMDOTTraceDefine_h
#define HMDOTTraceDefine_h

typedef NS_ENUM(NSUInteger, HMDOTTraceInsertMode) {
    HMDOTTraceInsertModeEverySpanStart = 0,//默认行为，记录致命错误，即span开始时写入，结束时更新，缺点是磁盘IO会比较密集
    HMDOTTraceInsertModeEverySpanFinish,//仅仅单个span结束时写入，当某个span意外中断的时候无法归因，有一定的磁盘IO
    HMDOTTraceInsertModeAllSpanBatch//整个trace完成时所有span批量写入，磁盘IO很轻量，但是一旦中间发生异常所有span都会丢失
};

#endif /* HMDOTTraceDefine_h */
