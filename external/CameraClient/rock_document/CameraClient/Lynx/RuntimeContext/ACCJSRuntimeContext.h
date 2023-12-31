//
//  ACCJSRuntimeContext.h
//  
//
//  Created by wanghongyu on 2021/11/7.
//

#import <Foundation/Foundation.h>
#import <IESInject/IESServiceProvider.h>

/// 所谓ACCJSRuntimeContext
/// 就是给JS环境在运行时提供工具线的能力
@interface ACCJSRuntimeContext : NSObject

/// 在拍摄器创建时赋值
@property (nonatomic, weak, nullable) id <IESServiceProvider> recorderServiceProvider;

/// 在编辑器创建时赋值
@property (nonatomic, weak, nullable) id <IESServiceProvider> editorServiceProvider;

+ (instancetype)sharedInstance;

@end
