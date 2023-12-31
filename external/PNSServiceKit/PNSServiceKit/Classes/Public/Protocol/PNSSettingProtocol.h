//
//  PNSSettingProtocol.h
//  PNSServiceKit
//
//  Created by chirenhua on 2022/6/15.
//

#import <UIKit/UIKit.h>
#import "PNSServiceCenter.h"

#ifndef PNSSettingProtocol_h
#define PNSSettingProtocol_h

#define PNSSetting PNS_GET_INSTANCE(PNSSettingProtocol)

typedef void (^SettingUpdateBlock)(void);

@protocol PNSSettingProtocol <NSObject>

- (NSDictionary * _Nullable)dictionaryForKey:(NSString * _Nonnull)key;

- (NSString * _Nullable)stringForKey:(NSString * _Nonnull)key;

- (NSArray<NSNumber *> * _Nullable)boolArrayForKey:(NSString * _Nonnull)key;

- (NSArray<NSString *> * _Nullable)stringArrayForKey:(NSString * _Nonnull)key;

- (NSArray<NSNumber *> * _Nullable)floatArrayForKey:(NSString * _Nonnull)key;

- (NSArray<NSNumber *> * _Nullable)intArrayForKey:(NSString * _Nonnull)key;

- (NSArray<NSDictionary *> * _Nullable)dictionaryArrayForKey:(NSString * _Nonnull)key;

- (NSArray<NSArray *> * _Nullable)arrayArrayForKey:(NSString * _Nonnull)key;

- (id _Nullable)modelForKey:(NSString * _Nonnull)key;

- (BOOL)boolForKey:(NSString * _Nonnull)key;

- (CGFloat)floatForKey:(NSString * _Nonnull)key;

- (NSInteger)intForKey:(NSString * _Nonnull)key;

- (void)registerSettingUpdateHandler:(SettingUpdateBlock _Nonnull)block;

@end

#endif /* PNSSettingProtocol_h */
