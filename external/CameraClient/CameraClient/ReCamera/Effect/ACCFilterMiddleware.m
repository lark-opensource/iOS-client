//
//  ACCFilterMiddleware.m
//  CameraClient
//
//  Created by 郝一鹏 on 2020/1/13.
//

#import "ACCFilterMiddleware.h"
#import "ACCFilterAction.h"
#import "ACCFilterState.h"

@implementation ACCFilterMiddleware

+ (instancetype)middlewareWithCamera:(IESMMCamera<IESMMRecoderProtocol> *)camera
{
    ACCFilterMiddleware *middleware = [ACCFilterMiddleware middleware];
    middleware.camera = camera;
    return middleware;
}

- (BOOL)shouldHandleAction:(ACCAction *)action
{
    return [action isKindOfClass:[ACCFilterAction class]];
}

- (ACCAction *)handleAction:(ACCAction *)action next:(nonnull ACCActionHandler)next
{
    if ([action isKindOfClass:[ACCFilterAction class]]) {
        [self handleFilterAction:(ACCFilterAction *)action];
    }
    return next(action);
}

- (ACCAction *)handleFilterAction:(ACCFilterAction *)action
{
    if (action.status == ACCActionStatusPending) {
        switch (action.type) {
            case ACCFilterActionTypeApplyFilter: {
                [self applyFilter:action.filterModel];
                [action fulfill];
                [self dispatch:action];
                break;
            }
            case ACCFilterActionTypeSwitchingFilter: {
                [self switchingFilterWithLeftFilter:action.leftSwitchFilter rightFilter:action.rightSwitchFilter progress:action.progress];
                break;
            }
            default:
                break;
        }
    }
    return action;
}

- (void)applyFilter:(ACCFilterModel *)filterModel
{
    ACCFilterState *filterState = (ACCFilterState *)[self getState];
    if ([filterState.filterModel.filterID isEqualToString:filterModel.filterID]) {
        return;
    }
    [self.camera applyEffect:filterModel.path ?: @"" type:IESEffectFilter];
}

- (void)switchingFilterWithLeftFilter:(ACCFilterModel *)leftFilterModel
                          rightFilter:(ACCFilterModel *)rightFilterModel
                             progress:(CGFloat)progress
{
    [self.camera switchFilterWithLeftPath:leftFilterModel.path rightPath:rightFilterModel.path progress:progress];
}

@end
