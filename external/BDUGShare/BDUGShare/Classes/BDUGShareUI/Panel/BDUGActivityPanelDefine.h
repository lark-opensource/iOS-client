//
//  TTPanelDefine.h
//  Pods
//
//  Created by 延晋 张 on 16/6/1.
//
//

#import <Foundation/Foundation.h>

#define kRootViewWillTransitionToSize       @"kRootViewWillTransitionToSize"

typedef NS_ENUM(NSUInteger,  BDUGActivityPanelControllerItemLoadImageType) {
    // 使用TTThemed加载图片
     BDUGActivityPanelControllerItemLoadImageTypeThemed,
    // 使用URL加载图片
     BDUGActivityPanelControllerItemLoadImageTypeURL,
    // 使用Image加载图片
     BDUGActivityPanelControllerItemLoadImageTypeImage,
};

//todo： 处理这里的逻辑
typedef NS_ENUM(NSUInteger,  BDUGActivityPanelControllerItemActionType) {
    // 点击activity item后，panel消失
     BDUGActivityPanelControllerItemActionTypeDismiss,
    // 点击activity item后，panel不消失
     BDUGActivityPanelControllerItemActionTypeNone,
};

typedef NS_OPTIONS(NSUInteger,  BDUGActivityPanelControllerItemUIType) {
    // activity item有边框
     BDUGActivityPanelControllerItemUITypeBorder = 1 << 0,
    // activity item有圆角
     BDUGActivityPanelControllerItemUITypeCornerRadius = 1 << 1,
};

