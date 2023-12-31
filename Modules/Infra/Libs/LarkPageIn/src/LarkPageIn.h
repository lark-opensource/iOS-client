//
//  LarkPageIn.h
//  Lark
//
//  Created by huanglx on 2022/12/8.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//
#import <Foundation/Foundation.h>
@interface LarkPageIn : NSObject

/*
 settings 更新后，及时设置下次预加载的策略
 @param-enable:是否开启
 @param-filePath:文件地址
 @param-strategy:加载策略
 */
+ (void)updateBySettings:(bool)enable andFilePath:(NSString *)geckoPath andStrategy:(NSUInteger)strategy;
@end


