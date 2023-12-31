//
//  IESVideoBSController+BDXModelAdapt.m
//  BDXElement
//
//  Created by bill on 2020/3/24.
//

#import "IESVideoBSController+BDXModelAdapt.h"

@implementation IESVideoBSController (BDXModelAdapt)

- (void)bdx_setHasEnoughCacheForModel:(BOOL (^)(id<IESVideoBSModelProtocol>, NSTimeInterval))hasEnoughCacheForModel {
    [self setHasEnoughCacheForModel:hasEnoughCacheForModel];
}

- (AWEVideoBSModel *)bdx_selectModelWithModels:(NSArray<AWEVideoBSModel *> *)models
                                                 trategyType:(IESVideoBSTrategyType * _Nullable)trategyType {
    return (AWEVideoBSModel *)[self selectModelWithModels:models trategyType:trategyType];
}

- (AWEVideoBSModel *)bdx_selectModelAndUpdateConfigWithModels:(NSArray<AWEVideoBSModel *> *)models duration:(NSTimeInterval)duration {
    return (AWEVideoBSModel *)[self selectModelAndUpdateConfigWithModels:models duration:duration];
}

- (AWEVideoBSModel *)bdx_selectModelAndUpdateConfigWithModels:(NSArray<AWEVideoBSModel *> *)models
                                                     duration:(NSTimeInterval)duration
                                                  trategyType:(IESVideoBSTrategyType * _Nullable)trategyType {
    return (AWEVideoBSModel *)[self selectModelAndUpdateConfigWithModels:models duration:duration trategyType:trategyType];
}

@end
