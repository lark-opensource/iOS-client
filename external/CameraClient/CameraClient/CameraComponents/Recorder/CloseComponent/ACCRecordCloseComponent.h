//
//  ACCRecordCloseComponent.h
//  Pods
//
//  Created by songxiangwu on 2019/7/28.
//

#import <UIKit/UIKit.h>
#import <CreativeKit/ACCFeatureComponent.h>

typedef NS_ENUM(NSInteger, AWESubtitleActionSheetButtonType) {
    AWESubtitleActionSheetButtonNormal,
    AWESubtitleActionSheetButtonHighlight,
    AWESubtitleActionSheetButtonSubtitle
};

NS_ASSUME_NONNULL_BEGIN

@class ACCAnimatedButton;
@class ACCGroupedPredicate;
@protocol ACCRecordCloseHandlerProtocol;

@interface ACCRecordCloseComponent : ACCFeatureComponent

@property (nonatomic, strong, readonly) ACCGroupedPredicate *showButtonPredicte;
@property (nonatomic, strong, readonly) ACCAnimatedButton *closeButton;

/**
 * @brief Text to be displayed on the reshoot button. If nil,  `重新拍摄` will be used.
 */
@property (nonatomic, copy, nullable) NSString *reshootTitle;

/**
 * @brief Text to be displayed on the exit button. If nil,  `退出` will be used on the alert style action sheet whilst `退出相机` will be on the quick story style action sheet.
 */
@property (nonatomic, copy, nullable) NSString *exitTitle;


@property (nonatomic, strong) id<ACCRecordCloseHandlerProtocol> themeHandler;


- (void)updateCloseButtonVisibility;

@end

NS_ASSUME_NONNULL_END
