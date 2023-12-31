//
//  ACCMusicTemplateModelTransformer.h
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2020/11/27.
//

#import <Foundation/Foundation.h>
#import "ACCMusicMVTemplateModelProtocol.h"
#import "ACCMomentAIMomentModel.h"
#import <TTVideoEditor/VEAIMomentMoment.h>
#import <TTVideoEditor/VEAlgorithmMVTemplate.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCMusicTemplateModelTransformer : NSObject

+ (NSArray<VEAIMomentMoment *> *)transformToVEMoments:(NSArray<ACCMomentAIMomentModel *> *)moments;
+ (NSArray<VEAlgorithmMVTemplate *> *)transformToVETemplates:(NSArray<id<ACCMusicMVTemplateInfoProtocol>> *)templateInfos;

@end

NS_ASSUME_NONNULL_END
