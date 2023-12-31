//
//  HMDDoubleUploadSettings.h
//  Heimdallr
//
//  Created by bytedance on 2022/3/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HMDDoubleUploadSettings : NSObject

@property (nonatomic, assign)BOOL enableOpen;
@property (nonatomic, copy)NSArray *hostAndPath;
@property (nonatomic, copy)NSArray *allowList;

@end

NS_ASSUME_NONNULL_END
