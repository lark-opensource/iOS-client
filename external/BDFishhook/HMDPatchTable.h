//
//  HMDPatchTable.h
//  Heimdallr
//
//  Created by sunrunwang on 2023/1/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDPatchLocation : NSObject

@property(nonatomic, nonnull) void *location;

@property(nonatomic) uint64_t addend;

@property(nonatomic, getter=isWeakImport) BOOL weakImport;

#pragma mark metaData

@property(nonatomic) uint32_t metaData;

@property(nonatomic, readonly) uint32_t diversity;  // discriminator

@property(nonatomic, readonly) uint32_t high8;

@property(nonatomic, readonly) uint32_t authenticated;

@property(nonatomic, readonly) uint32_t key;

@property(nonatomic, readonly) uint32_t useAddrDiversity;

#pragma mark patch

- (BOOL)patchReplacement:(void * _Nonnull)replacement;

@end

@interface HMDPatchTable : NSObject

+ (NSArray<HMDPatchLocation *> * _Nullable)patchLocationsForSystemFunction:(void * _Nonnull)systemFunction;

+ (void * _Nullable)searchSystemFunctionForName:(NSString * _Nonnull)name;

@end

NS_ASSUME_NONNULL_END
