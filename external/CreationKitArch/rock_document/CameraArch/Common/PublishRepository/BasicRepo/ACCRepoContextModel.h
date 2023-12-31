//
//  ACCRepoContextModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/20.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModelDefine.h>
#import <CreationKitArch/ACCAwemeModelProtocol.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCRepoContextModel : NSObject <ACCRepositoryContextProtocol, NSCopying>

@property (nonatomic, copy) NSString *createVersion;
@property (nonatomic, copy) NSString *uuid;

@property (nonatomic, copy) NSString *createId; // getter is implemented in other category.

@property (nonatomic, assign) AWEVideoSource videoSource;

@property (nonatomic, assign) AWEVideoType videoType;
@property (nonatomic, assign) AWEVideoRecordType videoRecordType;


@property (nonatomic, readonly) BOOL isMVVideo;

@property (nonatomic, assign) ACCFeedType feedType;

@property (nonatomic, assign) double maxDuration;

@property (nonatomic, assign) ACCRecordLengthMode videoLenthMode;
@property (nonatomic, assign) AWERecordSourceFrom recordSourceFrom;

@property (nonatomic, assign) NSInteger photoToVideoPhotoCountType;

@end

@interface AWEVideoPublishViewModel (RepoContext)
 
@property (nonatomic, strong, readonly) ACCRepoContextModel *repoContext;
 
@end

NS_ASSUME_NONNULL_END
