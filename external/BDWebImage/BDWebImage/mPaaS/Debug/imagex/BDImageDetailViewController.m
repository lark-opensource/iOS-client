//
//  BDImageDetailViewController.m
//  BDWebImage_Example
//
//  Created by 陈奕 on 2020/4/2.
//  Copyright © 2020 Bytedance.com. All rights reserved.
//

#import "BDImageDetailViewController.h"
#import <BDWebImage.h>
#import <Masonry/Masonry.h>

@interface BDImageDetailViewController ()<UIPickerViewDataSource,UIPickerViewDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) BDImageView *imageView;
@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) UIToolbar *toolBar;
@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, assign) NSInteger loopCount;
@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, strong) UITextView *recordTextView;
@property (nonatomic, strong) UILabel *urlLabel;
@property (nonatomic, strong) UIScrollView *scrollView;

@end

@implementation BDImageDetailViewController

- (NSString *)description {
    return [NSString stringWithFormat:
            @"BDImageDetailViewController<%p>\n"
            @"  imageView: %@\n"
            @"     button: %@\n"
            @"    toolBar: %@\n"
            @" pickerView: %@\n"
            @"  loopCount: %@\n"
            @"   maskView: %@\n"
            @"recordLabel: %@\n"
            @"   urlLabel: %@\n",
            self,
            self.imageView,
            self.button,
            self.toolBar,
            self.pickerView,
            @(self.loopCount),
            self.maskView,
            self.recordTextView,
            self.urlLabel];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGFloat width = self.view.bounds.size.width;
    
    _scrollView = [UIScrollView new];
    _scrollView.delegate = self;
    _scrollView.frame = (CGRect){0, 0, width, width};
    _scrollView.center = self.view.center;
    _scrollView.userInteractionEnabled = YES;
    _scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:_scrollView];
    
    _urlLabel = [UILabel new];
    _urlLabel.textColor = [UIColor blackColor];
    _urlLabel.text = self.url;
    _urlLabel.numberOfLines = 0;
    [self.view addSubview:_urlLabel];
    [_urlLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(_scrollView.mas_top).offset(-10);
        make.left.equalTo(self.view.mas_left).offset(10);
        make.width.equalTo(_scrollView).multipliedBy(0.9);
        make.height.mas_equalTo(100);
    }];
    _urlLabel.hidden = YES;
    
    _recordTextView = [UITextView new];
    _recordTextView.showsVerticalScrollIndicator = NO;
    _recordTextView.showsHorizontalScrollIndicator = NO;
    _recordTextView.editable = NO;
    _recordTextView.textColor = [UIColor whiteColor];
    _recordTextView.text = self.record;
    _recordTextView.font = [UIFont systemFontOfSize:14];
    _recordTextView.textAlignment = NSTextAlignmentNatural;
    [_recordTextView setBackgroundColor:[UIColor blackColor]];
    [_recordTextView setAlpha:0.5];
    [self.view addSubview:_recordTextView];
    [_recordTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_scrollView);
        make.right.equalTo(_scrollView);
        make.width.equalTo(_scrollView).multipliedBy(0.5);;
        make.height.equalTo(_scrollView);
    }];
    _recordTextView.hidden = YES;
    
    UIButton *copyLogButton = [[UIButton alloc] init];
    [copyLogButton setTitle:@"copy log" forState:UIControlStateNormal];
    copyLogButton.backgroundColor = [UIColor blackColor];
    [copyLogButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:copyLogButton];
    [copyLogButton addTarget:self action:@selector(copyLog) forControlEvents:UIControlEventTouchUpInside];
    [copyLogButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_scrollView.mas_bottom).offset(10);
        make.left.equalTo(self.view.mas_left).offset(10);
    }];
    copyLogButton.hidden = YES;
    
    UIButton *copyURLButton = [[UIButton alloc] init];
    [copyURLButton setTitle:@"copy URL" forState:UIControlStateNormal];
    copyURLButton.backgroundColor = [UIColor blackColor];
    [copyURLButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:copyURLButton];
    [copyURLButton addTarget:self action:@selector(copyURL) forControlEvents:UIControlEventTouchUpInside];
    [copyURLButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(copyLogButton.mas_top);
        make.left.equalTo(copyLogButton.mas_right).offset(10);
    }];
    copyURLButton.hidden = YES;
    
#ifdef DEBUG
    _recordTextView.hidden = NO;
    _urlLabel.hidden = NO;
    copyLogButton.hidden = NO;
    copyURLButton.hidden = NO;
#endif
    
    _imageView = [BDImageView new];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    _imageView.userInteractionEnabled = NO;
    
    __weak typeof(self) weakSelf = self;
    BDImageDetailType showType = self.showType;
    [_imageView bd_setImageWithURL:[NSURL URLWithString:_url] placeholder:nil options:BDImageProgressiveDownload|BDImageRequestIgnoreCache completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (((BDImage *)image).isAnimateImage && showType == BDImageDetailTypeStatic) {
            [strongSelf showAnimItem];
        }
        if(image != nil) {
            CGSize imageSize = strongSelf.imageView.image.size;
            if(imageSize.width == 0) return;
            CGFloat factor = width / imageSize.width;
            CGSize displaySize = CGSizeMake(width, imageSize.height * factor);
            strongSelf.imageView.frame = CGRectMake(0, 0, displaySize.width, displaySize.height);
            strongSelf.scrollView.contentSize = displaySize;
            strongSelf.scrollView.contentOffset = CGPointMake(0, 0);
            [strongSelf.scrollView addSubview:strongSelf.imageView];
        }
    }];
    if (self.showType == BDImageDetailTypeAnim) {
        [self showAnimItem];
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _imageView;
}

- (void)copyLog{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = self.recordTextView.text;
    [self sentAlert];
}

- (void)copyURL{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = self.url;
    [self sentAlert];
}

- (void)sentAlert{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"已经粘贴到剪贴板" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    if (_showType == BDImageDetailTypeStatic) {
        return;
    }
    [_toolBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self.view);
    }];
    if (@available(iOS 11.0, *)) {
        [_toolBar.lastBaselineAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor].active = YES;
    } else {
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_toolBar
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1
                                                               constant:0]];
    }
}

- (void)showAnimItem {
    _toolBar = [[UIToolbar alloc] init];
    UIBarButtonItem *adjustItem = [[UIBarButtonItem alloc] initWithTitle:@"自定循环" style:UIBarButtonItemStylePlain target:self action:@selector(animLoop)];
    UIBarButtonItem *cycleItem = [[UIBarButtonItem alloc] initWithTitle:@"永久循环" style:UIBarButtonItemStylePlain target:self action:@selector(playAnimAlways)];
    UIBarButtonItem *playItem = [[UIBarButtonItem alloc] initWithTitle:@"手动播放" style:UIBarButtonItemStylePlain target:self action:@selector(playAnim)];
    UIBarButtonItem *stopItem = [[UIBarButtonItem alloc] initWithTitle:@"手动暂停" style:UIBarButtonItemStylePlain target:self action:@selector(stopAnim)];
    UIBarButtonItem *flexibleitem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(UIBarButtonSystemItemFlexibleSpace) target:self action:nil];
    [_toolBar setItems:@[adjustItem, flexibleitem, cycleItem, flexibleitem, playItem, flexibleitem, stopItem] animated:YES];
    [self.view addSubview:_toolBar];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(btnClick:)];
    [_imageView addGestureRecognizer:tapGesture];
    _imageView.userInteractionEnabled = YES;
    
    _button = [[UIButton alloc] initWithFrame:(CGRect){0, 0, 60, 60}];
    _button.center = self.view.center;
    [_button setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    [_button addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    [_button setHidden:YES];
    [self.view addSubview:_button];
    
    _maskView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    [_maskView setTag:108];
    [_maskView setBackgroundColor:[UIColor blackColor]];
    [_maskView setAlpha:0.5];
    UITapGestureRecognizer *maskGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closePicker)];
    [_maskView addGestureRecognizer:maskGesture];
    _maskView.userInteractionEnabled = YES;
    [_maskView setHidden:YES];
    [self.view addSubview:_maskView];
    
    _loopCount = 0;
    
    _pickerView = [UIPickerView new];
    _pickerView.backgroundColor = [UIColor whiteColor];
    _pickerView.frame = (CGRect){0, self.view.bounds.size.height, self.view.bounds.size.width, 230};
    _pickerView.delegate = self;
    _pickerView.dataSource = self;
    [_pickerView setHidden:YES];
    [self.view addSubview:_pickerView];
    
}

- (void)btnClick:(UIView *)sender {
    if ([_imageView.player isPlaying]) {
        [self stopAnim];
    } else {
        [self playAnim];
    }
}

- (void)playAnimAlways {
    _imageView.player.loopCount = 0;
    [self playAnim];
}

- (void)playAnim {
    if ([_imageView.player isPlaying]) {
        return;
    }
    [_imageView.player startPlay];
    [_button setImage:[UIImage imageNamed:@"stop"] forState:UIControlStateNormal];
    [_button setHidden:NO];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([self->_imageView.player isPlaying]) {
            [self->_button setHidden:YES];
        }
    });
}

- (void)stopAnim {
    if (![_imageView.player isPlaying]) {
        return;
    }
    [_imageView.player stopPlay];
    [_button setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    [_button setHidden:NO];
}

- (void)animLoop {
    [self stopAnim];
    [self ViewAnimation:_pickerView willHidden:NO];
}

- (void)ViewAnimation:(UIView*)view willHidden:(BOOL)hidden {
      
    [UIView animateWithDuration:0.3 animations:^{
        if (hidden) {
            view.frame = (CGRect){0, self.view.bounds.size.height, self.view.bounds.size.width, 230};
        } else {
            view.frame = (CGRect){0, self.view.bounds.size.height - 230, self.view.bounds.size.width, 230};
            [view setHidden:hidden];
        }
    } completion:^(BOOL finished) {
        [view setHidden:hidden];
        [self->_maskView setHidden:hidden];
    }];
}

- (void)closePicker {
    [self ViewAnimation:_pickerView willHidden:YES];
}

#pragma mark --- UIPickerViewDelegate

- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 20;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return @(row + 1).stringValue;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    _loopCount = row + 1;
    _imageView.player.loopCount = _loopCount;
    [self playAnim];
    [self ViewAnimation:_pickerView willHidden:YES];
}

@end
