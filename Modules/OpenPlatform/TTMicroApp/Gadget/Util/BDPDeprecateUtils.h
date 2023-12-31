//
//  BDPDeprecateUtils.h
//  Timor
//
// OPSDK 灰度
//  Created by yinyuan on 2020/12/24.
//

#import <Foundation/Foundation.h>
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/BDPMonitorEvent.h>

// 必须成对出现，声明新容器废弃且不再运行的代码，如果被运行了，将会报错&上报。用于在 OPSDK 灰度期间标识废弃代码。OPSDK 预计在 21年2月左右完成GA，如果线上运行未报下方错误，则可以删除这些宏以及宏内的废弃代码。
#define OPSDK_DEPRECATE_CODE____________BEGIN____________DO_NOT_CALL_ANYMORE(uniqueID) {    \
    /** ⚠️如果你看到这个异常，说明发生了严重的逻辑问题，请务必立即联系(yinyuan.0)，谢谢！⚠️ **/   \
    BDPAssertWithLog(@"OPSDK_DEPRECATE_CODE RUNNING EXCEPTION. %@", uniqueID); \
    BDPMonitorWithCode(GDMonitorCode.deprecated_code_runnnig, uniqueID).flush();
    
// 必须成对出现
#define OPSDK_DEPRECATE_CODE____________END____________DO_NOT_CALL_ANYMORE   }
