//
//  LarkSafeModeHook.m
//  LarkSafeMode
//
//  Created by luyz on 2023/1/29.
//

#import "LarkSafeModeHook.h"
#include <BDFishhook/BDFishhook.h>

@implementation LarkSafeModeHook

+ (void)exitBinding {
    struct bd_rebinding exit_binding;
    exit_binding.name = "exit";
    exit_binding.replacement = lark_exit;
    exit_binding.replaced = (void *)&sys_exit;
    
    struct bd_rebinding rebs[1] = {exit_binding};
    bd_rebind_symbols(rebs, 1);
}

static void (*sys_exit)(int);

void lark_exit(int i) {
    // lint:disable lark_storage_check - 用户/业务无关数据，记录 crash，不进行统一存储管控检查
    [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"user_quite"];
    [[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)0 forKey:@"lk_safe_mode_crash_count"];
    // lint:enable lark_storage_check
    sys_exit(i);
}

@end
