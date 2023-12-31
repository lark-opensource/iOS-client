//
//  HMDCrashHeaderInfo.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/20.
//

#import "HMDCrashHeaderInfo.h"
#include "hmd_mach.h"
#include "hmd_signal_info.h"
#import "NSString+HMDCrash.h"
#import <mach/exception_types.h>

@implementation HMDCrashHeaderInfo

- (void)updateWithDictionary:(NSDictionary *)dict {
    [super updateWithDictionary:dict];
    
    if ([dict hmd_hasKey:@"crash_time"]) {
        self.crashTime = [dict hmd_doubleForKey:@"crash_time"]/1000;
    } else if ([dict hmd_hasKey:@"time"]) {
        self.crashTime = [dict hmd_doubleForKey:@"time"];
    }
    
    self.faultAddr = [dict hmd_unsignedLongLongForKey:@"fault_address"];
    self.typeStr = [dict hmd_stringForKey:@"type"];
    if ([self.typeStr isEqualToString:@"MACH_Exception"]) {
        self.crashType = HMDCrashTypeMachException;
    }else if ([self.typeStr isEqualToString:@"CPP_Exception"]){
        self.crashType = HMDCrashTypeCPlusPlus;
    }else if ([self.typeStr isEqualToString:@"NSException"]){
        self.crashType = HMDCrashTypeNSException;
    }else if([self.typeStr isEqualToString:@"FATAL_SIGNAL"]){
        self.crashType = HMDCrashTypeFatalSignal;
    }else{
        self.crashType = HMDCrashTypeMissing;
    }
    
    if (self.crashType == HMDCrashTypeMachException) {
        self.mach_type = [dict hmd_intForKey:@"mach_type"];
        self.mach_code = [dict hmd_longLongForKey:@"mach_code"];
        self.mach_subcode = [dict hmd_longLongForKey:@"mach_subcode"];
        self.signum = hmdmach_signalForMachException(self.mach_type, self.mach_code);
        
        const char *code_desc = hmdmach_codeName(self.mach_type, self.mach_code);
        if (code_desc == NULL) {
            code_desc = "";
        }
        const char *exception_name = hmdmach_exceptionName(self.mach_type);
        const char *signal_name = hmdsignal_signalName(self.signum);
        self.name = [NSString stringWithFormat:@"%s (%s)", exception_name, signal_name];
        self.reason = [NSString stringWithFormat:@"%s %s fault_address:0x%016llx",exception_name,code_desc,self.faultAddr];
    } else if (self.crashType == HMDCrashTypeFatalSignal) {
        self.signum = [dict hmd_intForKey:@"signum"];
        self.sigcode = [dict hmd_intForKey:@"sigcode"];
        
        self.mach_type = hmdmach_machExceptionForSignal(self.signum);
        
        const char *exception_name = hmdmach_exceptionName(self.mach_type);
        const char *signal_name = hmdsignal_signalName(self.signum);
        self.name = [NSString stringWithFormat:@"%s (%s)",exception_name, signal_name];
        self.reason = [NSString stringWithFormat:@"%s fault_address:0x%016llx",signal_name,self.faultAddr];
    } else {
        
        NSString *name = [dict hmd_stringForKey:@"name"];
        NSString *name_convert = [name hmdcrash_stringWithHex];
        if (name_convert) {
            name = name_convert;
        }
        
        NSString *reason = [dict hmd_stringForKey:@"reason"];
        NSString *reason_convert = [reason hmdcrash_stringWithHex];
        if (reason_convert) {
            reason = reason_convert;
        }
        
        if (self.crashType == HMDCrashTypeCPlusPlus) {//demangle
            name = [name hmdcrash_cxxDemangledString];
            reason = [reason hmdcrash_cxxDemangledString];
        }
        
        name = [name stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        reason = [reason stringByReplacingOccurrencesOfString:@"\n" withString:@" "];

        self.name = name;
        self.reason = reason.length>0?reason:name;
    }
}

@end
