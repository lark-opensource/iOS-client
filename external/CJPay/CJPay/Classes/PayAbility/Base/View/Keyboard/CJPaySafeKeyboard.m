//
//  CJPaySafeKeyboard.m
//  CJPay
//
//  Created by 杨维 on 2018/10/18.
//

#import "CJPaySafeKeyboard.h"
#import "UIImage+CJPay.h"
#import "CJPayUIMacro.h"
#import "CJPayServerThemeStyle.h"
#import "CJPayStyleButton.h"
#import "CJPayFullPageBaseViewController+Theme.h"
#import "CJPayLocalThemeStyle.h"


static const NSInteger kButtonDeleteTag = 100;
static const NSInteger kButtonNumTag = 1000;
static const NSInteger kButtonCompleteTag = 101;
static NSString * const kBlankKey = @"blank";
static NSString * const kDeleteKey = @"delete";

@implementation CJPaySafeKeyboardStyleConfigModel

+ (instancetype)defaultModel {
    return [CJPaySafeKeyboardStyleConfigModel modelWithType:CJPaySafeKeyboardTypeDefault];
}

+ (instancetype)modelWithType:(CJPaySafeKeyboardType)keyboardType {
    return [self modelWithType:keyboardType withThemeStyle:[CJPayLocalThemeStyle lightThemeStyle]];
}

+ (instancetype)modelWithType:(CJPaySafeKeyboardType)keyboardType withThemeStyle:(CJPayLocalThemeStyle *)style {
    CJPaySafeKeyboardStyleConfigModel *model = [CJPaySafeKeyboardStyleConfigModel new];
    if (keyboardType == CJPaySafeKeyboardTypeDenoiseV2) {
        model = [self p_configDenoiseKeyboardTypeModelV2];
    } else {
        model = [self p_configDenoiseKeyboardTypeModel];
    }

    return model;
}

+ (CJPaySafeKeyboardStyleConfigModel *)p_configDenoiseKeyboardTypeModel {
    CJPaySafeKeyboardStyleConfigModel *model = [CJPaySafeKeyboardStyleConfigModel new];
    model.font = [UIFont cj_denoiseBoldFontOfSize:26];
    model.rowGap = 6;
    model.buttonCornerRadius = 4;
    model.insets = UIEdgeInsetsMake(6, 6, 0, 6);
    model.deleteImageName = @"cj_denoise_keyboard_delete_icon";
    model.fontColor = [UIColor cj_161823ff];
    model.borderColor = [UIColor cj_161823WithAlpha:0.06];
    model.gridBlankBackgroundColor = UIColor.clearColor;
    model.gridNormalColor = UIColor.whiteColor;
    model.gridHighlightColor = [UIColor cj_161823WithAlpha:0.06];
    model.deleteNormalColor = UIColor.clearColor;
    model.deleteHighlightColor = [UIColor cj_161823WithAlpha:0.06];

    return model;
}

+ (CJPaySafeKeyboardStyleConfigModel *)p_configDenoiseKeyboardTypeModelV2 {
    CJPaySafeKeyboardStyleConfigModel *model = [CJPaySafeKeyboardStyleConfigModel new];
    model.font = [UIFont cj_denoiseBoldFontOfSize:24];
    model.rowGap = 0.5;
    model.insets = UIEdgeInsetsMake(0.5, 0, 0, 0);
    model.deleteImageName = @"cj_denoise_keyboard_delete_icon";
    model.fontColor = [UIColor cj_161823ff];
    model.borderColor = [UIColor cj_161823WithAlpha:0.06];
    model.gridBlankBackgroundColor = UIColor.clearColor;
    model.gridNormalColor = UIColor.whiteColor;
    model.gridHighlightColor = [UIColor cj_161823WithAlpha:0.06];
    model.deleteNormalColor = UIColor.clearColor;
    model.deleteHighlightColor = [UIColor cj_161823WithAlpha:0.06];

    return model;
}

@end


@interface CJPaySafeKeyboard ()

@property (nonatomic, copy) NSArray *titleList;
@property (nonatomic, assign) NSInteger rowCount;
@property (nonatomic, assign) NSInteger columnCount;
@property (nonatomic, strong) CJPaySafeKeyboardStyleConfigModel *styleConfigModel;
@property (nonatomic, assign) BOOL needRelayout;
@property (nonatomic, assign) CGRect lastBounds;

@end


@implementation CJPaySafeKeyboard

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.keyboardType = CJPaySafeKeyboardTypeDefault;
        self.rowCount = 4;
        self.columnCount = 3;
    }
    return self;
}

- (void)setupUI {
    [self setupUIWithModel:[CJPaySafeKeyboardStyleConfigModel modelWithType:self.keyboardType withThemeStyle:self.themeStyle]];
}

- (void)setThemeStyle:(CJPayLocalThemeStyle *)themeStyle
{
    _themeStyle = themeStyle;
    [self setupUI];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self p_resetLayout];
}

- (void)setupUIWithModel:(CJPaySafeKeyboardStyleConfigModel *)model {
    self.styleConfigModel = model;
    self.needRelayout = YES;
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)p_resetLayout {
    BOOL isBoundsChanged = !CGRectEqualToRect(self.bounds,self.lastBounds);
    
    BOOL isUpdatedTitleList = NO;
    if ([self.titleList count] > 10) {
        // 判断目前键盘实际类型是否与 keyboardType 一致
        NSArray *expectedTitleList = [self p_keyboardContentWithType:self.keyboardType];
        if ( expectedTitleList.count > 10 && ![self.titleList[9] isEqualToString:expectedTitleList[9]] ) {
            isUpdatedTitleList = YES;
        }
    }
    
    if (isBoundsChanged || isUpdatedTitleList) {
        self.titleList = [self p_keyboardContentWithType:self.keyboardType];
        self.backgroundColor = self.styleConfigModel.gridBlankBackgroundColor;
        CGRect bounds = self.bounds;
        // 每次设置键盘时，将原来的button清空
        [self cj_removeAllSubViews];
        [self p_setupUIWithModel:self.styleConfigModel bounds:bounds];
    }
}

- (void)p_setupUIWithModel:(CJPaySafeKeyboardStyleConfigModel *)model bounds:(CGRect)bounds {
    self.lastBounds = bounds; //保存当前bounds，用于和下次的新bounds比较
    
    CGFloat kWidth = bounds.size.width - model.insets.left - model.insets.right;
    CGFloat kHeight = bounds.size.height - model.insets.top - model.insets.bottom;
    CGFloat kX = model.insets.left;
    CGFloat kY = model.insets.top;

    CGFloat rowGap = model.rowGap;
    CGFloat columnGap = model.rowGap;
    CGFloat buttonWidth = (kWidth - columnGap * (self.columnCount - 1)) / self.columnCount;
    CGFloat buttonHeight = (kHeight - rowGap * (self.rowCount - 1)) / self.rowCount;

    NSInteger currentRow = 0;
    NSInteger currentColumn = 0;

    for (NSInteger index = 0; index < self.titleList.count; index++) {
        currentColumn = index % self.columnCount;
        currentRow = index / self.columnCount;

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self addSubview:btn];
        CJPayMasMaker(btn, {
            make.left.equalTo(self).offset(kX + currentColumn * (buttonWidth + columnGap));
            make.top.equalTo(self).offset(kY + currentRow * (buttonHeight + rowGap));
            make.width.mas_equalTo(buttonWidth);
            make.height.mas_equalTo(buttonHeight);
        });
        
        btn.clipsToBounds = YES;
        btn.layer.cornerRadius = model.buttonCornerRadius;


        NSString *title = self.titleList[index];

        if ([title isEqualToString:kBlankKey]) {
            btn.backgroundColor = model.gridBlankBackgroundColor;
            btn.enabled = NO;
            btn.isAccessibilityElement = NO;
        } else if ([title isEqualToString:kDeleteKey]) {
            btn.tag = kButtonDeleteTag;
            [btn cj_setImageName:model.deleteImageName forState:UIControlStateNormal];
            [btn cj_setImageName:model.deleteImageName forState:UIControlStateHighlighted];
            [btn addTarget:self action:@selector(p_buttonClicked:) forControlEvents:UIControlEventTouchDown];
            [btn setBackgroundImage:[UIImage cj_imageWithColor:model.deleteNormalColor] forState:UIControlStateNormal];
            [btn setBackgroundImage:[UIImage cj_imageWithColor:model.deleteHighlightColor] forState:UIControlStateHighlighted];
            btn.accessibilityLabel = @"删除";
        } else {
            if ([[NSNumberFormatter alloc] numberFromString:title]) {
                btn.tag = kButtonNumTag + index;
            }
            [btn setTitle:title forState:UIControlStateNormal];
            btn.titleLabel.font = model.font;
            [btn setTitleColor:model.fontColor forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(p_buttonClicked:) forControlEvents:UIControlEventTouchDown];
            [btn setBackgroundImage:[UIImage cj_imageWithColor:model.gridNormalColor] forState:UIControlStateNormal];
            [btn setBackgroundImage:[UIImage cj_imageWithColor:model.gridHighlightColor] forState:UIControlStateHighlighted];
            btn.accessibilityTraits = UIAccessibilityTraitKeyboardKey;

            if ([title isEqualToString:@"X"]) {
                btn.titleLabel.font = [UIFont cj_boldFontOfSize:20];
                btn.backgroundColor = model.gridBlankBackgroundColor;
                [btn setBackgroundImage:nil forState:UIControlStateNormal];
                [btn setBackgroundImage:nil forState:UIControlStateHighlighted];
            }
        }
    }
}
- (void)p_buttonClicked:(UIButton *)button {
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle: UIImpactFeedbackStyleMedium];
        [feedbackGenerator prepare];
        [feedbackGenerator impactOccurred];
    }
    
    if (button.tag == kButtonCompleteTag) {
        CJ_CALL_BLOCK(self.completeClickedBlock);
        return;
    }

    if (button.tag == kButtonDeleteTag) {
        CJ_CALL_BLOCK(self.deleteClickedBlock);
        return;
    }

    CJ_CALL_BLOCK(self.characterClickedBlock, button.titleLabel.text);
    // continue

    if (button.tag >= kButtonNumTag && button.tag <= kButtonNumTag + 10) {
        if (self.numberClickedBlock) {
            NSInteger number = button.titleLabel.text.integerValue;
            self.numberClickedBlock(number);
        }
        return;
    }
}

- (NSArray *)p_keyboardContentWithType:(CJPaySafeKeyboardType)keyboardType {
    switch (keyboardType) {
        case CJPaySafeKeyboardTypeIDCard:
            return @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"X", @"0", kDeleteKey];
        default:
            return @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", kBlankKey, @"0", kDeleteKey];
    }
}

@end
