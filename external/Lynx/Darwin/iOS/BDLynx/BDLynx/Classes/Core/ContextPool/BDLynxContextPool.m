//
//  BDLynxContextPool.m
//  BDLynx-Pods-Aweme
//
//  Created by bill on 2020/5/19.
//

#import "BDLynxContextPool.h"

@interface BDLynxContextPool ()

@property(nonatomic, strong, readwrite) NSMutableDictionary *sharedPipers;

@end

@implementation BDLynxContextPool

+ (instancetype)sharedInstance {
  static BDLynxContextPool *instance = nil;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[BDLynxContextPool alloc] init];
  });

  return instance;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _sharedPipers = [NSMutableDictionary dictionary];
    _cardPool = [NSMutableArray array];
    _cardsInUse = [NSMutableArray array];
  }
  return self;
}

- (void)addLynxContext:(id)context schema:(NSString *)schema {
  if (!context || !schema) return;
  if (![self.sharedPipers objectForKey:schema]) {
    [self.sharedPipers setObject:context forKey:schema];
  }
}

- (void)removeContext:(NSString *)schema {
  if ([self.sharedPipers objectForKey:schema]) {
    [self.sharedPipers removeObjectForKey:schema];
  }
}

- (BOOL)contextExistsWithSchema:(NSString *)schema {
  if ([self.sharedPipers objectForKey:schema]) {
    return YES;
  }
  return NO;
}

- (id)cardWithSchema:(NSString *)schema {
  if ([self.sharedPipers objectForKey:schema]) {
    return [self.sharedPipers objectForKey:schema];
  }
  return nil;
}

@end
