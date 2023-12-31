//
//  ACCDuetLayoutGuideView.h
//  CameraClient-Pods-Aweme
//
//  Created by 李辉 on 2020/2/24.
//

#import <UIKit/UIKit.h>

#import "ACCDuetLayoutModel.h"

#import <TTVideoEditor/IESMMCamera.h>
#import <TTVideoEditor/IESMMRecoderProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCDuetLayoutGuideView : UIView

+ (ACCDuetLayoutGuideView *)showDuetLayoutGuideViewIfNeededWithContainerView:(UIView *)containerView
                                                                  guideIndex:(NSInteger)index;

- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
