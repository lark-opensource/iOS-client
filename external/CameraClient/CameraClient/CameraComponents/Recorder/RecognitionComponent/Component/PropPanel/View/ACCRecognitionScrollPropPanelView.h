//
//  ACCRecognitionScrollPropPanelView.h
//  CameraClient
//
//  Created by Shen Chen on 2020/4/1.
//

#import <UIKit/UIKit.h>
#import "ACCRecognitionPropPanelViewModel.h"
#import "ACCExposePanGestureRecognizer.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ACCScrollPropPickerHomeTintMode) {
    ACCScrollPropPickerHomeTintModePicture = 0,
    ACCScrollPropPickerHomeTintModeVideo,
    ACCScrollPropPickerHomeTintModeStory
};

@interface ACCRecognitionScrollPropPanelView : UIView

@property (nonatomic, strong) ACCRecognitionPropPanelViewModel *panelViewMdoel;
@property (nonatomic, strong) ACCExposePanGestureRecognizer *exposePanGestureRecognizer;
@property (nonatomic, assign) ACCScrollPropPickerHomeTintMode homeTintMode;

@end

NS_ASSUME_NONNULL_END
