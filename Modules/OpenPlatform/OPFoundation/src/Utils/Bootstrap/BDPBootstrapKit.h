//
//  BDPBootstrapKit.h
//  Timor
//
//  Created by 傅翔 on 2019/6/12.
//
//  注释[dingruuoshan]：mini版GAIA,用于消除原有+load中的操作防止APP启动过慢，其中BDPBootstrapLoad类型还是在main之前执行，与+load类似，BDPBootstrapLaunch类型被延迟到[BDPBootstrapKit lauch]这个时机点。
//  注释[dingruuoshan]：原理是把修饰过的类信息放到"__DATA,TimorLoad"、"__DATA,TimorLaunch"这两个段中，在image加载的时候利用遍历这两个段中的类名并逐个判断是否有实现bootstrapLoad和bootstrapLaunch方法，如果有则加到load和launch对应的列表中，然后分别在load和launch的时机调用。

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 启动事项管理Kit
 */
@interface BDPBootstrapKit : NSObject

/** 触发launch的启动事项 */
+ (void)launch;

@end

NS_ASSUME_NONNULL_END
