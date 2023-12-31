//
//  LVVideoReverseOperation.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/28.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "LVTask.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^LVVideoReverseCompletion)(NSString * _Nullable, NSError * _Nullable);

@interface LVVideoReverseOperation : NSOperation <LVProgressTask>

@property (nonatomic, copy, nullable) LVTaskProgressCallback progressHandler;

@property (nonatomic, copy, readonly) LVVideoReverseCompletion completion;

- (instancetype)initWithAsset:(AVAsset *)asset targetPath:(NSString *)targetPath completion:(LVVideoReverseCompletion)completion;

@end

NS_ASSUME_NONNULL_END
