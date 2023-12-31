//
//  ACCMomentIntelligentMovieTIMManager.h
//  CameraClient-Pods-Aweme
//
//  Created by Lemonior on 2020/11/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCMomentAIMomentModel, ACCMusicInfo, ACCTemplateRecommendModel;

@interface ACCMomentIntelligentMovieTIMManager : NSObject

+ (void)fetchTemplateWithMoment:(ACCMomentAIMomentModel *)moment
                      musicInfo:(ACCMusicInfo *)musicInfo
                     completion:(void (^)(ACCTemplateRecommendModel * _Nullable templatesModel,
                                          NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
