//
//  PNSKVStoreProtocol.h
//  PNSServiceKit
//
//  Created by chirenhua on 2022/6/15.
//

#import "PNSServiceCenter.h"

#ifndef PNSKVStoreProtocol_h
#define PNSKVStoreProtocol_h

#define PNSKVStoreClass PNS_GET_CLASS(PNSKVStoreProtocol)

@protocol PNSKVStoreProtocol <NSObject>

+ (BOOL)setString:(NSString * _Nullable)value
           forKey:(NSString * _Nonnull)key
         uniqueID:(NSString * _Nullable)uniqueID;

+ (BOOL)setObject:(NSObject<NSCoding> * _Nullable)object
           forKey:(NSString * _Nonnull)key
         uniqueID:(NSString * _Nullable)uniqueID;

+ (NSString * _Nullable)stringForKey:(NSString * _Nonnull)key
                           uniqueID:(NSString * _Nullable)uniqueID;

+ (id _Nullable)objectOfClass:(Class _Nonnull)cls
                      forKey:(NSString * _Nonnull)key
                    uniqueID:(NSString * _Nullable)uniqueID;

+ (void)removeValueForKey:(NSString *_Nullable)key
                 uniqueID:(NSString * _Nullable)uniqueID;

+ (BOOL)containsKey:(NSString *_Nonnull)key
           uniqueID:(NSString * _Nullable)uniqueID;

+ (NSArray * _Nullable)allKeysWithUniqueID:(NSString * _Nullable)uniqueID;

+ (void)clearAllWithUniqueID:(NSString * _Nullable)uniqueID;

+ (void)closeWithUniqueID:(NSString * _Nullable)uniqueID;

+ (void)initializeKVStore;

@end

#endif /* PNSKVStoreProtocol_h */
