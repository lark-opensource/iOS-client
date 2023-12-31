//
//  TSPKMachInfo.m
//  BDAlogProtocol
//
//  Created by bytedance on 2022/7/21.
//

#import "TSPKMachInfo.h"
#import <mach-o/dyld.h>
#import "TSPKCallStackRuleInfo.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import "TSPKLogger.h"
#import "TSPrivacyKitConstants.h"

@implementation TSPKMachInfo

- (instancetype)initWithHeader:(mach_header_t *)header
                         slide:(intptr_t)slide
                          name:(const char *)name
                         range:(NSRange)range {
    if (self = [super init]) {
        self.machHeader = header;
        self.machSlide = slide;
        NSString *machPath = [NSString stringWithUTF8String:name];
        self.machName = [machPath lastPathComponent];
        self.textVMStart = range.location;
        self.textVMEnd = NSMaxRange(range) + 1;
    }

    return self;
}

- (void)fixSortedRules:(NSArray *)rules {
    mach_header_t *header = self.machHeader;
    intptr_t slide = self.machSlide;
    NSString *machName = self.machName;
    intptr_t textVMStart = self.textVMStart; // text section start
    intptr_t textVMEnd = self.textVMEnd;
    if (header == NULL) { // header not find
        return;
    }

    // make sure one target address is between textVMStart and textVMEnd at least
    NSUInteger ruleIndex = 0;
    const NSUInteger maxRuleIndex = rules.count;
    while (ruleIndex < maxRuleIndex) { // find one rule in the scope
        TSPKCallStackRuleInfo *rule = [rules btd_objectAtIndex:ruleIndex];
        NSUInteger target = rule.start - slide;
        if (target >= textVMStart && target < textVMEnd) {
            break;
        }
        ruleIndex += 1;
    }
    if (ruleIndex == maxRuleIndex) { // all rules does not exist in the mach
        return;
    }

    // find base_addr & load command of linkedit segment & load command of function_starts
    NSUInteger base_addr = NSUIntegerMax;
    segment_command_t *cur_seg_cmd;
    segment_command_t * linkedit = NULL;
    struct linkedit_data_command const * function_starts = NULL;

    uintptr_t cur = (uintptr_t) header + sizeof(mach_header_t);
    for (uint i = 0; i < header->ncmds; i++, cur += cur_seg_cmd->cmdsize) {
        cur_seg_cmd = (segment_command_t *) cur;
        if (cur_seg_cmd->cmd == LC_SEGMENT_ARCH_DEPENDENT) {
            if (strcmp(cur_seg_cmd->segname, SEG_LINKEDIT) == 0) {
                linkedit = cur_seg_cmd; // linkedit load command
            }
            if (base_addr == NSUIntegerMax) {
                if (cur_seg_cmd->fileoff == 0 && cur_seg_cmd->filesize != 0) {
                    base_addr = cur_seg_cmd->vmaddr; // text command
                }
            }
        } else if (cur_seg_cmd->cmd == LC_FUNCTION_STARTS) {
            function_starts = (struct linkedit_data_command const *)cur_seg_cmd; // load command of function start
        }
    }
    if (base_addr == NSUIntegerMax) { // Cannot find the base address.
        return;
    }
    if (linkedit == NULL) { // Cannot find the __LINKEDIT command
        return;
    }
    if (function_starts == NULL || function_starts->datasize == 0) { // Cannot find the LC_FUNCTION_STARTS command
        return;
    }

    // calculate info start & infoEnd
    const uint8_t* infoStart = (uint8_t*)(slide + linkedit->vmaddr + function_starts->dataoff - linkedit->fileoff);
    const uint8_t* infoEnd = &infoStart[function_starts->datasize];

    NSUInteger address = base_addr;
    NSUInteger foundAddress = 0;
    TSPKCallStackRuleInfo *rule = [rules btd_objectAtIndex:ruleIndex];

    for (const uint8_t* p = infoStart; (*p != 0) && (p < infoEnd); ) {
        // uleb128 decode
        uint64_t delta = 0;
        uint32_t shift = 0;
        bool more = true;
        do {
            uint8_t byte = *p++;
            delta |= ((byte & 0x7F) << shift);
            shift += 7;
            if ( byte < 0x80 ) {
                address += delta;
                more = false;
            }
        } while (more);

        // fix address next time because next start = current end
        if (foundAddress != 0) {
            // last address find matched address
            rule.binaryName = machName;
            rule.slide = slide;
            rule.start -= slide;
            rule.end = address;
            foundAddress = 0;
            ruleIndex += 1;
            if (ruleIndex >= maxRuleIndex) {
                // target rule list done
                break;
            }
            rule = [rules btd_objectAtIndex:ruleIndex];
        }

        NSUInteger target = rule.start - slide;
        if (target == address) {
            foundAddress = target; // method matched
        } else if (target < address) {
            foundAddress = 0;
            while (target < address) {
                ruleIndex += 1;
                if (ruleIndex >= maxRuleIndex) {
                    //
                    p = infoEnd;
                    break;
                }
                rule = [rules btd_objectAtIndex:ruleIndex];
                target = rule.start - slide;
            }
            if (target == address) {
                foundAddress = target;
            }
        }
    }

    if (foundAddress != 0) {
        rule.binaryName = machName;
        rule.slide = slide;
        rule.start -= slide;
        rule.end = textVMEnd;
    }
}

@end
