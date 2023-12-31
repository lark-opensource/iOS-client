//
//  TTExpDiagnosisCallback.h
//  TTNetworkManager
//
//  Created by zhangzeming on 2021/6/14.
//  Copyright © 2021 bytedance. All rights reserved.
//

#ifndef TTExpDiagnosisCallback_h
#define TTExpDiagnosisCallback_h

// 在创建探测请求的时候需要传入此回调的实现。当请求结束时，结果会以JSON格式
// 通过这个回调返回。
typedef void (^DiagnosisCallback)(NSString* report);

#endif /* TTExpDiagnosisCallback_h */
