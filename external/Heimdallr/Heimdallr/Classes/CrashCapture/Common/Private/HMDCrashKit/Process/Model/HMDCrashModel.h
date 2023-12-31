//
//  HMDCrashModel.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/20.
//

#import <Foundation/Foundation.h>
#import "NSDictionary+HMDSafe.h"
#import "NSArray+HMDSafe.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDCrashModel : NSObject

- (instancetype _Nullable)initWithDictionary:(nullable NSDictionary *)dict;

+ (instancetype)objectWithDictionary:(NSDictionary *)dict;

+ (NSArray * _Nullable)objectsWithDicts:(NSArray<NSDictionary *> *)dicts;

- (void)updateWithDictionary:(NSDictionary *)dict;

- (NSDictionary * _Nullable)postDict;

@end

NS_ASSUME_NONNULL_END
