//
//  HMDNotificationCenter.h
//  CLT
//
//  Created by sunrunwang on 2019/3/27.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMDProtectCapture.h"
#import "HMDNotificationConnection.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDNotificationCenter : NSObject

@property(class, readonly, atomic) HMDNotificationCenter *sharedInstance;

+ (instancetype _Nonnull)sharedInstance;


#pragma mark - Control Method of KVO

- (HMDProtectCapture *_Nullable)addObserver:(id _Nonnull)observer
                                   selector:(SEL _Nonnull)aSelector
                                       name:(NSNotificationName _Nullable)aName
                                     object:(id _Nullable)anObject;

- (HMDProtectCapture *_Nullable)removeObserver:(id _Nonnull)observer
                                          name:(NSNotificationName _Nullable)aName
                                        object:(id _Nullable)anObject;

- (HMDProtectCapture *_Nullable)removeObserver:(id _Nonnull)observer;

- (void)asyncCleanUpInvalidConnection;

@end

NS_ASSUME_NONNULL_END
