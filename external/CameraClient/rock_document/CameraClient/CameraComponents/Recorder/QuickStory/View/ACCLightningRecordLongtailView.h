//
//  ACCLightningRecordLongtailView.h
//  CameraClient-Pods-Aweme
//
//  Created by Kevin Chen on 2021/4/14.
//

#import <UIKit/UIKit.h>
#import "ACCLightningRecordAnimatable.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCLightningRecordLongtailView : UIView <ACCLightningRecordAnimatable>

- (void)setProgress:(float)progress animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
