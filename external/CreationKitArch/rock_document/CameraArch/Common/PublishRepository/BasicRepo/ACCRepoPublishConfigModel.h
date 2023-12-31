//
//  ACCRepoPublishConfigModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/21.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/AWECoverTextModel.h>

NS_ASSUME_NONNULL_BEGIN

@class AWECoverTextModel, AWEVideoPublishViewModel;
@protocol ACCTextExtraProtocol;

@protocol ACCRepoPublishConfigModelParamProtocol <NSObject>

@optional
- (void)appendTitleToParamDict:(NSMutableDictionary *)params publishModel:(AWEVideoPublishViewModel *)publishViewModel;

@end

@protocol ACCRepoPublishConfigModelTitleObserver <NSObject>

- (void)publishTitleHasChanged:(NSString *)publishTitle extraInfo:(NSArray <id<ACCTextExtraProtocol>> *)titleExtraInfo;

@end


@interface ACCRepoPublishConfigModel : NSObject<NSCopying, ACCRepoPublishConfigModelParamProtocol, ACCRepositoryContextProtocol>

@property (nonatomic, copy) NSString *publishTitle;
@property (nonatomic, copy) NSArray <id<ACCTextExtraProtocol>> *titleExtraInfo;

@property (nonatomic, assign) BOOL saveToAlbum;

@property (nonatomic, assign) BOOL isHashTag;

@property (nonatomic, assign) CGFloat dynamicCoverStartTime;

@property (nonatomic, strong, nullable) UIImage *coverImage;
@property (nonatomic, strong, nullable) UIImage *firstFrameImage;

@property (nonatomic, copy) NSString *tosCoverURI;

//cover text
@property (nonatomic, strong, nullable) AWECoverTextModel *coverTextModel;
@property (nonatomic, strong, nullable) UIImage *coverTextImage;

@property (nonatomic, copy) NSString *hotSpotWord;

@end

@interface AWEVideoPublishViewModel (RepoPublishConfig)
 
@property (nonatomic, strong, readonly) ACCRepoPublishConfigModel *repoPublishConfig;
 
@end

NS_ASSUME_NONNULL_END
