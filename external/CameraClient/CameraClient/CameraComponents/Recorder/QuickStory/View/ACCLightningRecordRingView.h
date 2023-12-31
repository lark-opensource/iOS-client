//
//  ACCLightningRecordRingView.h
//  RecordButton
//
//  Created by shaohua yang on 8/3/20.
//  Copyright © 2020 United Nations. All rights reserved.
//

#import "ACCLightningRecordAnimatable.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCLightningRecordRingView : UIView <ACCLightningRecordAnimatable>

@property (nonatomic, assign) CGFloat progress; // 0.0 - 1.0
@property (nonatomic, strong) UIColor *progressColor;
@property (nonatomic, strong) NSArray<NSNumber *> *marks; // 白色分割 0.0 - 1.0

- (void)setProgress:(float)progress animated:(BOOL)animated;
- (void)addRangeIndicatorWithStart:(float)start end:(float)end;

@end

NS_ASSUME_NONNULL_END
