//
//  CJPayPrivateServiceHeader.h
//  CJPay-Example
//
//  Created by 王新华 on 2021/9/7.
//

#ifndef CJPayPrivateServiceHeader_h
#define CJPayPrivateServiceHeader_h

#import "CJPaySDKMacro.h"
#import "CJPayProtocolManager.h"

// 更新时间：2021-09-08 by wangxinhua
// Common: SDK内部通用能力的组件，一般情况下功能为必须具备的能力，用于组件解耦通过这种方式进行调用。
// Module: 支持对外暴露和直接引用的组件。宿主App有相关业务场景则可以根据需求使用相关Module的能力。外部宿主需要感知调用。
// Plugin: 支持可选引入的插件，功能非必须。对于某些接入宿主可以选择不引入。引入后自动安装插件能力。为内部SDK提供额外能力。外部宿主不需要感知。

#pragma - mark Common
#import "CJPayGurdService.h"
#import "CJPayMetaSecService.h"
#import "CJPayOfflineService.h"
#import "CJPayRouterService.h"
#import "CJPayThemeModeService.h"
#import "CJPayThemeStyleService.h"
#import "CJPayWebViewService.h"
#import "CJPayParamsCacheService.h"
#import "CJPayGeneralAbilityService.h"
#import "CJPaySecService.h"
#import "CJPayHybridService.h"

#endif /* CJPayPrivateServiceHeader_h */
