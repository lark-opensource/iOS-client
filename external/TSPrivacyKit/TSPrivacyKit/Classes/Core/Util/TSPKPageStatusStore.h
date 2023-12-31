//
//  TSPKPageStatusStore.h
//  Musically
//
//  Created by ByteDance on 2022/8/19.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, TSPKPageStatus) {
    TSPKPageStatusUnknown = 0,
    TSPKPageStatusAppear = 1,
    TSPKPageStatusDisappear = 2,
};

@interface TSPKPageStatusStore : NSObject

+ (nonnull instancetype)shared;

- (void)setConfigs:(NSArray *__nullable)configs;

- (void)addObserver;

- (TSPKPageStatus)pageStatus:(nonnull NSString *)pageName;

@end
