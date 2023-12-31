//
//  ACCRepoPropModel.h
//  CameraClient
//
//  Created by haoyipeng on 2020/10/25.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCRepoPropModel : NSObject <NSCopying, ACCRepositoryRequestParamsProtocol, ACCRepositoryContextProtocol>

// Source of props for track use
@property (nonatomic, readonly) NSString *propSelectedFrom;
// limit max sticker save photo in system album
@property (nonatomic, assign) NSInteger totalStickerSavePhotos;
// Props binding challenge stored in the publish stage
@property (nonatomic, copy) NSArray<NSString *> *stickerBindedChallengeInPublishStepArray;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *cacheStickerChallengeNameDict;

- (NSArray <NSString *>*)stickerBindedChallengeArray;


@end

@interface AWEVideoPublishViewModel (RepoProp)
 
@property (nonatomic, strong, readonly) ACCRepoPropModel *repoProp;
 
@end

NS_ASSUME_NONNULL_END
