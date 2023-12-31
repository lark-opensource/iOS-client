//
//  AWEASMusicCategoryTableViewController.m
//  AWEStudio
//
//  Created by 李茂琦 on 2018/9/5.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "AWEASMusicCategoryTableViewController.h"
#import "ACCASMusicCategoryManager.h"
#import "AWEASSMusicNavView.h"
#import "ACCASMusicCategoryTableViewCell.h"
#import "ACCVideoMusicCategoryModel.h"
#import "ACCMusicViewBuilderProtocol.h"

#import <CreationKitInfra/ACCModuleService.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCTrackProtocol.h>

#import <Masonry/View+MASAdditions.h>


@interface AWEASMusicCategoryTableViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) ACCASMusicCategoryManager *manager;
@property (nonatomic, copy) NSString *previousPage;
@property (nonatomic, assign) BOOL shouldHideCellMoreButton;
@property (nonatomic, strong) AWEASSMusicNavView *navView;
@property (nonatomic, assign) BOOL isCommerce;
@property (nonatomic, assign) ACCServerRecordMode recordMode;
@property (nonatomic, assign) NSTimeInterval videoDuration;
@property (nonatomic, assign) BOOL disableCutMusic;

@end

@implementation AWEASMusicCategoryTableViewController

@synthesize completion = _completion, enableClipBlock = _enableClipBlock, willClipBlock = _willClipBlock;

- (BOOL)configWithRouterParamDict:(NSDictionary<NSString *,NSString *> *)paramDict
{
    self.previousPage = [paramDict objectForKey:@"previousPage"];
    self.shouldHideCellMoreButton = [[paramDict objectForKey:@"hideMore"] isEqualToString:@"1"];
    self.isCommerce = [paramDict acc_boolValueForKey:@"is_commerce"];
    self.recordMode = [paramDict acc_intValueForKey:@"record_mode"];
    self.videoDuration = [paramDict acc_doubleValueForKey:@"video_duration"];
    self.disableCutMusic = [paramDict acc_boolValueForKey:@"disable_cut_music"];
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupView];
    [self loadData];
}

- (void)setupView
{
    self.navView.titleLabel.text = @"play_list";
    [self.view addSubview:self.navView];    
    CGFloat navViewHeight = [self.navView recommendHeight];
    ACCMasMaker(self.navView, {
        make.leading.equalTo(@0);
        make.trailing.equalTo(self.view.mas_trailing);
        make.top.equalTo(self.view);
        make.height.equalTo(@(navViewHeight));
    });
    
    [self.view addSubview:self.tableView];
    ACCMasMaker(self.tableView, {
        make.top.equalTo(self.navView.mas_bottom);
        make.left.equalTo(self.view);
        make.width.equalTo(self.view);
        make.bottom.equalTo(self.view);
    });
    [self loadData];
}

- (void)refreshUI
{
    [self.tableView reloadData];
}

- (AWEASSMusicNavView *)navView
{
    if (!_navView) {
        _navView = [[AWEASSMusicNavView alloc] init];
        _navView.leftButtonIsBack = YES;
        _navView.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainer);
        _navView.titleLabel.textColor = ACCResourceColor(ACCUIColorConstTextPrimary);
        [_navView.leftCancelButton addTarget:self
                                      action:@selector(cancelBtnClicked:)
                            forControlEvents:UIControlEventTouchUpInside];
    }
    return _navView;
}

- (void)cancelBtnClicked:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Getter

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [_tableView registerClass:ACCASMusicCategoryTableViewCell.class forCellReuseIdentifier:[ACCASMusicCategoryTableViewCell identifier]];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.contentInset = UIEdgeInsetsMake(0, 0, 8, 0);
        _tableView.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainer);
    }
    return _tableView;
}

- (ACCASMusicCategoryManager *)manager
{
    if (!_manager) {
        _manager = [[ACCASMusicCategoryManager alloc] init];
        _manager.isCommerce = self.isCommerce;
        _manager.recordMode = self.recordMode;
        _manager.videoDuration = self.videoDuration;
    }
    return _manager;
}

#pragma mark - About Data

- (void)loadData
{
    @weakify(self);
    [self.manager fetchDataWithCompletion:^(NSArray<ACCVideoMusicCategoryModel *> *list, NSError *error) {
        @strongify(self);
        [self refreshUI];
    }];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // todo: @liyansong 切换到新的音乐歌单页面
    NSUInteger index = indexPath.row;
    if (index < [self.manager numberOfCategories]) {
        ACCVideoMusicCategoryModel *model = [self.manager categoryModel:index];
        NSString *URL = [NSString stringWithFormat:@"aweme://assmusic/category/%@?name=%@", model.idStr, model.name];
        NSDictionary *quires = @{
            @"previousPage"   : self.previousPage ?: @"",
            @"enterMethod"    : @"click_category_list",
            @"hideMore"       : @(self.shouldHideCellMoreButton),
            @"is_hot"         : @(model.isHot),
            @"record_mode"    : @(self.recordMode),
            @"video_duration" : @(self.videoDuration),
            @"disable_cut_music": @(self.disableCutMusic)
        };
        [IESAutoInline(ACCBaseServiceProvider(), ACCMusicViewBuilderProtocol) transitionWithURLString:URL appendQuires:quires completion:^(UIViewController *viewController) {
            if ([viewController conformsToProtocol:@protocol(HTSVideoAudioSupplier)]) {
                id<HTSVideoAudioSupplier> resultVC = (id<HTSVideoAudioSupplier>)viewController;
                resultVC.completion = self.completion;
                resultVC.enableClipBlock = self.enableClipBlock;
                resultVC.willClipBlock = self.willClipBlock;
            }
        }];
        [ACCTracker() trackEvent:@"enter_song_category"
                          params:@{
                              @"enter_from" : @"change_music_page",
                              @"category_name" : model.name ?: @"",
                              @"category_id" : model.idStr ?: @"",
                              @"enter_method" : @"click_category_list"
                          }];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.manager numberOfCategories];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ACCASMusicCategoryTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[ACCASMusicCategoryTableViewCell identifier] forIndexPath:indexPath];
    [cell configWithMusicCategoryModel:[self.manager categoryModel:indexPath.row]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [ACCASMusicCategoryTableViewCell recommendedHeight];
}

#pragma mark - UITableViewDelegate

@end
