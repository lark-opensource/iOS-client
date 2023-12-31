//
//  AWECaptionTableViewCell.m
//  Pods
//
//  Created by lixingdong on 2019/8/30.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWECaptionTableViewCell.h"
#import <CreativeKit/ACCAnimatedButton.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/UIColor+ACCAdditions.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>

@interface AWECaptionCollectionViewCell()<UITextFieldDelegate>

@property (nonatomic, strong) AWEStudioCaptionModel *captionModel;
@property (nonatomic, strong) UILabel *captionLabel;

@property (nonatomic, assign, readwrite) BOOL textHighlighted;

@end

@implementation AWECaptionCollectionViewCell

+ (NSString *)identifier
{
    return NSStringFromClass([AWECaptionCollectionViewCell class]);
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

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
    self.backgroundColor = [UIColor clearColor];
    
    [self.contentView addSubview:self.captionLabel];
    
    ACCMasMaker(self.captionLabel, {
        make.edges.equalTo(self);
    });
}


#pragma mark - Public

- (void)configCellWithCaptionModel:(AWEStudioCaptionModel *)caption
{
    self.captionModel = caption;
    self.captionLabel.text = caption.text;
}

- (void)configCaptionHighlight:(BOOL)highlighted
{
    if (highlighted) {
        self.captionLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
    } else {
        self.captionLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse4);
    }
}

#pragma mark - Getter

- (UILabel *)captionLabel
{
    if (!_captionLabel) {
        _captionLabel = [[UILabel alloc] init];
        _captionLabel.textAlignment = NSTextAlignmentCenter;
        _captionLabel.textColor = ACCResourceColor(ACCColorConstTextInverse4);
        _captionLabel.font = [ACCFont() systemFontOfSize:14 weight:ACCFontWeightSemibold];
    }
    return _captionLabel;
}


- (BOOL)textHighlighted
{
    if ([self.captionLabel.textColor isEqualToColor:ACCResourceColor(ACCUIColorConstTextInverse2)]) {
        return YES;
    } else {
        return NO;
    }
}

@end

#pragma mark - AWECaptionTableViewCell

@interface AWECaptionTableViewCell()<UITextFieldDelegate>

@property (nonatomic, strong) AWEStudioCaptionModel *captionModel;
@property (nonatomic, strong) UILabel *captionLabel;
@property (nonatomic, strong) UITextField *captionTextField;
@property (nonatomic, strong) ACCAnimatedButton *audioPlayButton;

@end

@implementation AWECaptionTableViewCell

+ (NSString *)identifier
{
    return NSStringFromClass([AWECaptionTableViewCell class]);
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupUI];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChangeValue:) name: UITextFieldTextDidChangeNotification object:self.captionTextField];
    }
    
    return self;
}

- (void)setupUI
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = [UIColor clearColor];
    
    [self.contentView addSubview:self.captionLabel];
    [self.contentView addSubview:self.captionTextField];
    [self.contentView addSubview:self.audioPlayButton];
    
    ACCMasMaker(self.captionLabel, {
        make.edges.equalTo(self);
    });
    
    ACCMasMaker(self.captionTextField, {
        make.top.bottom.equalTo(self);
        make.leading.equalTo(self.mas_leading).offset(36);
        make.trailing.equalTo(self.mas_trailing).offset(-36);
    });
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    if (highlighted) {
        self.captionLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
    } else {
        self.captionLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse4);
    }
}

#pragma mark - Notification & UITextFieldDelegate

- (void)textFieldDidChangeValue:(NSNotification *)notification
{
    UITextField *textField = self.captionTextField;
    self.captionModel.text = textField.text;
    self.captionLabel.text = textField.text;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    UITextRange* selectedRange = textField.selectedTextRange;
    UITextPosition* beginning = textField.beginningOfDocument;
    UITextPosition* selectionStart = selectedRange.start;
    UITextPosition* selectionEnd = selectedRange.end;
    
    const NSInteger location = [textField offsetFromPosition:beginning toPosition:selectionStart];
    const NSInteger length = [textField offsetFromPosition:selectionStart toPosition:selectionEnd];
    
    NSRange tailRange = NSMakeRange(location, length);
    
    ACCBLOCK_INVOKE(self.textFieldWillReturnBlock, self.captionModel, tailRange);
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if ([text isEqualToString:@"\n"]) {
        
    }
    return YES;
}

#pragma mark - Public

- (void)configCellWithCaptionModel:(AWEStudioCaptionModel *)caption
{
    self.captionModel = caption;
    self.captionLabel.text = caption.text;
    self.captionTextField.text = caption.text;
}

- (void)switchEditMode:(BOOL)isEditMode
{
    if (isEditMode) {
        self.captionTextField.text = self.captionLabel.text;
        self.captionLabel.hidden = YES;
        self.captionTextField.hidden = NO;
        self.audioPlayButton.hidden = NO;
        [self.captionTextField becomeFirstResponder];
        self.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.06];
    } else {
        self.captionLabel.text = self.captionTextField.text;
        self.captionLabel.hidden = NO;
        self.captionTextField.hidden = YES;
        self.audioPlayButton.hidden = YES;
        self.backgroundColor = [UIColor clearColor];
    }
}

- (void)configCaptionHighlight:(BOOL)highlighted
{
    if (highlighted) {
        self.captionLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
    } else {
        self.captionLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse4);
    }
}

#pragma mark - Action

- (void)audioPlayButtonClicked
{
    ACCBLOCK_INVOKE(self.audioPlayBlock, self.captionModel.startTime / 1000.0, self.captionModel.endTime / 1000.0);
}

#pragma mark - Getter

- (UILabel *)captionLabel
{
    if (!_captionLabel) {
        _captionLabel = [[UILabel alloc] init];
        _captionLabel.textAlignment = NSTextAlignmentCenter;
        _captionLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse4);
        _captionLabel.font = [ACCFont() systemFontOfSize:14 weight:ACCFontWeightSemibold];
    }
    return _captionLabel;
}

- (UITextField *)captionTextField
{
    if (!_captionTextField) {
        _captionTextField = [[UITextField alloc] init];
        _captionTextField.backgroundColor = [UIColor clearColor];
        _captionTextField.delegate = self;
        _captionTextField.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
        _captionTextField.tintColor = ACCResourceColor(ACCUIColorPrimary);
        _captionTextField.font = [ACCFont() systemFontOfSize:14 weight:ACCFontWeightSemibold];
        _captionTextField.textAlignment = NSTextAlignmentCenter;
        _captionTextField.hidden = YES;
    }
    return _captionTextField;
}

- (ACCAnimatedButton *)audioPlayButton
{
    if (!_audioPlayButton) {
        UIImage *img = ACCResourceImage(@"icon_caption_play");
        _audioPlayButton = [[ACCAnimatedButton alloc] initWithFrame:CGRectMake(ACC_SCREEN_WIDTH - 36, 12, 20, 20) type:ACCAnimatedButtonTypeAlpha];
        _audioPlayButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-12, -12, -12, -12);
        _audioPlayButton.hidden = YES;
        [_audioPlayButton setImage:img forState:UIControlStateNormal];
        [_audioPlayButton setImage:img forState:UIControlStateHighlighted];
        [_audioPlayButton addTarget:self action:@selector(audioPlayButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    }
    return _audioPlayButton;
}

@end
