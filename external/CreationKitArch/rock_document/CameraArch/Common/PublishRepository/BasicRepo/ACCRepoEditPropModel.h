//
//  ACCRepoEditPropModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Liu Bing on 2021/1/18.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@class IESMMEffectTimeRange;

@interface ACCRepoEditPropModel : NSObject<NSCopying, ACCRepositoryContextProtocol>

@property (nonatomic, strong) NSMutableArray<IESMMEffectTimeRange *> *displayTimeRanges;

@end


@interface AWEVideoPublishViewModel (RepoEditProp)
 
@property (nonatomic, strong, readonly) ACCRepoEditPropModel *repoEditProp;
 
@end


NS_ASSUME_NONNULL_END
