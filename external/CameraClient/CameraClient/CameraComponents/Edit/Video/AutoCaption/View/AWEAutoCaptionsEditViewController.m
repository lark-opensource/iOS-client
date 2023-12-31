//
//  AWEAutoCaptionsEditViewController.m
//  Pods
//
//  Created by lixingdong on 2019/9/2.
//

#import "AWEAutoCaptionsEditViewController.h"
#import "AWECaptionBottomView.h"
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreationKitInfra/ACCAlertProtocol.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>

@interface AWEAutoCaptionsEditViewController () <UITableViewDelegate, UITableViewDataSource, ACCEditPreviewMessageProtocol>

@property (nonatomic, strong) NSMutableArray<AWEStudioCaptionModel *> *captions;
@property (nonatomic, copy) NSDictionary *referExtra;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) ACCAnimatedButton *backButton;
@property (nonatomic, strong) ACCAnimatedButton *saveButton;
@property (nonatomic, strong) UIView *separateLine;
@property (nonatomic, strong) UITableView *captionTableView;

@property (nonatomic, assign) NSInteger currentEditRow;

@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, assign) CGFloat audioStopTime;
@property (nonatomic, strong) NSString *captionMD5;

@property (nonatomic, assign) CGFloat startTime;
@property (nonatomic, assign) CGFloat backupStartTime;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) NSInteger backupCurrentIndex;

@property (nonatomic, assign) BOOL ignoreScroll;

@end

@implementation AWEAutoCaptionsEditViewController

- (instancetype)initWithReferExtra:(NSDictionary *)referExtra captions:(NSMutableArray<AWEStudioCaptionModel *> *)captions selectedIndex:(NSInteger)selectedIndex
{
    self = [super init];
    if (self) {
        _referExtra = [referExtra copy];
        self.captions = [[NSMutableArray alloc] initWithArray:captions copyItems:YES];
        self.currentEditRow = selectedIndex;
        self.captionMD5 = [[self.captions componentsJoinedByString:@";"] acc_md5String];
        
        if (selectedIndex < self.captions.count && selectedIndex >= 0) {
            AWEStudioCaptionModel *model = [self.captions objectAtIndex:selectedIndex];
            self.startTime = model.startTime / 1000.0;
            self.backupStartTime = self.startTime;
            self.currentIndex = selectedIndex;
            self.backupCurrentIndex = selectedIndex;
        }
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self addObservers];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.previewService setStickerEditMode:YES];
    
    if ([self validCurrentEditRow]) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentEditRow inSection:0];
        [self.captionTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.previewService setStickerEditMode:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.ignoreScroll = NO;
    
    [self.view endEditing:YES];
    
    [self.previewService setStickerEditMode:YES];
}

- (BOOL)prefersStatusBarHidden
{
    return ![UIDevice acc_isIPhoneX];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)setupUI
{
    self.view.backgroundColor = ACCResourceColor(ACCColorBGCreation2);
    
    [self.view addSubview:self.titleLabel];
    [self.view addSubview:self.backButton];
    [self.view addSubview:self.saveButton];
    [self.view addSubview:self.separateLine];
    [self.view addSubview:self.captionTableView];
    
    [self.captionTableView reloadData];
}

- (void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleKeyboardChangeFrameNotification:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleKeyboardWillShowNotification:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [self.previewService addSubscriber:self];
}

- (void)updateAudioPlayerStatusWithCurrentPlayerTime:(CGFloat)currentPlayerTime
{
    if (!self.isPlaying) {
        return;
    }
    if (self.audioStopTime < currentPlayerTime) {
        [self.previewService setStickerEditMode:YES];
        [self.previewService pause];
        self.isPlaying = NO;
    }
}

#pragma mark - Notification

- (void)handleKeyboardChangeFrameNotification:(NSNotification *)noti
{
    if (self.ignoreScroll) {
        return;
    }
    NSTimeInterval duration = [[noti.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [[noti.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    CGRect keyboardBounds;
    [[noti.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardBounds];
    
    CGRect frame = self.captionTableView.frame;
    if (keyboardBounds.origin.y > ACC_SCREEN_HEIGHT - 1) {
        //隐藏
        frame = CGRectMake(0, 52.0 + [self navigationBarOffsetY], ACC_SCREEN_WIDTH, ACC_SCREEN_HEIGHT - 52.0 - [self navigationBarOffsetY]);
    } else {
        //出现
        frame = CGRectMake(0, 52.0 + [self navigationBarOffsetY], ACC_SCREEN_WIDTH, ACC_SCREEN_HEIGHT - 52.0 - [self navigationBarOffsetY] - keyboardBounds.size.height);
    }
    [UIView animateWithDuration:duration delay:0 options:(curve<<16) animations:^{
        self.captionTableView.frame = frame;
    } completion:^(BOOL finished) {
    }];
}

- (void)handleKeyboardWillShowNotification:(NSNotification *)noti
{
    if (self.ignoreScroll) {
        return;
    }
    if (self.currentEditRow < 0 || self.currentEditRow >= [self.captionTableView numberOfRowsInSection:0]) {
        return;
    }
    [self.captionTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.currentEditRow inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
}

- (BOOL)needAdaptKeyboardHeightWithCellIndexPath:(NSIndexPath *)indexPath keyboardHeight:(CGFloat)keyboardHeight
{
    AWECaptionTableViewCell *cell = [self.captionTableView cellForRowAtIndexPath:indexPath];
    CGRect rect = [self.captionTableView convertRect:cell.frame toView:self.view];
    if (ACC_SCREEN_HEIGHT - CGRectGetMaxY(rect) < keyboardHeight) {
        return YES;
    }
    
    return NO;
}

#pragma mark - UITableViewDelegate, UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kAWECaptionBottomTableViewCellHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.captions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AWECaptionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[AWECaptionTableViewCell identifier]];
    if (!cell) {
        cell = [[AWECaptionTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[AWECaptionTableViewCell identifier]];
    }
    
    if (indexPath.row < self.captions.count) {
        AWEStudioCaptionModel *model = [self.captions objectAtIndex:indexPath.row];
        [cell configCellWithCaptionModel:model];
    }
    
    @weakify(self);
    cell.textFieldWillReturnBlock = ^(AWEStudioCaptionModel *model, NSRange tailRange) {
        @strongify(self);
        [self updateCaptionWithCaption:model tailRange:tailRange row:indexPath.row];
    };
    
    cell.audioPlayBlock = ^(CGFloat startTime, CGFloat endTime) {
        @strongify(self);
        if (self.isPlaying) {
            return;
        }
        self.audioStopTime = endTime;
        self.isPlaying = YES;
        [self.previewService seekToTime:CMTimeMakeWithSeconds(startTime, 1000000) completionHandler:^(BOOL finished) {
            if (finished) {
                [self.previewService setStickerEditMode:NO];
            }
        }];
        
        //track
        NSMutableDictionary *params = [@{} mutableCopy];
        [params addEntriesFromDictionary:self.referExtra];
        [params setObject:self.enterFrom ?: @"" forKey:@"enter_method"];
        [ACCTracker() trackEvent:@"preview_subtitle" params:params needStagingFlag:NO];
    };
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(AWECaptionTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == self.currentEditRow) {
        [cell switchEditMode:YES];
    } else {
        [cell switchEditMode:NO];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.currentEditRow = indexPath.row;
    AWECaptionTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    AWEStudioCaptionModel *model = [self.captions objectAtIndex:indexPath.row];
    self.startTime = model.startTime / 1000.0;
    self.currentIndex = indexPath.row;
    [cell switchEditMode:YES];
    [tableView.visibleCells enumerateObjectsUsingBlock:^(__kindof AWECaptionTableViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (cell != obj) {
            [obj switchEditMode:NO];
        }
    }];
}

#pragma mark - ACCEditPreviewMessageProtocol

- (void)playerCurrentPlayTimeChanged:(NSTimeInterval)currentPlayerTime
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateAudioPlayerStatusWithCurrentPlayerTime:currentPlayerTime];
    });
}

#pragma mark - 更新字幕

- (void)updateCaptionWithCaption:(AWEStudioCaptionModel *)model tailRange:(NSRange)tailRange row:(NSInteger)row
{
    if (tailRange.location == 0 || tailRange.location == model.text.length) {
        return;
    }
    
    self.ignoreScroll = YES;
    CGFloat averageTime = 0;
    CGFloat segmentationTime = 0;
    if (model.text.length > 0) {
        averageTime = (model.endTime - model.startTime) / model.text.length;
    }
    
    NSString *preStr = model.text;
    NSString *tailStr = @"";
    if (tailRange.location < model.text.length) {
        tailStr = [model.text substringFromIndex:tailRange.location];
        preStr = [model.text substringToIndex:tailRange.location];
        segmentationTime = averageTime * tailRange.location + model.startTime;
    }
    
    AWEStudioCaptionModel *nextModel = [[AWEStudioCaptionModel alloc] init];
    nextModel.text = tailStr;
    nextModel.startTime = segmentationTime;
    nextModel.endTime = model.endTime;
    
    model.text = preStr;
    model.endTime = segmentationTime;
    
    if (row < self.captions.count) {
        self.currentEditRow = row + 1;
        [self.captions insertObject:nextModel atIndex:(row + 1)];
        [self.captionTableView reloadData];
        [self.captionTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.currentEditRow inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    }
}

#pragma mark - Action

- (void)backButtonClicked
{
    if ([self validCurrentEditRow]) {
        AWECaptionTableViewCell *cell = [self.captionTableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.currentEditRow inSection:0]];
        [cell switchEditMode:NO];
        self.currentEditRow = -1;
        self.ignoreScroll = NO;
        [self.view endEditing:YES];
    }
    
    if ([self captionHasChanged]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:ACCLocalizedString(@"auto_caption_editor_unsave", @"确认不保存修改内容吗？") preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedString(@"auto_caption_cancel", @"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedString(@"auto_caption_confirm", @"confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self dismissViewControllerAnimated:YES completion:^{
                ACCBLOCK_INVOKE(self.didDismissBlock, self.backupStartTime, self.backupCurrentIndex);
            }];
        }]];
        [ACCAlert() showAlertController:alertController animated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            ACCBLOCK_INVOKE(self.didDismissBlock, self.backupStartTime, self.backupCurrentIndex);
        }];
    }
}

- (void)saveButtonClicked
{
    //track
    NSMutableDictionary *params = [@{} mutableCopy];
    [params addEntriesFromDictionary:self.referExtra];
    [ACCTracker() trackEvent:@"save_edit_subtitle" params:params needStagingFlag:NO];
    
    NSMutableIndexSet *set = [[NSMutableIndexSet alloc] init];
    for (int i = 0; i < self.captions.count; i++) {
        AWEStudioCaptionModel *model = [self.captions objectAtIndex:i];
        if (ACC_isEmptyString(model.text)) {
            [set addIndex:i];
        }
    }
    
    [self.captions removeObjectsAtIndexes:set];
    ACCBLOCK_INVOKE(self.savedBlock, self.captions, self.currentIndex);
    [self dismissViewControllerAnimated:YES completion:^{
        ACCBLOCK_INVOKE(self.didDismissBlock, self.startTime, self.currentIndex);
    }];
}

- (BOOL)captionHasChanged
{
    NSString *finalMD5 = [[self.captions componentsJoinedByString:@";"] acc_md5String];
    
    if ([finalMD5 isEqualToString:self.captionMD5]) {
        return NO;
    }
    
    return YES;
}

#pragma mark - Utils

- (BOOL)validCurrentEditRow
{
    if (self.currentEditRow >= 0 && self.currentEditRow < [self.captionTableView numberOfRowsInSection:0]) {
        return YES;
    }
    
    return NO;
}

- (CGFloat)navigationBarOffsetY
{
    return ([UIDevice acc_isIPhoneX] ? 44 : 0);
}

#pragma mark - Getter

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, [self navigationBarOffsetY], ACC_SCREEN_WIDTH, 52.0)];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
        _titleLabel.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightMedium];
        _titleLabel.text = ACCLocalizedString(@"auto_caption_edit", @"字幕编辑");
    }
    return _titleLabel;
}

- (ACCAnimatedButton *)backButton
{
    if (!_backButton) {
        UIImage *img = ACCResourceImage(@"ic_camera_cancel");
        _backButton = [[ACCAnimatedButton alloc] initWithFrame:CGRectMake(16, 14 + [self navigationBarOffsetY], 24, 24)];
        _backButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-15, -15, -15, -15);
        [_backButton setImage:img forState:UIControlStateNormal];
        [_backButton setImage:img forState:UIControlStateHighlighted];
        [_backButton addTarget:self action:@selector(backButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        
        _backButton.isAccessibilityElement = YES;
        _backButton.accessibilityTraits = UIAccessibilityTraitButton;
        _backButton.accessibilityLabel = @"取消";
    }
    return _backButton;
}

- (ACCAnimatedButton *)saveButton
{
    if (!_saveButton) {
        UIImage *img = ACCResourceImage(@"ic_camera_save");
        _saveButton = [[ACCAnimatedButton alloc] initWithFrame:CGRectMake(ACC_SCREEN_WIDTH - 40, 14 + [self navigationBarOffsetY], 24, 24)];
        _saveButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-15, -15, -15, -15);
        [_saveButton setImage:img forState:UIControlStateNormal];
        [_saveButton setImage:img forState:UIControlStateHighlighted];
        [_saveButton addTarget:self action:@selector(saveButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        
        _saveButton.isAccessibilityElement = YES;
        _saveButton.accessibilityTraits = UIAccessibilityTraitButton;
        _saveButton.accessibilityLabel = @"保存";
    }
    return _saveButton;
}

- (UIView *)separateLine
{
    if (!_separateLine) {
        _separateLine = [[UIView alloc] initWithFrame:CGRectMake(0, 51.0 + [self navigationBarOffsetY], ACC_SCREEN_WIDTH, 1.0 / ACC_SCREEN_SCALE)];
        _separateLine.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.08];
    }
    
    return _separateLine;
}

- (UITableView *)captionTableView
{
    if (!_captionTableView) {
        _captionTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 52.0 + [self navigationBarOffsetY], ACC_SCREEN_WIDTH, ACC_SCREEN_HEIGHT - 52.0 - [self navigationBarOffsetY])];
        _captionTableView.backgroundColor = [UIColor clearColor];
        _captionTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _captionTableView.tableFooterView = [UIView new];
        _captionTableView.delegate = self;
        _captionTableView.dataSource = self;
        [_captionTableView registerClass:[AWECaptionTableViewCell class] forCellReuseIdentifier:[AWECaptionTableViewCell identifier]];
    }
    
    return _captionTableView;
}

@end
