//
//  ADFGError.h
//  Pods
//
//  Created by cuikeyi on 2021/2/7.
//

#ifndef ADFGError_h
#define ADFGError_h
#import <Foundation/Foundation.h>

typedef enum {
    ADFGErrorTriggerResultParams = -10001,  // triggerEventResult错误，triggerResult为空，打开页面失败
    ADFGErrorGlobalDialogDalay = -10002,    // 延时任务禁止配置成全局弹框
    ADFGErrorBusinessForbidden = -10003,    // 业务禁止弹出
    ADFGErrorTimeout = -10004,              // 弹框超时
    ADFGErrorNotInWindow = -10005,          // 弹框推出页面非展示态
    ADFGErrorGlobalConfigNull = -10006,     // 全局配置模型为空
    ADFGErrorEventNull = -10007,            // event事件为空
    ADFGErrorOpenURLNull = -10008,          // 打开web页面URL为空
    ADFGErrorTaskIDNull = -10009,           // 打开TaskID为空
} ADFGError;

#endif /* ADFGError_h */
