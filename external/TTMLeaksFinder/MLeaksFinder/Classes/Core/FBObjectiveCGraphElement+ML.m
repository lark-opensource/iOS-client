//
//  FBObjectiveCGraphElement+ML.m
//  MLeaksFinder
//
//  Created by xushuangqing on 2019/8/12.
//

#import "FBObjectiveCGraphElement+ML.h"

@implementation FBObjectiveCGraphElement (ML)

// 用Category的方式，改写了FBObjectiveCGraphElement的classNameOrNull方法
// 目的是处理isa-swizzling产生的奇特类名
- (NSString *)classNameOrNull
{
    NSString *className = NSStringFromClass([self objectClass]);
    if ([className hasSuffix:@"_Hmd_Prefix_"]) {
        className = [className substringToIndex:([className length] - [@"_Hmd_Prefix_" length])];
    }
    if ([className hasPrefix:@"NSKVONotifying_"]) {
        className = [className substringFromIndex:[@"NSKVONotifying_" length]];
    }
    if ([className hasSuffix:@"_hmd_subfix_"]) {
        className = [className substringToIndex:([className length] - [@"_hmd_subfix_" length])];
    }
    
    //笼统处理兼容下其他被_分割的class
    if([className containsString:@"_"]){
        NSArray *ary = [className componentsSeparatedByString:@"_"];
        for (int i = 0; i < [ary count]; i++) {
            if ([ary[i] length] >0) {
                className = ary[i];
                break;
            }
        }
    }
    
    if([className containsString:@"-"]){
        NSArray *ary = [className componentsSeparatedByString:@"-"];
        for (int i = 0; i < [ary count]; i++) {
            if ([ary[i] length] >0) {
                className = ary[i];
                break;
            }
        }
    }

    if (!className) {
        className = @"(null)";
    }
    return className;
}

@end
