//
//  TSPKSafeMutableDict.h
//  TikTok
//
//  Created by admin on 2021/11/22.
//

#import <Foundation/Foundation.h>

@interface TSPKSafeMutableDict : NSMutableDictionary

- (void)removeObjectForKey:(nonnull id)aKey;

- (void)setObject:(nonnull id)anObject forKey:(nonnull id)aKey;

- (nullable id)objectForKey:(nonnull id)aKey;

- (NSArray *_Nonnull)allKeys;

- (NSArray *_Nonnull)allValues;

@end
