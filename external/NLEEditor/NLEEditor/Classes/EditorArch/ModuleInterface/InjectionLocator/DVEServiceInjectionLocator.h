//
//  DVEServiceInjectionLocator.h
//  NLEEditor
//
//  Created by bytedance on 2021/9/10.
//

#import <Foundation/Foundation.h>

// 传入一个实现了 DVEGlobalExternalInjectProtocol 协议的类
FOUNDATION_EXTERN void DVEGlobalServiceContainerRegister(Class serviceContainerClass);
