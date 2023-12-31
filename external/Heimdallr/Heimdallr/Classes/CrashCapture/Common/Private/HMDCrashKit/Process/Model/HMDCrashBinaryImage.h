//
//  HMDCrashBinaryImage.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/20.
//

#import <Foundation/Foundation.h>
#import "HMDCrashModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDCrashSection : HMDCrashModel

@property(nonatomic, assign) uint64_t base;

@property(nonatomic, assign) uint64_t size;

@property(nonatomic, copy) NSString *sectionName;

@end

@interface HMDCrashSegment : HMDCrashModel

@property(nonatomic, assign) uint64_t base;

@property(nonatomic, assign) uint64_t size;

@property(nonatomic, copy) NSString *segmentName;

@property(nonatomic, copy) NSArray<HMDCrashSection *> *sections;

@end

@interface HMDCrashBinaryImage : HMDCrashModel

@property(nonatomic, copy) NSString *path;

@property(nonatomic, readonly) NSString *name;

@property(nonatomic, assign) uint64_t base;

@property(nonatomic, assign) uint64_t size;

@property(nonatomic, copy) NSArray<HMDCrashSegment *> *segments;

@property(nonatomic, copy) NSString *uuid;

@property(nonatomic, copy) NSString *arch;

@property(nonatomic, assign) BOOL load;

@property(nonatomic, assign) BOOL isEnvAbnormal;

@property(nonatomic, assign) BOOL isMain;

- (BOOL)containingAddress:(uintptr_t)address;

- (NSUInteger)hash;

- (BOOL)isEqual:(id)object;

@end

NS_ASSUME_NONNULL_END
