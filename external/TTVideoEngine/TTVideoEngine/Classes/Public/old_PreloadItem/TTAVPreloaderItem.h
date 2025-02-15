//
//  TTAVPreloaderItem.h
//  Pods
//
//  Created by 钟少奋 on 2017/4/11.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TTAVVideoResolution) {
    TTAVVideoResolutionSD,
    TTAVVideoResolutionHD,
    TTAVVideoResolutionFullHD,
    TTAVVideoResolutionType1080P,
    TTAVVideoResolutionType4K,
};

@interface TTAVPreloaderItem : NSObject

@property (nonatomic, nullable, copy) NSString *vid;
@property (nonatomic, nullable, copy) NSString *URL;
@property (nonatomic, nullable, copy) NSString *filePath;
@property (nonatomic, assign) TTAVVideoResolution resolution;
@property (nonatomic, nullable, copy) NSString *fileKey;
@property (nonatomic, assign) NSTimeInterval urlGenerateTime; // seconds since 1970. Dimension: second
@property (nonatomic, assign) int32_t supportedResolutionMask;
@property (nonatomic, assign) int64_t taskId;

- (NSArray<NSNumber *> *)supportedResolutionTypes;

@end

NS_ASSUME_NONNULL_END
