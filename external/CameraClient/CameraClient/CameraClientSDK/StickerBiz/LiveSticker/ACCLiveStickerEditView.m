//
//  ACCLiveStickerEditView.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/1/4.
//

#import "ACCLiveStickerEditView.h"
#import "ACCLiveStickerView.h"
#import "AWEInteractionLiveStickerModel.h"
#import "ACCConfigKeyDefines.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIFont+ACCAdditions.h>

@interface ACCLiveStickerEditView()

@property (nonatomic, weak) UIView *originalHostView;
@property (nonatomic, weak) ACCLiveStickerView *stickerView;
@property (nonatomic, strong) AWEInteractionLiveStickerInfoModel *originalModel;
@property (nonatomic, strong) AWEInteractionLiveStickerInfoModel *editModel;

@property (nonatomic, assign) CGFloat lastAlpha;

@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, strong) UILabel *guideLabel;

@property (nonatomic, strong) UIView *datePickerView;
@property (nonatomic, strong) UIDatePicker *datePicker;

@end

@implementation ACCLiveStickerEditView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    UIView *maskView = [[UIView alloc] initWithFrame:self.bounds];
    maskView.alpha = 0.f;
    maskView.backgroundColor = ACCResourceColor(ACCColorConstBGInverse2);
    [maskView acc_addSingleTapRecognizerWithTarget:self action:@selector(clickOnConfirmBtn)];
    self.maskView = maskView;
    [self addSubview:maskView];
    ACCMasMaker(maskView, {
        make.edges.equalTo(self);
    });
    
    // Confirm Button
    UIButton *confirmBtn = [[UIButton alloc] init];
    confirmBtn.titleLabel.font = [UIFont boldSystemFontOfSize:15.f];
    confirmBtn.contentEdgeInsets = UIEdgeInsetsMake(5.5, 0.f, 5.5, 0.f);
    confirmBtn.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-10.f, -10.f, -10.f, -10.f);
    [confirmBtn setTitle:@"完成" forState:UIControlStateNormal];
    [confirmBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [confirmBtn addTarget:self action:@selector(clickOnConfirmBtn) forControlEvents:UIControlEventTouchUpInside];
    [self.maskView addSubview:confirmBtn];
    
    CGSize confirmSize = [confirmBtn sizeThatFits:CGSizeMake(CGFLOAT_MAX, 32.f)];
    ACCMasMaker(confirmBtn, {
        make.right.equalTo(@-16.f);
        make.top.equalTo(@(ACC_STATUS_BAR_NORMAL_HEIGHT));
        make.width.equalTo(@(confirmSize.width));
        make.height.equalTo(@32.f);
    });
    
    UILabel *guideLabel = [[UILabel alloc] init];
    guideLabel.textColor = ACCResourceColor(ACCColorConstTextInverse3);
    guideLabel.font = [UIFont acc_systemFontOfSize:14.f weight:ACCFontWeightLight];
    guideLabel.textAlignment = NSTextAlignmentCenter;
    guideLabel.numberOfLines = 0;
    guideLabel.alpha = 0.f;
    guideLabel.text = @"预告过期后，视频上不再展示该贴纸";
    self.guideLabel = guideLabel;
    [self.maskView addSubview:guideLabel];
    ACCMasMaker(guideLabel, {
        make.centerX.equalTo(maskView);
        make.top.equalTo(@(self.acc_height * 0.4 + 10.f));
        make.width.equalTo(@(self.acc_width - 40.f));
        make.height.equalTo(@20.f);
    });
    
    [self setupTimePicker];
}

- (void)setupTimePicker
{
    UIView *datePickerView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, ACC_SCREEN_WIDTH, 90.f)];
    datePickerView.backgroundColor = [UIColor whiteColor];
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.f, 0.f, ACC_SCREEN_WIDTH, 90.f) byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(8.f, 8.f)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.path = bezierPath.CGPath;
    datePickerView.layer.mask = maskLayer;
    self.datePickerView = datePickerView;
    
    UIButton *cancelBtn = [[UIButton alloc] init];
    cancelBtn.titleLabel.font = [UIFont systemFontOfSize:15.f];
    cancelBtn.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-10.f, -10.f, -10.f, -10.f);
    [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    [cancelBtn setTitleColor:ACCResourceColor(ACCColorTextReverse) forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(clickOnCancelBtn) forControlEvents:UIControlEventTouchUpInside];
    [datePickerView addSubview:cancelBtn];
    ACCMasMaker(cancelBtn, {
        make.left.equalTo(@16.f);
        make.top.equalTo(@10.f);
        make.width.equalTo(@32.f);
        make.height.equalTo(@24.f);
    });
    
    UIButton *confirmBtn = [[UIButton alloc] init];
    confirmBtn.titleLabel.font = [UIFont boldSystemFontOfSize:15.f];
    confirmBtn.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-10.f, -10.f, -10.f, -10.f);
    [confirmBtn setTitle:@"确认" forState:UIControlStateNormal];
    [confirmBtn setTitleColor:ACCResourceColor(ACCColorPrimary) forState:UIControlStateNormal];
    [confirmBtn addTarget:self action:@selector(clickOnConfirmBtn) forControlEvents:UIControlEventTouchUpInside];
    [datePickerView addSubview:confirmBtn];
    ACCMasMaker(confirmBtn, {
        make.right.equalTo(@-16.f);
        make.top.equalTo(@10.f);
        make.width.equalTo(@32.f);
        make.height.equalTo(@24.f);
    });
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.textColor = ACCResourceColor(ACCColorTextReverse);
    titleLabel.font = [UIFont acc_systemFontOfSize:17.f weight:ACCFontWeightMedium];
    titleLabel.text = @"选择开播时间";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [datePickerView addSubview:titleLabel];
    ACCMasMaker(titleLabel, {
        make.centerX.equalTo(datePickerView);
        make.top.equalTo(@10.f);
        make.width.equalTo(@280.f);
        make.height.equalTo(@24.f);
    });
    
    UILabel *noteLabel = [[UILabel alloc] init];
    noteLabel.textColor = ACCResourceColor(ACCUIColorConstTextTertiary);
    noteLabel.font = [UIFont acc_systemFontOfSize:12.f weight:ACCFontWeightRegular];
    noteLabel.text = [NSString stringWithFormat:@"请在设置时间前后15分钟开播，未准时开播算为违约，7天内违约2次，未来%@天将无法使用预告功能",@(ACCConfigInt(kConfigInt_studio_live_sticker_maxdaycount))];
    noteLabel.textAlignment = NSTextAlignmentLeft;
    noteLabel.numberOfLines = 2;
    [datePickerView addSubview:noteLabel];
    ACCMasMaker(noteLabel, {
        make.left.equalTo(@16.f);
        make.right.equalTo(@-16.f);
        make.top.equalTo(titleLabel.mas_bottom).offset(10.f);
        make.height.equalTo(@36.f);
    });
    
    UIDatePicker *datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0.f, 0.f, ACC_SCREEN_WIDTH, 240.f)];
    if (@available(iOS 13.4, *)) {
        datePicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
        datePicker.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
    datePicker.backgroundColor = [UIColor whiteColor];
    datePicker.minuteInterval = 10;
    datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    [datePicker addTarget:self action:@selector(dateValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.datePicker = datePicker;
}

- (void)clickOnConfirmBtn
{
    [self endEditSticker];
}

- (void)clickOnCancelBtn
{
    [self.stickerView configWithInfo:self.originalModel];
    [self endEditSticker];
}

- (void)dateValueChanged:(UIDatePicker *)datePicker
{
    self.editModel.targetTime = ceil([datePicker.date timeIntervalSince1970]);
    [self.stickerView configWithInfo:self.editModel];
}

- (void)configDatePicker
{
    NSUInteger targetTime = [self p_fixedTimeForOriginalTime:self.editModel.targetTime];
    NSUInteger startTime = [self p_fixedTimeForOriginalTime:[[NSDate date] timeIntervalSince1970]];
    
    NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:startTime];
    NSDate *targetDate = [NSDate dateWithTimeIntervalSince1970:targetTime];
    
    // 获取7天后的24点整为结束时间
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *startComponents = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:startDate];
    NSUInteger endTime = [calendar dateByAddingUnit:NSCalendarUnitDay value:7 toDate:[calendar dateFromComponents:startComponents] options:0].timeIntervalSince1970;
    
    startComponents = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute fromDate:startDate];
    [startComponents setCalendar:calendar];
    NSDateComponents *targetComponents = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute fromDate:targetDate];
    [targetComponents setCalendar:calendar];
    
    NSUInteger specifiedTime = 0; // 指定时间
    if (targetTime <= 0) {
        // 没有指定开播时间
        specifiedTime = startTime;
    } else if (targetTime < startTime) {
        // 已经过期，锚定到今天或者明天的目标时间
        specifiedTime = [self p_transferDayInfoFromComponent:startComponents toComponent:targetComponents];
        if (specifiedTime < startTime) {
            specifiedTime += 86400;
        }
    } else if (targetTime <= endTime) {
        // 在7天内开播，锚定到指定时间
        specifiedTime = targetTime;
    } else {
        // 大于7天才开播，锚定到最后一天的目标时间
        specifiedTime = [self p_transferDayInfoFromComponent:startComponents toComponent:targetComponents];
        specifiedTime += 86400 * 6;
    }
    
    self.editModel.targetTime = specifiedTime;
    if (!self.stickerView.hasEdited) {
        // 首次设置时，以第一次初始化编辑后的计算为初始值
        self.originalModel = [self.editModel copy];
        self.stickerView.hasEdited = YES;
    }
    self.datePicker.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_GB"];
    self.datePicker.minimumDate = [NSDate dateWithTimeIntervalSince1970:startTime];
    self.datePicker.maximumDate = [NSDate dateWithTimeIntervalSince1970:endTime];
    [self.datePicker setDate:[NSDate dateWithTimeIntervalSince1970:specifiedTime] animated:NO];
    [self.stickerView configWithInfo:self.editModel];
}

- (void)startEditSticker:(ACCLiveStickerView *)stickerView
{
    _stickerView = stickerView;
    self.lastAlpha = stickerView.alpha;
    self.originalHostView = stickerView.superview;
    self.originalModel = stickerView.liveInfo;
    self.editModel = [self.originalModel copy];
    
    [self configDatePicker];
    
    [stickerView transportToEditWithSuperView:self
                            animationDuration:0.2
                                    animation:^{
        self.maskView.alpha = 1.f;
    } completion:^{
        self.guideLabel.alpha = 1.f;
        [self.stickerView changeResponderStatus:YES];
        self.stickerView.inputView = self.datePicker;
        self.stickerView.inputAccessoryView = self.datePickerView;
        [self.stickerView becomeFirstResponder];
    }];
}

- (void)endEditSticker
{
    self.maskView.alpha = 0.f;
    
    [self.stickerView restoreToSuperView:self.originalHostView
                       animationDuration:0.2
                          animationBlock:^{
    } completion:^{
        [self removeFromSuperview];
        [self.stickerView resignFirstResponder];
        self.stickerView.alpha = self.lastAlpha;
        self.stickerView.inputView = nil;
        self.stickerView.inputAccessoryView = nil;
        [self.stickerView changeResponderStatus:NO];
    }];
    ACCBLOCK_INVOKE(self.editDidCompleted);
}

- (NSUInteger)p_fixedTimeForOriginalTime:(NSTimeInterval)timeInterval
{
    // 对齐到整的10min，即600s
    NSUInteger time = ceil(timeInterval);
    if (time % 600 == 0) {
        return time;
    } else {
        return time / 600 * 600 + 600;
    }
}

- (NSUInteger)p_transferDayInfoFromComponent:(NSDateComponents *)from toComponent:(NSDateComponents *)to
{
    to.year = from.year;
    to.month = from.month;
    to.day = from.day;
    return [[to date] timeIntervalSince1970];
}

@end
