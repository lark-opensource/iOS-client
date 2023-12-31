//
//  BDPowerLogCallTreeNode.h
//  LarkMonitor
//
//  Created by ByteDance on 2023/1/9.
//

#import <Foundation/Foundation.h>
#import <Heimdallr/HMDThreadBacktrace.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPowerLogCallTreeNode : NSObject

@property(nonatomic, assign) uintptr_t address;

@property(nonatomic, assign) float weight;

@property(nonatomic, assign) int count;

@property(nonatomic, assign) int depth;

@property(nonatomic, strong) NSMutableDictionary<NSNumber *, BDPowerLogCallTreeNode *> *subnodes;

@property(nonatomic, strong) NSMutableArray *backtraces;

@property(nonatomic, weak) BDPowerLogCallTreeNode *parentNode;

@property(nonatomic, assign, readonly) BOOL isLeafNode;

@property(nonatomic, assign) BOOL virtualNode;

- (BDPowerLogCallTreeNode *)addSubNode:(uintptr_t)address weight:(float)weight;

- (void)addBacktrace:(HMDThreadBacktrace *)backtrace;

- (HMDThreadBacktrace *)findBestBacktrace;

- (NSString *)callTreeDescription;

- (NSString *)backtraceDescription;

@end

NS_ASSUME_NONNULL_END
