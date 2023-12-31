//
//  ACCLightningRecordRedView.h
//  RecordButton
//
//  Created by shaohua yang on 8/3/20.
//  Copyright © 2020 United Nations. All rights reserved.
//

#import "ACCLightningRecordAnimatable.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCLightningRecordRedView : UIView <ACCLightningRecordAnimatable>

@property (nonatomic, assign) BOOL hideWhenRecording; // 录制中是否要显示红色方块
@property (nonatomic, strong) UIColor *idleColor;

@end

NS_ASSUME_NONNULL_END
