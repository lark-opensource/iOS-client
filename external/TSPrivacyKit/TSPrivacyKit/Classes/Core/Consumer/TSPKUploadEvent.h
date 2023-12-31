//
//  TSPKUploadEvent.h
//  Indexer
//
//  Created by admin on 2021/12/16.
//

#import <Foundation/Foundation.h>
#import "TSPKBaseEvent.h"

typedef NS_ENUM(NSUInteger, TSPKUploadEventType) {
    TSPKUploadEventTypeOneShoot,
    TSPKUploadEventTypeRelease
};

extern NSString *_Nonnull const TSPKEventTagBadcase;

@interface TSPKUploadEvent : TSPKBaseEvent

@property (nonatomic, copy, nullable) NSString *eventName;
@property (nonatomic, copy, nullable) NSArray *backtraces;
@property (nonatomic, strong, nullable) NSMutableDictionary *params;
@property (nonatomic, strong, nullable) NSMutableDictionary *filterParams;
@property (nonatomic) BOOL isALogUpload;
@property (nonatomic, assign) NSInteger uploadDelay;

- (BOOL)uploadALogNeedDelay;
- (void)addExtraFilterParams:(NSArray *_Nullable)array;
@property (nonatomic, assign) TSPKUploadEventType type;

@end
