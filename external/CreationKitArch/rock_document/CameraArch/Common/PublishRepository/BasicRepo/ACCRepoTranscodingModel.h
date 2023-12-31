//
//  ACCRepoTranscodingModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/14.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCRepoTranscodingModel : NSObject <NSCopying, ACCRepositoryContextProtocol, ACCRepositoryRequestParamsProtocol>

@property (nonatomic, assign) BOOL isReencode;
@property (nonatomic, assign) BOOL isByteVC1;

@property (nonatomic, assign) NSUInteger bitRate;
@property (nonatomic, assign) NSUInteger outputWidth;
@property (nonatomic, assign) NSUInteger outputHeight;

@property (nonatomic, strong) NSURL *uploadURL;
@property (nonatomic, assign) long long uploadFileSize; // KB
@property (nonatomic, readonly) NSMutableDictionary *videoComposeQualityTraceInfo;
@property (nonatomic, readonly) NSMutableDictionary *videoQualityTraceInfo;

@end

@interface AWEVideoPublishViewModel (RepoTranscoding)
 
@property (nonatomic, strong, readonly) ACCRepoTranscodingModel *repoTranscoding;
 
@end

NS_ASSUME_NONNULL_END
