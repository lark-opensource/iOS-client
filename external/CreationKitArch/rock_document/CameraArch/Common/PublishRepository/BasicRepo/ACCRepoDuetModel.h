//
//  ACCRepoDuetModel.h
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/23.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModelDefine.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

//extern const int kAWEModernVideoEditDuetEnlargeMetric;

NS_ASSUME_NONNULL_BEGIN

@protocol ACCAwemeModelProtocol;

@interface ACCRepoDuetModel : NSObject <NSCopying, ACCRepositoryTrackContextProtocol, ACCRepositoryRequestParamsProtocol, ACCRepositoryContextProtocol>

@property (nonatomic, assign) BOOL isDuet;
@property (nonatomic, strong) id<ACCAwemeModelProtocol> duetSource; 
@property (nonatomic, strong) NSURL *duetLocalSourceURL;
@property (nonatomic, assign) AWEPublishFlowStep furthestStep;
@property (nonatomic, copy) NSString *duetLayout;// mark this is a new duet which allow user change layout
@property (nonatomic, assign) NSInteger duetOrCommentChainlength;


- (NSArray *)challengeNames;
- (NSArray *)challengeIDs;

@end

@interface AWEVideoPublishViewModel (RepoDuet)
 
@property (nonatomic, strong, readonly) ACCRepoDuetModel *repoDuet;
 
@end

NS_ASSUME_NONNULL_END
