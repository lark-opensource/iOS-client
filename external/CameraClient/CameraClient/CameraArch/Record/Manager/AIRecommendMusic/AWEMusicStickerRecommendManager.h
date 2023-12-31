//
//  AWEMusicStickerRecommendManager.h
//  CameraClient
//
//  Created by Liu Deping on 2019/10/15.
//

#import <Foundation/Foundation.h>
#import "AWEAIMusicRecommendManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCMusicModelProtocol;
@class AWEVideoPublishViewModel;

@interface AWEMusicStickerRecommendManager : NSObject

@property (nonatomic, copy, readonly) NSArray<id<ACCMusicModelProtocol>> *recommendMusicList;

+ (instancetype)sharedInstance;

- (void)fetchRecommendMusicWithRepository:(nullable AWEVideoPublishViewModel *)repository
                                 callback:(nullable AWEAIMusicRecommendFetchCompletion)completion;

@end

NS_ASSUME_NONNULL_END
