//
//  ACCRepoEditEffectModel.h
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2021/1/27.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCRepoEditEffectModel : NSObject

@property (nonatomic, strong) NSMutableArray *displayTimeRanges; // 特效区间

// only for draft
@property (nonatomic, strong, nullable) NSData *displayTimeRangesJson;

- (BOOL)isEqualToObject:(ACCRepoEditEffectModel *)object;

@end

@interface AWEVideoPublishViewModel (RepoEditEffect)
 
@property (nonatomic, strong, readonly) ACCRepoEditEffectModel *repoEditEffect;

@end

NS_ASSUME_NONNULL_END
