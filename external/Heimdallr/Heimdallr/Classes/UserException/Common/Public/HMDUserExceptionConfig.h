//
//  HMDUserExceptionConfig.h
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/4/1.
//

#import "HMDTrackerConfig.h"
extern NSString *_Nullable const kHMDModuleUserException;


@interface HMDUserExceptionConfig : HMDTrackerConfig

@property(nonatomic, assign) NSInteger maxUploadCount;
@property(nonatomic, strong, nullable) NSDictionary *typeBlockList;
@property(nonatomic, strong, nullable) NSArray<NSString *> *typeAllowList;

@end

