//
//  ACCRepoRecorderTrackerToolModel.h
//  AWEStudio
//
//  Created by haoyipeng on 2020/10/29.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreativeKit/ACCComponentLogDelegate.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCRepoRecorderTrackerToolModel : NSObject <NSCopying, ACCComponentLogDelegate>

@property (nonatomic, assign) NSInteger musicDownloadDuration;
@property (nonatomic, assign) NSInteger effectDownloadDuration;
@property (nonatomic, assign) NSInteger videoDownloadDuration;
@property (nonatomic, copy, nullable) NSString *musicID;
@property (nonatomic, copy, nullable) NSString *stickerID;
@property (nonatomic, strong, nullable) NSString *moneyLeftWelfareActivityID;
@property (nonatomic, strong, nullable) NSString *publishWelfareActivityID;
@property (nonatomic, assign) BOOL hasAuthority;
@property (nonatomic, assign) NSTimeInterval pageLoadUICost; //加载页面入口 UI 耗时

- (NSDictionary *)trackerDic;

@end

@interface AWEVideoPublishViewModel (RepoRecorderTrackerTool)
 
@property (nonatomic, strong, readonly) ACCRepoRecorderTrackerToolModel *repoRecorderTrackerTool;
 
@end

NS_ASSUME_NONNULL_END
