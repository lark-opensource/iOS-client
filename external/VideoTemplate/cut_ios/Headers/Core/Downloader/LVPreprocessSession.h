//
//  LVPreprocessSession.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/9/11.
//

#import <Foundation/Foundation.h>
#import "VideoTemplateLogger.h"
#import "LVConstDefinition.h"
#import "LVTask.h"

typedef NS_ENUM(NSInteger, LVPreprocessState) {
    LVPreprocessStateUnknown,
    LVPreprocessStateProcessing,
    LVPreprocessStateCancelled,
    LVPreprocessStateSucceeded,
    LVPreprocessStateFailed,
};

NS_ASSUME_NONNULL_BEGIN

@protocol LVPreprocessSession <NSObject, LVProgressTask>

typedef void(^LVPreprocessExcuteCallback)(BOOL success, NSError * _Nullable error);

@property (nonatomic, assign) LVPreprocessState state;

- (void)excuteWithCallback:(LVPreprocessExcuteCallback)callback;

- (void)cancel;

@end

@interface LVPreprocessSession : NSObject <LVPreprocessSession>

@property (nonatomic, copy, nullable) LVTaskProgressCallback progressHandler;

@end

NS_ASSUME_NONNULL_END
