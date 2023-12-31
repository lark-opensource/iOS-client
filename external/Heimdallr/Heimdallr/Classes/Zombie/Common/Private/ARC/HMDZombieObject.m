//
//  HMDZombieObject.m
//  ZombieDemo
//
//  Created by Liuchengqing on 2020/3/2.
//  Copyright © 2020 Liuchengqing. All rights reserved.
//

#import <objc/runtime.h>

#import "HMDMacro.h"
#import "HMDCrashKit.h"
#import "HMDZombieObject.h"
#import "HMDZombieMonitor+private.h"
#import "NSArray+HMDJSON.h"
#import "HMDInjectedInfo.h"
#import "HMDCrashKit+Internal.h"

#define CStrToNSStr(str) [NSString stringWithCString:str encoding:NSUTF8StringEncoding]

void zombieClassName(const char *name, char *newName) {
    NSInteger length = strlen(name);
    memcpy(newName, name, length+1);
    char *mark = "hmd_zombie_";
    if (strstr(name, mark)) {
        size_t count = strlen(mark);
        memmove(newName, name+count, strlen(name)+1-count);
    }
}

BOOL isZombieClass(char * _Nullable name) {
    if (name == NULL) {
        return NO;
    }
    char *mark = "hmd_zombie_";
    return strstr(name, mark) != NULL;
}

NSNumber* hexToNumber(NSString *hexStr){
    if(hexStr == nil){
        return @(0);
    }
    NSScanner *scanner = [NSScanner scannerWithString:hexStr];
    unsigned long long value;
    [scanner scanHexLongLong:&value];
    NSNumber *hexNumber = [NSNumber numberWithLongLong:value];
    if (hexNumber) {
        return hexNumber;
    }
    return @(0);
}

void zombieMsgHandle(__unsafe_unretained id obj, SEL sel) {
    const char *selName = sel_getName(sel);
    const char *currentName = class_getName(object_getClass(obj));
    const UInt8 count = currentName ? strlen(currentName) : strlen("null");
    char *className = malloc(count+1);
    if (currentName) {
        zombieClassName(currentName, className);
    } else {
        strcpy(className, "null");
    }
    
    HMDPrint(" [%s %s]: message sent to deallocated instance %p\n", className, selName, obj);
    
    if (HMDZombieMonitor.sharedInstance.detectedHandle) {
        HMDZombieMonitor.sharedInstance.detectedHandle(CStrToNSStr(className), CStrToNSStr(selName));
    }
    
    // exception
    if (HMDZombieMonitor.sharedInstance.crashWhenDetectedZombie) {
        NSMutableString *msg = [NSMutableString stringWithFormat:@"-[%s %s]: message sent to deallocated instance %p \n", className, selName, obj];
        if (HMDZombieMonitor.sharedInstance.zombieConfig.classList.count > 0) {
            const char *backtrace = [HMDZombieMonitor.sharedInstance getZombieBacktrace:(__bridge void * _Nonnull)(obj)];
            if (backtrace) {
                NSString *bt = [NSString stringWithCString:backtrace  encoding:NSUTF8StringEncoding];
                free((void *)backtrace);
                NSMutableArray *array = (NSMutableArray *)[bt componentsSeparatedByString:@"##"];
                [array removeObject:@""]; // This removes all objects like @""
                if (array.count > 0) {
                    [msg appendString:array[0]];
                }
                
                NSMutableArray<NSDictionary *> *addrUnits = [NSMutableArray array];
                for (int i = 1; i < array.count; i++) {
                    NSString *frame = array[i];
                    NSMutableArray *fr = (NSMutableArray *)[frame componentsSeparatedByString:@" "];
                    [fr removeObject:@""]; // This removes all objects like @""
                    if (fr.count >= 3) {
                        NSString *name = [NSString stringWithFormat:@"frame %d, image: %@", i - 1, fr[1]];
                        NSDictionary *dic = @{@"name":name, @"value":hexToNumber(fr[2])};
                        [addrUnits addObject:dic];
                    }
                }
                if (addrUnits.count > 0) {
                    [HMDSharedCrashKit syncDynamicValue:[addrUnits hmd_jsonString] key:@"custom_address_analysis"];
                }
            }
        }
        [[HMDInjectedInfo defaultInfo] setCustomFilterValue:@(1) forKey:@"ZombieBadAddress"];
        [NSException raise:@"ZombieBadAddress" format:@"%@", msg];
    }
    free(className);
}

@interface HMDZombieObject() {
    Class isa;
}

@end


@implementation HMDZombieObject

+ (void)initialize {
    // 保留
}


- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    // 方法类型传递self 与 sel
    return [NSMethodSignature signatureWithObjCTypes:"v@:"];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    zombieMsgHandle(self, anInvocation.selector);
}

@end

