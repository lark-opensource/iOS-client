//
//  ACCMomentDebugMomentListViewController.h
//  Pods
//
//  Created by Pinka on 2020/6/17.
//

#if INHOUSE_TARGET

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ACCMomentDebugMomentListViewControllerType) {
    ACCMomentDebugMomentListViewControllerType_MomentList,
    ACCMomentDebugMomentListViewControllerType_MomentMaterial,
    ACCMomentDebugMomentListViewControllerType_BIMList,
    ACCMomentDebugMomentListViewControllerType_PeopleList,
    ACCMomentDebugMomentListViewControllerType_TagList,
    ACCMomentDebugMomentListViewControllerType_CommonBIMList,
    ACCMomentDebugMomentListViewControllerType_SimIdList,
};

@interface ACCMomentDebugMomentListViewController : UIViewController

@property (nonatomic, assign) ACCMomentDebugMomentListViewControllerType vcType;

@end

NS_ASSUME_NONNULL_END

#endif
