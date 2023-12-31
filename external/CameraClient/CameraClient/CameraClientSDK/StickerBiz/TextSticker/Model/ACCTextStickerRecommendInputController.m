//
//  ACCTextStickerRecommendInputController.h.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/7/26.
//

#import "ACCTextStickerRecommendInputController.h"
#import "ACCTextStickerView.h"
#import "AWERepoStickerModel.h"
#import "AWERepoTrackModel.h"
#import "AWERepoContextModel.h"
#import "ACCTextStickerRecommendDataHelper.h"
#import "ACCConfigKeyDefines.h"
#import "ACCRepoActivityModel.h"

#import <CreativeKit/ACCTrackProtocol.h>

@interface ACCTextStickerRecommendInputController()

@property (nonatomic, weak) ACCTextStickerView *stickerView;
@property (nonatomic, weak) AWEVideoPublishViewModel *publishViewModel;
// Edit property
@property (nonatomic, assign) NSUInteger lastTotalLength;// 之前的总长度
@property (nonatomic, assign) NSRange lastInputRange;// 上一次输入的位置
@property (nonatomic, assign) BOOL hasReplaceStop;// 替换是否被打断
@property (nonatomic, assign) NSRange lastRecommendRange;// 上一次推荐值的range
@property (nonatomic, assign) BOOL disableSearch;// 每隔0.3s搜索一次
@property (nonatomic, copy) NSString *searchKey;// 等待搜索的值
@property (nonatomic, copy) NSString *lastSearchKey;// 上一次搜索的值
@property (nonatomic, assign) BOOL libMode;

@property (nonatomic, copy) NSDictionary *commonTrackInfo;

@end

@implementation ACCTextStickerRecommendInputController

- (instancetype)initWithStickerView:(ACCTextStickerView *)stickerView publishViewModel:(AWEVideoPublishViewModel *)publishViewModel
{
    self = [super init];
    if (self) {
        _stickerView = stickerView;
        _publishViewModel = publishViewModel;
        _hasReplaceStop = YES;
        _disableSearch = publishViewModel.repoContext.videoType == AWEVideoTypeNewYearWish;
        [self p_setup];
    }
    return self;
}

- (void)p_setup
{
    self.lastTotalLength = self.stickerView.textView.text.length;
    self.lastInputRange = NSMakeRange(self.lastTotalLength, 0);
    // 每次进入编辑态时，都加载一次
    if (!self.publishViewModel.repoSticker.textLibItems.count) {
        [ACCTextStickerRecommendDataHelper requestLibList:self.publishViewModel completion:nil];
    }
}

- (void)didSelectRecommendTitle:(NSString *)title group:(nullable NSString *)group
{
    if (!title.length) {
        return;
    }
    
    NSRange range = self.stickerView.textView.selectedRange;// 当前光标位置
    NSRange lastRecommendRange = self.lastRecommendRange;// 上次用完推荐后的光标位置
    NSString *result = self.stickerView.textView.text ? : @"";
    title = [title stringByAppendingString:@" "];// 默认需要加个空格
    
    BOOL shouldAppend = YES;// 是否为追加
    /*替换的条件: 1.开关不是强制追加 2.期间无任何手动输入 3.光标没有发生位移 4.当前不为空*/
    if (!ACCConfigBool(kConfigBool_studio_text_recommend_mode) && !self.hasReplaceStop && result.length) {
        shouldAppend = (range.location != NSMaxRange(lastRecommendRange));
    }
    
    NSMutableString *handleResult = [result mutableCopy];
    NSUInteger replaceStart = range.location;
    
    if (shouldAppend || range.length > 0) {
        // 追加
        if (range.location < handleResult.length) {
            replaceStart = range.location;
            [handleResult replaceCharactersInRange:range withString:title];
        } else {
            replaceStart = handleResult.length;
            [handleResult appendString:title];
        }
    } else {
        // 替换
        if (lastRecommendRange.location < handleResult.length) {
            replaceStart = lastRecommendRange.location;
            [handleResult replaceCharactersInRange:lastRecommendRange withString:title];
        }
    }
    
    result = [handleResult copy];
    self.lastInputRange = NSMakeRange(replaceStart + title.length, 0);
    self.lastTotalLength = result.length;
    self.lastRecommendRange = NSMakeRange(replaceStart, title.length);
    self.hasReplaceStop = NO;

    self.stickerView.textView.text = result;
    self.stickerView.textModel.content = result;
    self.stickerView.textView.selectedRange = NSMakeRange(replaceStart + title.length, 0);
    [self.stickerView updateDisplay];
    
    [self trackForEvent:@"text_trending_words_click" params:@{
        @"word_name" : title ? : @"",
        @"rec_type" : [self p_dataModeTag],
        @"copywriting_tab" : group ? : @""
    }];
}

- (void)didShowRecommendTitle:(NSString *)title group:(nullable NSString *)group
{
    [self trackForEvent:@"text_trending_words_show" params:@{
        @"word_name" : title ? : @"",
        @"rec_type" : [self p_dataModeTag],
        @"copywriting_tab" : group ? : @""
    }];
}

- (void)didSelectLibGroup:(NSString *)group
{
    [self trackForEvent:@"click_copywriting_tab" params:@{
        @"copywriting_tab" : group ? : @""
    }];
}

- (void)didExitLibPanel:(BOOL)save
{
    [self trackForEvent:save ? @"save_copywriting" : @"cancel_copywriting" params:nil];
}

- (void)didSelectKeyboardInput:(NSRange)range
{
    if ([self p_isMarked]) {
        return;
    }
    
    if (self.lastTotalLength < self.stickerView.textView.text.length) {
        // 代表有输入或者变化
        NSUInteger lastInputStart = self.lastInputRange.location;
        // 只针对增量值作搜索
        if (range.location > lastInputStart) {
            NSString *searchText = [self.stickerView.textView.text substringWithRange:NSMakeRange(lastInputStart, range.location - lastInputStart)];
            self.lastInputRange = NSMakeRange(lastInputStart, searchText.length);
            self.hasReplaceStop = YES;
            [self searchRelatedText:searchText];
        }
    } else if (range.location != NSMaxRange(self.lastInputRange)){
        // 只是光标移动
        self.lastInputRange = NSMakeRange(range.location, 0);
        if (self.stickerView.textView.text.length == 0) {
            self.lastInputRange = NSMakeRange(0, 0);
            [self.toolBar updateWithRecommendTitles:self.publishViewModel.repoSticker.directTitles];
        }
    }
    self.lastTotalLength = self.stickerView.textView.text.length;
}

- (void)searchRelatedText:(NSString *)text
{
    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (!text.length || [text containsString:@"@"] || [text containsString:@"#"]) {
        return;
    }
    
    self.searchKey = text;
    if (!self.disableSearch) {
        self.disableSearch = YES;
        @weakify(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @strongify(self);
            self.disableSearch = NO;
            if (text.length && ![self.lastSearchKey isEqualToString:self.searchKey]) {
                self.lastSearchKey = self.searchKey;
                [ACCTextStickerRecommendDataHelper requestRecommend:self.searchKey publishModel:self.publishViewModel completion:^(NSArray<ACCTextStickerRecommendItem *> *result, NSError *error) {
                    @strongify(self);
                    if (!error && result.count) {
                        [self.toolBar updateWithRecommendTitles:result];
                    }
                }];
            }
        });
    }
}

- (void)resetToContent:(NSString *)content
{
    self.stickerView.textView.text = content;
    self.stickerView.textModel.content = content;
    self.lastTotalLength = self.stickerView.textView.text.length;
    self.lastInputRange = NSMakeRange(self.lastTotalLength, 0);
}

- (void)switchInputMode:(BOOL)libMode
{
    self.libMode = libMode;
    self.hasReplaceStop = YES;
}

- (void)trackForEnterLib:(BOOL)directEnter
{
    [self trackForEvent:@"click_copywriting_entrance" params:@{
        @"enter_method" : directEnter ? @"text_canvas" : @"text_panel"
    }];
}

- (void)trackForEvent:(NSString *)event params:(NSDictionary *)params
{
    NSMutableDictionary *trackParams = [self.commonTrackInfo mutableCopy];
    if (params) {
        [trackParams addEntriesFromDictionary:params];
    }
    if (!self.libMode) {
        [trackParams removeObjectForKey:@"copywriting_tab"];
    }
    [ACCTracker() trackEvent:event params:trackParams];
}

- (BOOL)p_isMarked
{
    return (self.stickerView.textView.markedTextRange && !self.stickerView.textView.markedTextRange.isEmpty);
}

- (NSString *)p_dataModeTag
{
    if (self.libMode) {
        return @"copywriting";
    } else if (self.lastSearchKey.length) {
        return @"imagine";
    } else {
        return @"direct";
    }
}

- (NSDictionary *)commonTrackInfo
{
    if (!_commonTrackInfo && _publishViewModel) {
        NSDictionary *pubRefer = self.publishViewModel.repoTrack.referExtra;
        _commonTrackInfo = @{
            @"shoot_way" : self.publishViewModel.repoTrack.referString ? : @"",
            @"creation_id" : self.publishViewModel.repoContext.createId ? : @"",
            @"content_type" : pubRefer[@"content_type"] ? : @"",
            @"content_source" : pubRefer[@"content_source"] ? : @"",
            @"text_type" : self.fromTextMode ? @"text_mode" : @"general_mode",
            @"enter_from" : self.fromTextMode ? @"text_edit_page" : @"video_edit_page"
        };
    }
    return _commonTrackInfo;
}

@end
