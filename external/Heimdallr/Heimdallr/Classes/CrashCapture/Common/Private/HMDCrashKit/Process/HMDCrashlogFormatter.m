//
//  HMDCrashlogFormatter.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/20.
//

#import "HMDCrashlogFormatter.h"
#import "hmd_machine_context.h"
@implementation HMDCrashlogFormatter

+ (NSString *)formatedLogWithCrashInfo:(HMDCrashInfo *)crashInfo
{
    NSMutableString *result = [NSMutableString string];
    
    NSString *uuid = crashInfo.meta.UUID;
    NSString *deviceModel = crashInfo.meta.deviceModel;
    NSString *homeDirectory = NSHomeDirectory();
    NSString *processName = crashInfo.meta.processName;
    NSUInteger processID = crashInfo.meta.processID;
    NSString *bundleID = crashInfo.meta.bundleID;
    
    NSDate *crashTime = nil;
    if (crashInfo.headerInfo.crashTime) {
        crashTime = [NSDate dateWithTimeIntervalSince1970:crashInfo.headerInfo.crashTime];
    }
    else if (crashInfo.exceptionFileModificationDate) {
        crashTime = crashInfo.exceptionFileModificationDate;
    }
    else {
        crashTime = [NSDate date];
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
    NSString *crashTimeString = [formatter stringFromDate:crashTime];
    
    NSString *launchTimeString = @"";
    if (crashInfo.meta.startTime>0) {
        NSDate *lauchTime = [NSDate dateWithTimeIntervalSince1970:crashInfo.meta.startTime];
        launchTimeString = [formatter stringFromDate:lauchTime];
    }

    NSString *commit = crashInfo.meta.commitID;
    
    NSString *version = [NSString stringWithFormat:@"%@(%@)",crashInfo.meta.appVersion,crashInfo.meta.bundleVersion];
    NSString *codeType = crashInfo.meta.arch;
    NSString *osVersion = crashInfo.meta.osFullVersion;
    
    //    ---          展示内容          ---
    
    NSString *crashTypeString = crashInfo.headerInfo.typeStr;
    NSString *exception = crashInfo.headerInfo.name;
    NSString *reason = crashInfo.headerInfo.reason;
    uint64_t faultAddress = crashInfo.headerInfo.faultAddr;
    int sigNum = crashInfo.headerInfo.signum;
    int sigCode = crashInfo.headerInfo.sigcode;
    int64_t machCode = crashInfo.headerInfo.mach_code;
    int64_t machSubCode = crashInfo.headerInfo.mach_subcode;
    
    //   ----------------------------------
    
    
    NSString *str = [NSString stringWithFormat:
           @"Incident Identifier: %@"                                                 "\n"
           "CrashReporter Key:   temporary"                                           "\n"
           "Hardware Model:      %@"                                                  "\n"
           "@Process:            %@ [%u]"                                             "\n"
           "Path:                %@"                                                  "\n"
           "Identifier:          %@"                                                  "\n"
           "Version:             %@"                                                  "\n"
           "\n"
           "Code Type:           %@"                                                  "\n"
           "Parent Process:      [launchd]"                                           "\n"
           "OS Version:          %@"                                                  "\n"
           "\n"
           "Report Version:      104"                                                 "\n"
           "Date/Time:           %@"                                                  "\n"
           "Launch Time:         %@"                                                  "\n"
           "commit:              %@"                                                  "\n"
           "Heimdallr_Crash_Log"                                                      "\n"
           "\n"
           "crashTypeString %@"                                                       "\n"
           "exception %@"                                                             "\n"
           "reason %@"                                                                "\n"
           "fault_address: 0x%016llx"                                                 "\n"
           "mach_codes: 0x%016llx 0x%016llx"                                          "\n"
           "sig_num: %d"                                                              "\n"
           "sig_code: %d"                                                             "\n"
           "\n",
           uuid, deviceModel, processName, (unsigned int)processID,
           homeDirectory, bundleID, version, codeType, osVersion, crashTimeString, launchTimeString, commit,
           crashTypeString, exception, reason,
           faultAddress, machCode, machSubCode, sigNum, sigCode];
    [result appendString:str];
    
    __block HMDCrashThreadInfo *crashThread = nil;
    __block NSUInteger crashThreadIndex = 0;
    
    HMDCrashThreadInfo *stackRecord = crashInfo.stackRecord;
    [crashInfo.threads enumerateObjectsUsingBlock:^(HMDCrashThreadInfo * _Nonnull thread, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL isCrashed = thread.crashed;
        if(isCrashed)
        {
            crashThread = thread;
            crashThreadIndex = idx;
            if (stackRecord) {
                [result appendFormat:@"Thread %lu name:  %@(Enqueued from %@)\nThread %lu Crashed:\n",(unsigned long)idx,thread.threadName, stackRecord.threadName, (unsigned long)idx];
            } else {
                [result appendFormat:@"Thread %lu name:  %@\nThread %lu Crashed:\n",(unsigned long)idx,thread.threadName,(unsigned long)idx];
            }
        } else {
            [result appendFormat:@"Thread %lu name:  %@\nThread %lu\n",(unsigned long)idx,thread.threadName,(unsigned long)idx];
        }
        [self printFrames:thread.frames str:result];

        if (isCrashed && stackRecord) {
            [result appendFormat:@"Enqueued from %@\n",crashInfo.stackRecord.threadName];
            [self printFrames:crashInfo.stackRecord.frames str:result];
        }

        [result appendString:@"\n"];
    }];
    
    if (nil == crashThread) {
        [result appendString:@"Thread 1000 name:  null\n"
                              "Thread Crashed:\n"
                              "0   NULL                            0x0 0x012345 + 0 ((null)) + 0)\n\n"];
    }
    
    NSDictionary *regDict = crashThread.registers.registers;
    if (regDict.count) {
        
        [result appendFormat:@"Thread %lu crashed with Thread State:\n",(unsigned long)crashThreadIndex];
        
        int common_num = hmdmc_num_registers();
        for(int index = 0; index < common_num; index++) {
            const char *name = hmdmc_register_name(index);
            NSString *regName = @(name);
            if ([regDict hmd_hasKey:regName]) {
                unsigned long long value = [regDict hmd_unsignedLongLongForKey:regName];
                NSString *entry = [NSString stringWithFormat:@"%4s: 0x%016llx ",name,value];
                [result appendString:entry];
            }
        }
        
        int exception_num = hmdmc_num_exception_registers();
        for(int index = 0; index < exception_num; index++) {
            const char *name = hmdmc_exception_register_name(index);
            NSString *regName = @(name);
            if ([regDict hmd_hasKey:regName]) {
                unsigned long long value = [regDict hmd_unsignedLongLongForKey:regName];
                NSString *entry = [NSString stringWithFormat:@"%s: 0x%016llx ",name,value];
                [result appendString:entry];
            }
        }
        [result appendString:@"\n\n"];
    }
    
    [result appendString:@"Binary Images:\n"];
    
    [crashInfo.currentlyUsedImages enumerateObjectsUsingBlock:^(HMDCrashBinaryImage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [result appendFormat:@"%#18llx - %#18llx %@%@ %@ <%@> %@\n",obj.base,obj.base+obj.size-1,obj.isMain?@"+":@" ",obj.path.lastPathComponent,obj.arch,obj.uuid,obj.path];
    }];
    
    if (0 == crashInfo.currentlyUsedImages.count) {
        [result appendFormat:@"0x000 - 0x001 +HMDPlaceHolderImage arm64 <uuid> /Bundle/Application/HMDPlaceHolderImage.app\n"];
    }
    
    [result appendString:@"\n"];
    
    return result;

}

+ (void)printFrames:(NSArray<HMDCrashFrameInfo *> *)frames str:(NSMutableString *)str {
    [frames enumerateObjectsUsingBlock:^(HMDCrashFrameInfo * _Nonnull frame, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *symbolResult = nil;
        if (frame.symbolicated) {
            symbolResult = [NSString stringWithFormat:@"(%@ + %llu)",frame.symbolName,frame.addr - frame.symbolAddress];
        }else{
            symbolResult = @"((null)) + 0)";
        }
        HMDCrashBinaryImage *image = frame.image;
        if (image) {
            NSString *imageName = image.path.lastPathComponent;
            if (!imageName) {
                imageName = @"NULL";
            }
            NSString *addressInfo = [NSString stringWithFormat:@"0x%016llx 0x%llx + %llu",frame.addr,frame.image.base,frame.addr-frame.image.base];
            NSString *frameStr = [NSString stringWithFormat:@"%-4lu%-31s %@ %@\n",(unsigned long)idx,imageName.UTF8String,addressInfo,symbolResult];
            [str appendString:frameStr];
        }else{
            NSString *addressInfo = [NSString stringWithFormat:@"0x%016llx 0x0 + 0",frame.addr];
            NSString *frameStr = [NSString stringWithFormat:@"%-4lu%-31s %@ %@\n",(unsigned long)idx,"NULL",addressInfo,symbolResult];
            [str appendString:frameStr];
        }
    }];

}

@end
