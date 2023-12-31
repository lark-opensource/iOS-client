//
//  ACCEditorTrackerTool.h
//  CameraClient-Pods-Aweme
//
//  Created by liumiao on 2020/11/9.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCComponentLogDelegate.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString * const kAWEEditorEventFirstFrame;
FOUNDATION_EXTERN NSString * const kAWEEditorEventPreControlerInit;
FOUNDATION_EXTERN NSString * const kAWEEditorEventControlerInit;
FOUNDATION_EXTERN NSString * const kAWEEditorEventViewDidLoad;
FOUNDATION_EXTERN NSString * const kAWEEditorEventViewWillAppear;
FOUNDATION_EXTERN NSString * const kAWEEditorEventViewAppear;
FOUNDATION_EXTERN NSString * const kAWEEditorEventCreatePlayer;
FOUNDATION_EXTERN NSString * const kAWEEditorEventPlayerFirstFrame;
FOUNDATION_EXTERN NSString * const kAWEEditorEventPageLoadUI;

@interface ACCEditorTrackerTool : NSObject <ACCComponentLogDelegate>

// all the method should called in main queue

- (void)startTraceTimeForKey:(NSString *)key;

- (void)stopTraceTimeForKey:(NSString *)key;

- (void)addTrackTime:(NSTimeInterval)interval key:(NSString *)key;

- (NSDictionary *)trackerDic;

- (void)cleanTraceTime;

- (void)trackPlayerFirstFrameRenderIfNeed:(NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END
