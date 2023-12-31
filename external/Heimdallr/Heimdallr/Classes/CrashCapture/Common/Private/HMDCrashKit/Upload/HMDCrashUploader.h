//
//  HMDCrashUploader.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HMDCrashUploader <NSObject>

- (instancetype)initWithPath:(NSString *)path;

- (void)uploadCrashLogIfNeeded:(BOOL)needSync;

- (void)setLastCrashTimestamp:(CFTimeInterval)crashTimestamp;

@end

@interface HMDCrashUploader : NSObject

+ (id<HMDCrashUploader>)uploaderWithPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
