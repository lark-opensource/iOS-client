//
//  ACCRepoTrackModel.h
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/14.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCRepoTrackModel : NSObject <NSCopying, ACCRepositoryTrackContextProtocol, ACCRepositoryRequestParamsProtocol, ACCRepositoryContextProtocol>

@property (nonatomic, strong) NSNumber *recordRouteNumber;
@property (nonatomic, copy) NSString *referString;
@property (nonatomic, copy) NSString *enterFrom;
@property (nonatomic, copy) NSString *enterMethod;
@property (nonatomic, copy) NSString *enterEditPageMethod;
@property (nonatomic, copy) NSDictionary *enterShootPageExtra;

@property (nonatomic, assign) BOOL hasWatermark;
@property (nonatomic, assign) BOOL hasEndWatermark;

@property (nonatomic, copy) NSString *storyShootEntrance;

@property (nonatomic, copy) NSString *shootEnterFrom;

- (NSString *)contentSource;
- (NSDictionary *)contentTypeMap;

- (NSDictionary *)referExtra;

- (NSDictionary *)videoFragmentInfoDictionary;

- (NSDictionary *)mediaCountInfo;

- (NSDictionary *)getLogInfo;

- (NSDictionary *)commonTrackInfoDic;

- (void)trackPostEvent:(NSString *)event
           enterMethod:(nullable NSString *)enterMethod;

- (void)trackPostEvent:(NSString *)event
           enterMethod:(nullable NSString *)enterMethod
             extraInfo:(nullable NSDictionary *)extraInfo;

- (void)trackPostEvent:(NSString *)event
           enterMethod:(nullable NSString *)enterMethod
             extraInfo:(nullable NSDictionary *)extraInfo
           isForceSend:(BOOL)isForceSend;

@end

@interface AWEVideoPublishViewModel (RepoTrack)
 
@property (nonatomic, strong, readonly) ACCRepoTrackModel *repoTrack;
 
@end

NS_ASSUME_NONNULL_END
