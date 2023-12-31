//
//  TSPKBinaryInfo.m
//  BDAlogProtocol
//
//  Created by bytedance on 2022/7/21.
//

#import "TSPKBinaryInfo.h"
#import "TSPKMachInfo.h"
#import "TSPKCallStackMacro.h"
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import "TSPKCallStackRuleInfo.h"

@interface TSPKBinaryInfo ()

@property (nonatomic, strong) NSArray *machInfos;

@end

@implementation TSPKBinaryInfo

+ (instancetype)sharedInstance {
    static TSPKBinaryInfo *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[TSPKBinaryInfo alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (NSUInteger)slideOfMachName:(NSString *)machName {
    NSUInteger slide = 0;
    NSArray *machInfos = self.machInfos;
    for (TSPKMachInfo *machInfo in machInfos) {
        if ([machInfo.machName isEqualToString:machName]) {
            slide = machInfo.machSlide;
            break;
        }
    }
    return slide;
}

- (BOOL)fixSortedRules:(NSArray *)rules {
    if ([self isRulesAllFixed:rules]) {
        return NO;
    }
    NSArray *machInfos = self.machInfos; 
    for (TSPKMachInfo *machInfo in machInfos) {
        [machInfo fixSortedRules:rules];
        if ([self isRulesAllFixed:rules]) {
            break;
        }
    }
    return YES;
}

#pragma mark - Private

static bool has_prefix(const char *str, const char *prefix) {
    if (prefix == NULL || str == NULL) {
        return false;
    }

    size_t pre_len = strlen(prefix);
    if (pre_len > strlen(str)) {
        return false;
    }
    return strncmp(prefix, str, pre_len) == 0;
}

- (void)setup {
    const int LEN = 10;
    char prefix[LEN];
    snprintf(prefix, LEN, "%s", NSBundle.mainBundle.executablePath.UTF8String);

    NSMutableArray *infos = [NSMutableArray array];
    for (uint32_t i = 0; i < _dyld_image_count(); i++) { // traverse every image and read slide/start/end info
        mach_header_t *mach_header = (mach_header_t *)_dyld_get_image_header(i); // get every header
        intptr_t mach_slide = _dyld_get_image_vmaddr_slide(i); // slide
        const char *mach_name = _dyld_get_image_name(i); // mach_name
        if (mach_header->filetype == MH_EXECUTE ||
            (mach_header->filetype == MH_DYLIB && has_prefix(mach_name, prefix))) { // only macho in current bundle is allowed
            NSRange range = [self textRangeForHeader:mach_header];
            TSPKMachInfo *info = [[TSPKMachInfo alloc] initWithHeader:mach_header
                                                              slide:mach_slide name:mach_name range:range];
            [infos btd_addObject:info];
        }
    }
    self.machInfos = infos;
}

/// find load command of __text section to get start and end
- (NSRange)textRangeForHeader:(mach_header_t *)header {
    segment_command_t *cur_seg_cmd;
    uintptr_t cur = (uintptr_t) header + sizeof(mach_header_t);
    NSRange range = NSMakeRange(0, 0);

    for (uint i = 0; i < header->ncmds; i++, cur += cur_seg_cmd->cmdsize) {
        cur_seg_cmd = (segment_command_t *) cur;
        if (cur_seg_cmd->cmd == LC_SEGMENT_ARCH_DEPENDENT) {
            for (uint j = 0; j < cur_seg_cmd->nsects; j++) {
                section_t *sect =
                (section_t *)(cur + sizeof(segment_command_t)) + j;
                if (strcmp(sect->sectname, SECT_TEXT) == 0 && sect->size > 0) { // find load command of __text section
                    range = NSMakeRange(sect->addr, sect->size);
                    break;
                }
            }
        }
        if (!NSEqualRanges(range, NSMakeRange(0,0))) {
            break;
        }
    }
    return range;
}

- (BOOL)isRulesAllFixed:(NSArray *)rules {
    BOOL allFixed = YES;
    for (TSPKCallStackRuleInfo *rule in rules) {
        if (![rule isCompleted]) {
            allFixed = NO;
            break;
        }
    }
    return allFixed;
}

@end
