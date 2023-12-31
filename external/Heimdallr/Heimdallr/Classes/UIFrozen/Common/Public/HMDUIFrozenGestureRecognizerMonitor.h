//
//  HMDUIFrozenGestureRecognizerMonitor.h
//  Pods
//
//  Created by wangyinhui on 2022/4/26.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


//出现多个手势未响应时，发出通知
extern NSNotificationName const _Nullable HMDUIFrozenNotificationGestureUnresponsive;

typedef enum : NSUInteger {
    HMDUIFrozenGestureSwipeUp,
    HMDUIFrozenGestureSwipeDown,
    HMDUIFrozenGestureSwipeLeft,
    HMDUIFrozenGestureSwipeRight
} HMDUIFrozenGestureType;

@protocol HMDUIFrozenGestureDetectProtocol <NSObject>

//是否需要上报UIFrozen异常
- (BOOL)shouldUploadUIFrozenException;

//在发生异常时，获取业务方自定义数据
- (NSDictionary * _Nullable)getCustomExceptionData;

@end


@interface HMDUIFrozenGestureRecord : NSObject

@property(nonatomic, assign) HMDUIFrozenGestureType type;

@property(nonatomic, assign) CGPoint location;

@property(nonatomic, strong, nullable) NSArray * translations;

@end


typedef void(^ _Nullable HMDUIFrozenGestureRecordBlock)(HMDUIFrozenGestureRecord * _Nonnull record);

@interface HMDUIFrozenGestureRecognizerMonitor : NSObject

@property (nonatomic, assign) BOOL isUnresponsive;

@property (nonatomic, assign) BOOL isRecording;

@property(nonatomic, weak, nullable) id<HMDUIFrozenGestureDetectProtocol> delegate;

+ (instancetype _Nullable )shared;

- (void)addUIFrozenGestureRecognizersForWindow:(UIWindow * _Nullable)window;

- (void)addUIFrozenGestureRecognizersForKeyWindow;

- (void)removeUIFrozenGestureRecognizers;

- (void)startRecord;

- (void)stopRecord;

- (void)consumeStoreGestureRecordWithBlock:(HMDUIFrozenGestureRecordBlock)block;

@end

