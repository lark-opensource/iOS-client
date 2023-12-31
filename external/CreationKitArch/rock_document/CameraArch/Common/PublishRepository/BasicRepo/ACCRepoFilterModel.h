//
//  ACCRepoFilterModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/24.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCRepoFilterModel : NSObject<NSCopying>

@property (nonatomic, copy, nullable) NSString *colorFilterId;
@property (nonatomic, copy, nullable) NSString *colorFilterName;
@property (nonatomic, copy, nullable) NSNumber *colorFilterIntensityRatio;

@end

@interface AWEVideoPublishViewModel (RepoFilter)
 
@property (nonatomic, strong, readonly) ACCRepoFilterModel *repoFilter;
 
@end


NS_ASSUME_NONNULL_END
