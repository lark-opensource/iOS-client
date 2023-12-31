//
//  BDPDebugMacro.h
//  Timor
//
//  Created by 傅翔 on 2019/11/19.
//

/**
 本文件的宏主要与DEBUG调试相关, 非DEBUG且通用的宏请往`BDPMacroUtils.h`文件中补充
 */
#ifndef BDPDebugMacro_h
#define BDPDebugMacro_h

__unused static void BDPCleanUpBlk(__strong void(^*block)(void)) {
    (*block)();
}
#define BDP_ON_EXIT __strong void(^block)(void) __attribute__((cleanup(BDPCleanUpBlk), unused)) = ^

// 小程序线程名前缀
#define BDP_JSTHREADNAME_PREFIX @"com.bytedance.bdpjsruntime_mpid_"

#endif
