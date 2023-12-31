//
//  HMDCrashRecord.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/1/12.
//

#import "HMDCrashRecord.h"
#import "HMDSessionTracker.h"
#import "HMDALogProtocol.h"

@implementation HMDCrashRecord

@dynamic machCrashType;

+ (NSString *)tableName {
    return nil;
}

// 业务方的需求 [解析 crashReason ]
- (HMDMachCrashType)machCrashType {
    NSString *reason;
    if(self.crashType == HMDCrashRecordTypeMachException &&
       (reason = self.crashReason) != nil) {
        reason = [reason uppercaseString];
        if([reason containsString:@"BAD_ACCESS"]) return HMDMachCrashType_EXC_BAD_ACCESS;
        else if([reason containsString:@"BAD_INSTRUCTION"]) return HMDMachCrashType_EXC_BAD_INSTRUCTION;
        else if([reason containsString:@"CRASH"]) return HMDMachCrashType_EXC_CRASH;
        else if([reason containsString:@"ARITHMETIC"]) return HMDMachCrashType_EXC_ARITHMETIC;
        else if([reason containsString:@"EMULATION"]) return HMDMachCrashType_EXC_EMULATION;
        else if([reason containsString:@"SOFTWARE"]) return HMDMachCrashType_EXC_SOFTWARE;
        else if([reason containsString:@"BREAKPOINT"]) return HMDMachCrashType_EXC_BREAKPOINT;
        else if([reason containsString:@"SYSCALL"]) return HMDMachCrashType_EXC_SYSCALL;
        else if([reason containsString:@"MACH_SYSCALL"]) return HMDMachCrashType_EXC_MACH_SYSCALL;
        else if([reason containsString:@"RPC_ALERT"]) return HMDMachCrashType_EXC_RPC_ALERT;
    }
    return HMDMachCrashType_UNKOWN;
}

@end
