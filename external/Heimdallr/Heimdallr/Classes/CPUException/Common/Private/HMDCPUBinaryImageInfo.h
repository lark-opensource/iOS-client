//
//  HMDCPUBinaryImageManager.h
//  Heimdallr
//
//  Created by zhangxiao on 2021/3/12.
//

#import <Foundation/Foundation.h>
#import <mach/mach.h>

typedef NSString* HMDCPUExceptionImageName;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kHMDCallTreeNodeImageName;
extern NSString *const kHMDCallTreeImageUUID;
extern NSString *const kHMDCallTreeImagePath;
extern NSString *const kHMDCallTreeImageIsMainBinary;
extern NSString *const kHMDCallTreeImageCPUArch;

@interface HMDCPUBinaryImageInfo : NSObject

@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSDictionary *> *binaryMap;
@property (nonatomic, assign, readonly) BOOL isBinaryLoad;

- (void)loadBinaryImage;
- (nullable NSDictionary *)getBinaryImage:(HMDCPUExceptionImageName)imageName;
- (nullable NSDictionary<HMDCPUExceptionImageName,NSDictionary *> *)getBinaryImagesWithBinaryImages:(NSArray<HMDCPUExceptionImageName> *)imageNames;

@end

NS_ASSUME_NONNULL_END
