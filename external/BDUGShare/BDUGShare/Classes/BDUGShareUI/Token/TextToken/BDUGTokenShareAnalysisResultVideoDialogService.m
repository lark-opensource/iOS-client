//
//  BDUGTokenShareAnalysisResultVDialogService.m
//  Article
//
//  Created by lixiaopeng on 2018/6/21.
//

#import "BDUGTokenShareAnalysisResultVideoDialogService.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import "BDUGDialogBaseView.h"
#import "BDUGTokenShareAnalysisContentViewBase.h"
#import <BDUGShare/BDUGTokenShareModel.h>
#import <BDUGShare/BDUGTokenShareDialogManager.h>
#import "BDUGShareBaseUtil.h"
#import "UIColor+UGExtension.h"
#import "BDUGTokenShareBundle.h"
#import <TTImage/TTImageInfosModel.h>
#import "BDUGShareEvent.h"
#import "BDUGTokenShareDialogService.h"
#import <BDWebImage/UIImageView+BDWebImage.h>

#pragma mark - contentView

@interface BDUGTokenShareAnalysisVideoContentView : BDUGTokenShareAnalysisContentViewBase
@property(nonatomic, strong) UIImageView *picImageView;
@property(nonatomic, strong) UIImageView *messageBackgroundView;
@property(nonatomic, strong) UIImageView *playImageView;
@property(nonatomic, strong) UILabel *messageView;
@property(nonatomic, copy) void (^tapImageBlock)(void);
@end

@implementation BDUGTokenShareAnalysisVideoContentView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _picImageView = [[UIImageView alloc] init];
        _picImageView.frame = CGRectMake(0, 0, 270, 152);
        _picImageView.layer.borderColor = [UIColor colorWithHexString:@"e8e8e8"].CGColor;
        _picImageView.backgroundColor = [UIColor colorWithHexString:@"f4f5f6"];
        _picImageView.layer.borderWidth = [UIDevice btd_onePixel];
        _picImageView.contentMode = UIViewContentModeScaleAspectFill;
        _picImageView.clipsToBounds = YES;
        [self addSubview:_picImageView];
        
        _messageBackgroundView = [[UIImageView alloc] init];
        UIImage * image = [UIImage imageNamed:@"message_background_view" inBundle:BDUGTokenShareBundle.resourceBundle compatibleWithTraitCollection:nil];
        image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(image.size.height / 2, image.size.width / 2, image.size.height / 2 - 1, image.size.width / 2 - 1) resizingMode:UIImageResizingModeTile];
        _messageBackgroundView.image = image;
        _messageBackgroundView.frame = CGRectMake(0, 0, 0, 20);
        [_picImageView addSubview:_messageBackgroundView];
        _picImageView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
        [_picImageView addGestureRecognizer:tap];
        
        _messageView = [[UILabel alloc] init];
        _messageView.font = [UIFont systemFontOfSize:10];
        _messageView.textColor = [UIColor colorWithHexString:@"ffffff"];
        _messageView.textAlignment = NSTextAlignmentCenter;
        [_messageBackgroundView addSubview:_messageView];
        
        _playImageView = [[UIImageView alloc] init];
        NSString *imageName = @"token_play";
        _playImageView.image = [UIImage imageNamed:imageName inBundle:BDUGTokenShareBundle.resourceBundle compatibleWithTraitCollection:nil];
        [_playImageView sizeToFit];
        [_playImageView setCenter:_picImageView.center];
        [_picImageView addSubview:_playImageView];
    }
    return self;
}

- (void)refreshContent:(BDUGTokenShareAnalysisResultModel *)resultModel {
    self.titleLabel.numberOfLines = 2;
    NSString *urlString = [resultModel.pics.firstObject urlStringAtIndex:0];
    NSURL *URL = [NSURL URLWithString:urlString];
    
    __weak UIImageView *weakPic = self.picImageView;
    [self.picImageView bd_setImageWithURL:URL placeholder:nil options:BDImageRequestDefaultOptions progress:nil completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        if (1.5 * image.size.width / image.size.height < 220.0 / 274.0) {
            //判定为长图
            weakPic.contentMode = UIViewContentModeScaleAspectFill;
        } else {
            weakPic.contentMode = UIViewContentModeScaleAspectFit;
        } 
    }];
    if ((resultModel.mediaType == BDUGTokenShareDialogTypeVideo || resultModel.mediaType == BDUGTokenShareDialogTypeShortVideo) &&
        resultModel.videoDuration > 0) {
        int64_t duration = resultModel.videoDuration;
        NSString *durationText;
        if (duration > 0) {
            int minute = (int)duration / 60;
            int second = (int)duration % 60;
            durationText = [NSString stringWithFormat:@"%02i:%02i", minute, second];
        } else {
            durationText = @"00:00";
        }
        self.messageBackgroundView.hidden = NO;
        self.messageView.text = durationText;
        [self.messageView sizeToFit];
    } else {
        self.messageBackgroundView.hidden = YES;
    }
    [super refreshContent: resultModel];
}

- (void)refreshFrame {
    [super refreshFrame];
    
    self.titleLabel.frame = CGRectMake(CGRectGetMinX(self.tipsLabel.frame),0, self.tipsLabel.frame.size.width, 0);
    self.titleLabel.btd_height = [BDUGShareBaseUtil heightOfText:self.titleLabel.text fontSize:self.titleLabel.font.pointSize forWidth:self.titleLabel.frame.size.width forLineHeight:self.titleLineHeight constraintToMaxNumberOfLines:self.titleLabel.numberOfLines];
    if (self.titleLabel.btd_height > self.titleLineHeight) {
        self.picImageView.frame = CGRectMake(self.tipsLabel.btd_left, self.tipsLabel.btd_top - 16 - self.picImageView.btd_height, self.picImageView.btd_width, self.picImageView.btd_height);
    } else {
        self.picImageView.frame = CGRectMake(self.tipsLabel.btd_left, self.tipsLabel.btd_top - 29 - self.picImageView.btd_height, self.picImageView.btd_width, self.picImageView.btd_height);
    }
    self.titleLabel.frame = CGRectMake(self.tipsLabel.btd_left, self.picImageView.btd_top - 8 - self.titleLabel.btd_height, self.titleLabel.btd_width, self.titleLabel.btd_height);
    
    if (!self.messageBackgroundView.hidden) {
        self.messageView.frame = CGRectIntegral(self.messageView.frame);
        self.messageView.btd_left = 6;
        self.messageView.btd_centerY = self.messageBackgroundView.btd_height / 2;
        self.messageBackgroundView.btd_width = self.messageView.btd_right + 6;
        self.messageBackgroundView.btd_left = self.picImageView.btd_width - 4 - self.messageBackgroundView.btd_width;
        self.messageBackgroundView.btd_top = self.picImageView.btd_height - 4 - self.messageBackgroundView.btd_height;
    }
}

- (void)tapAction {
    if (_tapImageBlock) {
        _tapImageBlock();
    }
}
@end

#pragma mark - BDUGTokenShareAnalysisResultVideoDialogService

@implementation BDUGTokenShareAnalysisResultVideoDialogService

NSString * const kBDUGTokenShareAnalysisResultVideoDialogKey = @"kBDUGTokenShareAnalysisResultVideoDialogKey";

+ (void)showTokenAnalysisDialog:(BDUGTokenShareAnalysisResultModel *)resultModel
                    buttonColor:(UIColor *)buttonColor
                  actionModel:(BDUGTokenShareServiceActionModel *)actionModel
{
    void (^hiddenBlock)(BDUGDialogBaseView *) = ^(BDUGDialogBaseView *dialogView){
        [self hiddenDialog:dialogView];
        !actionModel.cancelHandler ?: actionModel.cancelHandler(resultModel);
    };
    NSString *buttonDesc = resultModel.buttonText;
    if (buttonDesc.length == 0) {
        buttonDesc = @"查看";
    }
    BDUGDialogBaseView *baseDialog = [[BDUGDialogBaseView alloc] initDialogViewWithTitle:buttonDesc buttonColor:buttonColor confirmHandler:^(BDUGDialogBaseView *dialogView) {
        [self hiddenDialog:dialogView];
        !actionModel.actionHandler ?: actionModel.actionHandler(resultModel);
    } cancelHandler:^(BDUGDialogBaseView *dialogView) {
       hiddenBlock(dialogView);
    }];
    BDUGTokenShareAnalysisVideoContentView *contentView = [[BDUGTokenShareAnalysisVideoContentView alloc] initWithFrame:CGRectMake(0, 0, 300, 264)];
    __weak BDUGDialogBaseView *weakBaseDialog = baseDialog;
    contentView.tipTapBlock = ^{
        __strong BDUGDialogBaseView *strongBaseDialog = weakBaseDialog;
        [self hiddenDialog:strongBaseDialog];
        !actionModel.tiptapHandler ?: actionModel.tiptapHandler(resultModel);
    };
    contentView.tapImageBlock = ^{
        __strong BDUGDialogBaseView *strongBaseDialog = weakBaseDialog;
        hiddenBlock(strongBaseDialog);
        !actionModel.actionHandler ?: actionModel.actionHandler(resultModel);
    };
    [contentView refreshContent:resultModel];
    [baseDialog addDialogContentView:contentView];
    [baseDialog show];
}

+ (void)hiddenDialog:(BDUGDialogBaseView *)dialogView {
    [dialogView hide];
}
@end
