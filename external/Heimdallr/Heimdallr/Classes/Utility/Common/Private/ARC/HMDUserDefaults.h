//
//  HMDUserdefaults.h
//  Pods
//
//  Created by xuminghao.eric on 2020/3/4.
//

#import <Foundation/Foundation.h>

@interface HMDUserDefaults : NSObject

+ (instancetype _Nonnull)standardUserDefaults;

- (id _Nullable)objectForKeyCompatibleWithHistory:(NSString *_Nonnull)defaultName;
/*
 some values for the key may not be found in the old or new plist
 such as： kHMDIgnorePerformanceDataTimekey、kHMDStoreErrorCodeKey、kHMDMemoryGrapthGenerateDateAndCount、kHMDNetTrafficLastProcessTrafficInfo、kHMDMemoryGrapthUploadedCounter
For these value, load history plist is unnecessary, calling this method is recommended.
if you add a new k/v to the plist, use objectForKey to get the value.
 */
- (id _Nullable)objectForKey:(NSString *_Nonnull)defaultName;
- (NSDictionary *_Nullable)dictForKey:(NSString *_Nonnull)defaultName;
- (NSString *_Nullable)stringForKey:(NSString *_Nonnull)defaultName;
- (BOOL)boolForKey:(NSString *_Nonnull)defaultName;
- (NSInteger)integerForKey:(NSString *_Nonnull)defaultName;
- (double)doubleForKey:(NSString *_Nonnull)defaultName;

- (void)setObject:(id _Nullable)value forKey:(NSString *_Nonnull)defaultName;
- (void)setString:(NSString *_Nullable)string forKey:(NSString *_Nonnull)defaultName;
- (void)setBool:(BOOL)boolValue forKey:(NSString *_Nonnull)defaultName;
- (void)setInteger:(NSInteger)integer forKey:(NSString *_Nonnull)defaultName;

- (void)removeObjectForKey:(NSString *_Nonnull)defaultName;
- (void)removeAllObjects;


@end
