//
//  ACCFilterAction.h
//  CameraClient
//
//  Created by 郝一鹏 on 2020/1/13.
//

#import <CameraClient/ACCAction.h>
#import "ACCFilterDefine.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCFilterActionType) {
    ACCFilterActionTypeApplyFilter,
    ACCFilterActionTypeSwitchingFilter,
};

@interface ACCFilterAction : ACCAction

@property (nonatomic, strong, nullable) ACCFilterModel *filterModel;
@property (nonatomic, assign) BOOL forceApply;

@property (nonatomic, strong) ACCFilterModel *leftSwitchFilter;
@property (nonatomic, strong) ACCFilterModel *rightSwitchFilter;
@property (nonatomic, assign) CGFloat progress;

@end

@interface ACCFilterAction (Creator)

+ (instancetype)createApplyFilterActionWithFilter:(ACCFilterModel *)filter;
+ (instancetype)createApplyFilterActionWithFilter:(ACCFilterModel *)filter forceApply:(BOOL)forceApply;

+ (instancetype)createSwitchingFilterWithLeftFilter:(ACCFilterModel *)leftFilter
                                        rightFilter:(ACCFilterModel *)rightFilter
                                           progress:(CGFloat)progress;

@end

NS_ASSUME_NONNULL_END
