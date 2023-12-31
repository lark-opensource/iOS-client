//
//  DVEScaleSlider.h
//  TTVideoEditorDemo
//
//  Created by bytedance on 2020/12/20
//  Copyright © 2021 bytedance. All rights reserved.
//

#import "DVEStepSlider.h"

NS_ASSUME_NONNULL_BEGIN
@interface DVEScaleValue :NSObject

@property (nonatomic, assign) NSInteger count;
@property (nonatomic, copy) NSString *title;

- (instancetype)initWithCount:(NSInteger)count title:(NSString *)title;

@end


@interface DVEScaleSlider : DVEStepSlider
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) UIView *scaleContainerView;
@property (nonatomic, strong) NSMutableArray <UIView *>*scaleViews;
@property (nonatomic, strong) NSMutableArray <UILabel *>*scaleLabels;

- (instancetype)initWithStep:(float)step defaultValue:(float)defaultvalue frame:(CGRect)frame;

- (void)showScalesWithArr:(NSArray <DVEScaleValue *>*)scales;
@end

NS_ASSUME_NONNULL_END
