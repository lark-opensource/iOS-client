//
//  IESVideoBSController+BDXModelAdapt.h
//  BDXElement
//
//  Created by bill on 2020/3/24.
//

#import <IESVideoBitrateSelection/IESVideoBitrateSelection.h>

@class AWEVideoBSModel;

NS_ASSUME_NONNULL_BEGIN

@interface IESVideoBSController (BDXModelAdapt)

- (AWEVideoBSModel *)bdx_selectModelWithModels:(NSArray<AWEVideoBSModel *> *)models
                                                       trategyType:(IESVideoBSTrategyType * _Nullable)trategyType;

- (AWEVideoBSModel *)bdx_selectModelAndUpdateConfigWithModels:(NSArray<AWEVideoBSModel *> *)models
                                                           duration:(NSTimeInterval)duration;

- (AWEVideoBSModel *)bdx_selectModelAndUpdateConfigWithModels:(NSArray<AWEVideoBSModel *> *)models
                                                     duration:(NSTimeInterval)duration
                                                  trategyType:(IESVideoBSTrategyType * _Nullable)trategyType;
@end

NS_ASSUME_NONNULL_END
