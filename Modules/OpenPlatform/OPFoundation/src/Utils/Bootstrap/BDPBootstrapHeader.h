//
//  BDPBootstrapHeader.h
//  Timor
//
//  Created by 傅翔 on 2019/6/13.
//

#import <Foundation/Foundation.h>

#define BOOT_PREFIX class BDPBootstrapKit;

#define BDP_BOOT_SEGMENT_NAME "__DATA"
#define BDP_LOAD_SECTION_NAME "TimorLoad"
#define BDP_LAUNCH_SECTION_NAME "TimorLaunch"
// 注释[dingruuoshan]：used表示release下也保留符号不优化，section表示放在image中哪个段
#define BDP_BOOT_SECTION_ATTRIBUTE(secname) __attribute__((used, section(BDP_BOOT_SEGMENT_NAME "," secname)))

// pre-main之前执行, 可充当+load方法
// 注释[dingruuoshan]：@class BDPBootstrapKit; const char *kABCClassbootload __attribute((used, section("__DATA"",""TimorLoad"))) = ""#ABCClass"";
//使用LKLoadable中提供的方法
//#define BDPBootstrapLoad(clsName, ...) BOOT_PREFIX \
//const char *k##clsName##bootload BDP_BOOT_SECTION_ATTRIBUTE(BDP_LOAD_SECTION_NAME) = ""#clsName""; \
//+ (void)bootstrapLoad { __VA_ARGS__ }

// bootstrap启动时才执行(在main阶段之后)
// 注释[dingruuoshan]：@class BDPBootstrapKit; const char *kABCClassbootload __attribute((used, section("__DATA"",""TimorLaunch"))) = ""#ABCClass"";
#define BDPBootstrapLaunch(clsName, ...) BOOT_PREFIX \
const char *k##clsName##bootlaunch BDP_BOOT_SECTION_ATTRIBUTE(BDP_LAUNCH_SECTION_NAME) = ""#clsName""; \
+ (void)bootstrapLaunch { __VA_ARGS__ }

/**
 注意事项:
 以上两个函数传入的clsName不可重复, 如果相同类或者多个类别, 可以在clsName后使用英文下划线分隔 _, 比如:
 BDPBootstrapLaunch(BDPClassA_name1, ...)
 BDPBootstrapLaunch(BDPClassA_name2, ...)
 BDPBootstrapLaunch(BDPClassA_name3, ...)
 // '_'下划线前边必须是类名, '_'后是自定义name, 整个字符串不可重复, 否则编译时duplicate symbol
 */
