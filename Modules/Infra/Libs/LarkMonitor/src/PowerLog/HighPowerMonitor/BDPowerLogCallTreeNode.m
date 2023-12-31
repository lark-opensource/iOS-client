//
//  BDPowerLogCallTreeNode.m
//  LarkMonitor
//
//  Created by ByteDance on 2023/1/9.
//

#import "BDPowerLogCallTreeNode.h"
#include <dlfcn.h>

@implementation BDPowerLogCallTreeNode

- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (int)count {
    if (self.virtualNode) {
        __block int count = 0;
        [self.subnodes enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, BDPowerLogCallTreeNode * _Nonnull obj, BOOL * _Nonnull stop) {
            count += obj.count;
        }];
        return count;
    } else {
        return _count;
    }
}

- (BDPowerLogCallTreeNode *)addSubNode:(uintptr_t)address weight:(float)weight {
    if (!self.subnodes) {
        self.subnodes = [NSMutableDictionary dictionary];
    }
    BDPowerLogCallTreeNode *subnode = [self.subnodes objectForKey:@(address)];
    if (!subnode) {
        subnode = [[BDPowerLogCallTreeNode alloc] init];
        subnode.address = address;
        subnode.depth = self.depth + 1;
        [self.subnodes setObject:subnode forKey:@(address)];
        subnode.parentNode = self;
    }
    subnode.count ++;
    subnode.weight += weight;
    return subnode;
}

- (BOOL)isLeafNode {
    return self.subnodes.count == 0;
}

- (void)addBacktrace:(HMDThreadBacktrace *)backtrace {
    if (!self.backtraces) {
        self.backtraces = [NSMutableArray array];
    }
    if (backtrace) {
        [self.backtraces addObject:backtrace];
    }
}

- (HMDThreadBacktrace *)findBestBacktrace {
    __block HMDThreadBacktrace *bestBacktrace = nil;
    [self.backtraces enumerateObjectsUsingBlock:^(HMDThreadBacktrace *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!bestBacktrace) {
            bestBacktrace = obj;
        } else if (bestBacktrace.threadCpuUsage < obj.threadCpuUsage) {
            bestBacktrace = obj;
        }
    }];
    return bestBacktrace;
}

- (NSString *)callTreeDescription {
#ifdef DEBUG
    NSMutableString *str = [NSMutableString string];
    if (!self.virtualNode) {
        Dl_info info = { 0 };
        NSString *imageName = nil;
        NSString *funcName = nil;
        if (dladdr((const void *)self.address, &info)) {
            imageName = info.dli_fname?[NSString stringWithUTF8String:info.dli_fname]:@"";
            imageName = [imageName lastPathComponent];
            funcName = info.dli_sname?[NSString stringWithUTF8String:info.dli_sname]:@"";
        }
        int offset = (int)(self.address - (uintptr_t)info.dli_saddr);
        if (self.depth > 0) {
            for (int i = 0; i < self.depth; i++) {
                [str appendFormat:@"\t"];
            }
        }
        [str appendFormat:@"%@ %@ +%d (%.2f)\n",imageName,funcName,offset,self.weight];
    }
    if (self.subnodes.count > 0) {
        NSArray *allSubNodes = [self.subnodes.allValues sortedArrayUsingComparator:^NSComparisonResult(BDPowerLogCallTreeNode * _Nonnull obj1, BDPowerLogCallTreeNode * _Nonnull obj2) {
            if (obj1.weight > obj2.weight) {
                return NSOrderedAscending;
            } else if (obj1.weight < obj2.weight) {
                return NSOrderedDescending;
            } else {
                return NSOrderedSame;
            }
        }];
        [allSubNodes enumerateObjectsUsingBlock:^(BDPowerLogCallTreeNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [str appendString:obj.callTreeDescription];
        }];
    }
    return str;
#else
    return @"";
#endif
}

- (NSString *)backtraceDescription {
#ifdef DEBUG
    NSMutableString *str = [NSMutableString string];
    BDPowerLogCallTreeNode *node = self;
    while (node) {
        if (!node.virtualNode) {
            Dl_info info = { 0 };
            NSString *imageName = nil;
            NSString *funcName = nil;
            if (dladdr((const void *)node.address, &info)) {
                imageName = info.dli_fname?[NSString stringWithUTF8String:info.dli_fname]:@"";
                imageName = [imageName lastPathComponent];
                funcName = info.dli_sname?[NSString stringWithUTF8String:info.dli_sname]:@"";
            }
            int offset = (int)(node.address - (uintptr_t)info.dli_saddr);
            [str appendFormat:@"%@ %@ +%d (%.2f)\n",imageName,funcName,offset,node.weight];
        }
        node = node.parentNode;
    }
    return str;
#else
    return @"";
#endif
}

@end
