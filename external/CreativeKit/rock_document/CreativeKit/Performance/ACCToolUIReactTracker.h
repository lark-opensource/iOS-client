//
//  ACCToolUIReactTracker.h
//  Indexer
//
//  Created by Leon on 2021/11/10.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXTERN NSString * const kAWEUIEventLatestEvent;
 
FOUNDATION_EXTERN NSString * const kAWEUIEventClickPlus;
FOUNDATION_EXTERN NSString * const kAWEUIEventClickAlbum;
FOUNDATION_EXTERN NSString * const kAWEUIEventClickRecord;
FOUNDATION_EXTERN NSString * const kAWEUIEventClickTakePicture;
FOUNDATION_EXTERN NSString * const kAWEUIEventClickCloseCamera;
FOUNDATION_EXTERN NSString * const kAWEUIEventFinishFastRecord;
FOUNDATION_EXTERN NSString * const kAWEUIEventClickRecordNext;
FOUNDATION_EXTERN NSString * const kAWEUIEventClickBackInEdit;
FOUNDATION_EXTERN NSString * const kAWEUIEventClickPublishDaily;
FOUNDATION_EXTERN NSString * const kAWEUIEventClickNextInEdit;
FOUNDATION_EXTERN NSString * const kAWEUIEventClickBackInPublish;
FOUNDATION_EXTERN NSString * const kAWEUIEventClickPublish;


@interface ACCToolUIReactTracker : NSObject

- (NSString *)latestEventName;

- (void)eventBegin:(NSString *)event;
- (void)eventBegin:(NSString *)event withExcuting:(nullable dispatch_block_t)excuting;

//Use kAWEUIEventLatestEvent to complete the latest event.
- (void)eventEnd:(NSString *)event withParams:(NSDictionary *)params;
- (void)eventEnd:(NSString *)event withParams:(NSDictionary *)params excuting:(nullable dispatch_block_t)excuting;

@end


