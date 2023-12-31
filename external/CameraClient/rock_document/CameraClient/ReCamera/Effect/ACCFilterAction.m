//
//  ACCFilterAction.m
//  CameraClient
//
//  Created by 郝一鹏 on 2020/1/13.
//

#import "ACCFilterAction.h"

@implementation ACCFilterAction

+ (instancetype)createApplyFilterActionWithFilter:(ACCFilterModel *)filter
{
    return [self createApplyFilterActionWithFilter:filter forceApply:NO];
}

+ (instancetype)createApplyFilterActionWithFilter:(ACCFilterModel *)filter forceApply:(BOOL)forceApply
{
    ACCFilterAction *action = [ACCFilterAction action];
    action.type = ACCFilterActionTypeApplyFilter;
    action.filterModel = filter;
    action.forceApply = forceApply;
    return action;
}

+ (instancetype)createSwitchingFilterWithLeftFilter:(ACCFilterModel *)leftFilter
                                        rightFilter:(ACCFilterModel *)rightFilter
                                           progress:(CGFloat)progress
{
    ACCFilterAction *action = [ACCFilterAction action];
    action.type = ACCFilterActionTypeSwitchingFilter;
    action.leftSwitchFilter = leftFilter;
    action.rightSwitchFilter = rightFilter;
    action.progress = progress;
    return action;
}

@end
