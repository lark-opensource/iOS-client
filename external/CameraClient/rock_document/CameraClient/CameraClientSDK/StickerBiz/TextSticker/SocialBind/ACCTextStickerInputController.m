//
//  ACCTextStickerInputController.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/3/9.
//

#import "ACCTextStickerInputController.h"
#import "ACCHashTagServiceProtocol.h"
#import <CreativeKit/ACCMacros.h>
#import "ACCThrottle.h"
#import <CameraClient/ACCConfigKeyDefines.h>

NS_INLINE NSRange kNotFoundRange()
{
    return NSMakeRange(NSNotFound, 0);
}

NS_INLINE BOOL kIsNotFoundRange(NSRange range)
{
    return range.location == NSNotFound;
}

@interface ACCTextStickerInputController ()

@property (nonatomic, strong) UITextView *textView;

@property (nonatomic, copy) NSArray<ACCTextStickerExtraModel *> *mentionExtraInfos;
@property (nonatomic, copy) NSArray<ACCTextStickerExtraModel *> *hashtagExtraInfos;

@property (nonatomic, strong) NSRegularExpression *hashTagRegExp;
@property (nonatomic, strong) NSRegularExpression *endWithHashTagRegExp;

// flags
@property (nonatomic, assign) NSRange lastSearchRange;
@property (nonatomic, assign) NSRange lastMarkedRange;

@property (nonatomic, assign) NSRange lastShouldChangeTextInRange;
@property (nonatomic, copy) NSString *lastShouldChangeTextInRangeText;
@property (nonatomic, assign) NSRange lastShouldChangeTextSelectedRange;

@property (nonatomic, strong) ACCThrottle *updateSearchThrottle;

@property (nonatomic, assign) BOOL ignoreSelectionChangedFlag;

@property (nonatomic, assign) BOOL enableHashtagNewlineOptimize;

@end

#pragma mark - life cycle
@implementation ACCTextStickerInputController

- (instancetype)initWithTextView:(UITextView *)textView
                initialExtraInfos:(NSArray<ACCTextStickerExtraModel *> *)extraInfos
{
    if (self = [super init]) {
        
        NSParameterAssert(textView != nil);
        _enableHashtagNewlineOptimize = ACCConfigBool(kConfigBool_enable_text_sticke_optimize);
        _textView = textView;
        [self p_setupWithExtraInfos:extraInfos];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onTextInputValueChangedNotify:)
                                                     name:UITextViewTextDidChangeNotification
                                                   object:textView];
    }
    return self;
}

- (void)p_setupWithExtraInfos:(NSArray<ACCTextStickerExtraModel *> *)extraInfos
{
    self.lastMarkedRange = kNotFoundRange();
    self.lastShouldChangeTextInRange = kNotFoundRange();
    self.lastShouldChangeTextSelectedRange = kNotFoundRange();
    
    self.endWithHashTagRegExp = [ACCHashTagService() endWithHashTagRegExp];
    self.hashTagRegExp = [ACCHashTagService() hashTagRegExp];
    
    self.mentionExtraInfos = [ACCTextStickerExtraModel filteredValidExtrasInList:extraInfos forType:ACCTextStickerExtraTypeMention];
    
    self.hashtagExtraInfos = [ACCTextStickerExtraModel filteredValidExtrasInList:extraInfos forType:ACCTextStickerExtraTypeHashtag];
    
    @weakify(self);
    self.updateSearchThrottle = [ACCThrottle throttleWithTimeInterval:0.2 executor:^(NSDictionary * _Nullable userInfo) {
        @strongify(self);
        [self updateSearchKeywordStatus];
    }];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - text and selection change handler

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (textView != self.textView) {
        return YES;
    }
    
    BOOL isDeleteAction = (text.length == 0);
    
    // 删除的时候如果删除的是mention，先帮他Mark选中一次 避免误删除, 如果已选中那么直接删除
    if (isDeleteAction &&
        !NSEqualRanges(range, [self p_markedRange]) &&
        [self p_markMentionTextRangeIfNeedWhenProcessDeleteInRange:range]) {
        
        self.lastShouldChangeTextInRange = kNotFoundRange();
        self.lastShouldChangeTextInRangeText = nil;
        self.lastShouldChangeTextSelectedRange = kNotFoundRange();
        
        return NO;
    }
    
    // shouldChangeTextInRange回调实际上是处理的“即将发生”的状态，如果用此时的状态计算会错误
    // 所以先标记等在TextInputValueChangedNotify的时候在去计算更新
    self.lastShouldChangeTextInRange = range;
    self.lastShouldChangeTextInRangeText = text;
    self.lastShouldChangeTextSelectedRange = textView.selectedRange;
    
    return YES;
}

- (void)onTextInputValueChangedNotify:(NSNotification *)sender
{
    if (sender.object != self.textView) {
        return;
    }
    
    // 预选词需要用预选词的range去更新
    if ([self p_isMarked]) {
        
        NSRange lastMarkedRange = self.lastMarkedRange;
        NSRange currentMarkedRange = [self p_markedRange];
        if (!kIsNotFoundRange(currentMarkedRange)) {
            if (kIsNotFoundRange(lastMarkedRange)) {
                lastMarkedRange = NSMakeRange(currentMarkedRange.location, 0);
            }
            if (NSMaxRange(currentMarkedRange) > [self p_plainText].length) {
                return;
            }
            NSString *text = [[self p_plainText] substringWithRange:currentMarkedRange];
            
            // 需要注意计算 如果有已选中的字符 因为是替换关系
            NSRange replacementRange = NSMakeRange(lastMarkedRange.location, lastMarkedRange.length + self.lastShouldChangeTextSelectedRange.length);
            [self p_updateAllExtraInfoAndCallbackChangedWithReplacementRange:replacementRange replacementText:text];
        }
        
    } else {
        [self p_updateAllExtraInfoAndCallbackChangedWithReplacementRange:self.lastShouldChangeTextInRange replacementText:self.lastShouldChangeTextInRangeText];
    }

    self.lastMarkedRange = [self p_markedRange];
    self.lastShouldChangeTextInRange = kNotFoundRange();
    self.lastShouldChangeTextSelectedRange = kNotFoundRange();
    self.lastShouldChangeTextInRangeText = nil;
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    if (textView != self.textView) {
        return;
    }
    
    if (!self.ignoreSelectionChangedFlag) {
        [self.updateSearchThrottle tryExecuteWithUserInfo:nil];
    }
}

- (BOOL)p_markMentionTextRangeIfNeedWhenProcessDeleteInRange:(NSRange)range
{
    for (ACCTextStickerExtraModel *extra in self.mentionExtraInfos) {
        
        NSInteger start = extra.start;
        NSInteger end = extra.end;

        if (range.location >= start && range.location + range.length <= end) {
            if (range.location == start && range.location + range.length == end) {
                return NO;
            } else {
                UITextPosition *startPosition = [self.textView positionFromPosition:self.textView.beginningOfDocument offset:start];
                UITextPosition *endPosition = [self.textView positionFromPosition:self.textView.beginningOfDocument offset:end];
                UITextRange *selectRange = [self.textView textRangeFromPosition:startPosition toPosition:endPosition];
                if (!startPosition || !endPosition || !selectRange || selectRange.isEmpty) {
                    continue;
                }
                [self.textView setSelectedTextRange:selectRange];
                return YES;
            }
        }
    }
    
    return NO;
}

#pragma mark - append handler
- (void)appendExtraCharacterWithType:(ACCTextStickerExtraType)extraType
{
    switch (extraType) {
        case ACCTextStickerExtraTypeHashtag: {
            [self p_replaceCurrentSelectTextWithText:@"#"];
            break;
        }
        case ACCTextStickerExtraTypeMention: {
            [self p_replaceCurrentSelectTextWithText:@"@"];
            break;
        }
    }
}

- (void)appendTextExtraWithExtra:(ACCTextStickerExtraModel *)extra
{
    if (!extra.isValid) {
        return;
    }
    
    if (extra.type == ACCTextStickerExtraTypeMention) {
        [self p_appendMentionWithExtra:extra];
    } else if (extra.type == ACCTextStickerExtraTypeHashtag) {
        [self p_appendHashtagWithExtra:extra];
    }
}

- (void)p_appendMentionWithExtra:(ACCTextStickerExtraModel *)extra
{
    if (!extra.isValid) {
        return;
    }
    
    NSString *name = extra.nickname;
    NSString *textToInsert = [NSString stringWithFormat:@"@%@ ", name];
    
    @weakify(self);
    [self p_replaceText:textToInsert toRange:self.lastSearchRange textUpdatedHander:^(NSString *text, NSRange replaceRange) {
        @strongify(self);
        
        extra.start = replaceRange.location;
        extra.length = textToInsert.length - 1; // 不包含用户名后的空格
        
        NSMutableArray <ACCTextStickerExtraModel *> *tmp = [NSMutableArray arrayWithArray:self.mentionExtraInfos?:@[]];
        [tmp addObject:extra];
        self.mentionExtraInfos = [tmp copy];
    }];
    
    self.lastSearchRange = kNotFoundRange();
    [self p_handlCurrentExtraInfoDidChanged];
}

- (void)p_appendHashtagWithExtra:(ACCTextStickerExtraModel *)extra
{
    if (ACC_isEmptyString(extra.hashtagName)) {
        NSAssert(NO, @"invaild hashtag extra, check");
        return;
    }
    
    NSString *textToInsert = [extra.hashtagName stringByAppendingString:@" "];
    [self p_replaceText:textToInsert toRange:self.lastSearchRange textUpdatedHander:nil];
    self.lastSearchRange = kNotFoundRange();
}

- (void)p_replaceCurrentSelectTextWithText:(NSString *)replaceText
{
    [self p_replaceText:replaceText toRange:self.textView.selectedRange textUpdatedHander:nil];
}

- (void)p_replaceText:(NSString *)replaceString
              toRange:(NSRange)replaceRange
    textUpdatedHander:(void(^)(NSString *text, NSRange replaceRange))textUpdatedHander
{
    
    self.ignoreSelectionChangedFlag = YES;
    
    [self.textView unmarkText];
    self.lastMarkedRange = kNotFoundRange();
    
    NSRange selectedRange = self.textView.selectedRange;
    
    NSString *text = [self p_plainText];
    replaceRange = [self p_safeTextRangeWithRange:replaceRange];
    
    [self p_updateMentionExtraInfoIfNeedWithReplacementRange:replaceRange replacementText:replaceString];
    self.textView.text = [self.textView.text stringByReplacingCharactersInRange:replaceRange withString:replaceString];
    [self.textView unmarkText];
    [self p_updateHashtagExtraInfo]; //  hashtag是动态更新的 所以需要更新text后再去更新
    
    text = [self p_plainText]; // update text
    
    ACCBLOCK_INVOKE(textUpdatedHander, text, replaceRange);
    
    // 光标移到添加的文本后面
    NSRange newSelectedRange = NSMakeRange(selectedRange.location + replaceString.length - replaceRange.length, 0);
    newSelectedRange = [self p_safeTextRangeWithRange:newSelectedRange];
    [self p_setSelectedRange:newSelectedRange];
    
    [self p_handlCurrentExtraInfoDidChanged];
    
    if ([self.delegate respondsToSelector:@selector(textStickerInputController:onReplaceText:withRange:)]) {
        [self.delegate textStickerInputController:self onReplaceText:replaceString withRange:replaceRange];
    }
    
    self.ignoreSelectionChangedFlag = NO;
    [self.updateSearchThrottle tryExecuteWithUserInfo:nil];
}

#pragma mark - extra update
- (void)p_updateAllExtraInfoAndCallbackChangedWithReplacementRange:(NSRange)range
                                                 replacementText:(NSString *)text
{
    [self p_updateMentionExtraInfoIfNeedWithReplacementRange:range replacementText:text];
    [self p_updateHashtagExtraInfo];
    [self p_handlCurrentExtraInfoDidChanged];
}

- (void)p_updateMentionExtraInfoIfNeedWithReplacementRange:(NSRange)range
                                           replacementText:(NSString *)text
{
    if (kIsNotFoundRange(range)) {
        return;
    }
    
    NSMutableArray<ACCTextStickerExtraModel *> *mentionExtras = @[].mutableCopy;
    NSUInteger textLength = text.length;

    for (ACCTextStickerExtraModel *extra in self.mentionExtraInfos) {
        
        NSRange extraRange = NSMakeRange(extra.start, extra.length);
        NSRange intersection = NSIntersectionRange(extraRange, range);
        
        if (intersection.length > 0 || //交集不为空，原有@信息失效
            (range.location > extra.start && range.location + range.length < extra.start + extra.length) // 交集为空，range.length == 0, 在原有@端中插入，原有@信息失效
            ) {
            continue;
            
        } else if (extra.start >= range.location + range.length) {
            NSInteger offset = textLength - range.length;
            extra.start += offset;
            extra.end += offset;
        }
        
        [mentionExtras addObject:extra];
    }
    self.mentionExtraInfos = [mentionExtras copy];
}

- (void)p_updateHashtagExtraInfo
{
    NSArray <ACCTextStickerExtraModel *> *hashTags = [self p_resolveHashTags];
    
    if (hashTags.count <= self.maxHashtagCount) {
        self.hashtagExtraInfos = hashTags;
    } else {
        
        NSMutableArray <ACCTextStickerExtraModel *> *ret = [NSMutableArray array];
        
        NSMutableArray <ACCTextStickerExtraModel *> *sortedHashTags = [NSMutableArray arrayWithArray:[ACCTextStickerExtraModel sortedByLocationAscendingWithExtras:hashTags]?:@[]] ;
        
        // 如果已存在 优先加入
        [[sortedHashTags copy] enumerateObjectsUsingBlock:^(ACCTextStickerExtraModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            // 因为已经编辑过位置信息 所以只能用name简单判断下是否一致
            if ([self p_containEqualNameHashtagExtra:obj]) {
                [ret addObject:obj];
                [sortedHashTags removeObject:obj];
            }
        }];
        
        // 把剩下的加满为止
        [[sortedHashTags copy] enumerateObjectsUsingBlock:^(ACCTextStickerExtraModel *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if (ret.count >= self.maxHashtagCount) {
                *stop = YES;
            } else {
                [ret addObject:obj];
            }
        }];
        self.hashtagExtraInfos = [ret copy];
    }
}

- (BOOL)p_containEqualNameHashtagExtra:(ACCTextStickerExtraModel *)hashtagExtra
{
    __block BOOL ret = NO;
    [[self.hashtagExtraInfos copy] enumerateObjectsUsingBlock:^(ACCTextStickerExtraModel *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (!ACC_isEmptyString(hashtagExtra.hashtagName) &&
            [obj.hashtagName isEqualToString:hashtagExtra.hashtagName]) {
            
            ret = YES;
            *stop = YES;
        }
    }];
    
    return ret;
}

- (NSArray<ACCTextStickerExtraModel *> *)p_resolveHashTags
{
    NSString *text = [self p_plainText];
    if (ACC_isEmptyString(text)) {
        return @[];
    }
    NSArray<NSTextCheckingResult *> *matches = [self.hashTagRegExp matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    
    NSMutableArray<ACCTextStickerExtraModel *> *hashTagExtras = [NSMutableArray array];
    for (NSTextCheckingResult *result in matches) {
        if (result.numberOfRanges >= 2) {
            NSRange range = [result rangeAtIndex:1];
            ACCTextStickerExtraModel *textExtra = [ACCTextStickerExtraModel hashtagExtraWithHashtagName:[text substringWithRange:range].lowercaseString];
            textExtra.start = range.location - 1;
            textExtra.end = range.location + range.length;
            [hashTagExtras addObject:textExtra];
        }
    }
    return [hashTagExtras copy];
}

- (void)p_handlCurrentExtraInfoDidChanged
{
    if ([self.delegate respondsToSelector:@selector(textStickerInputController:onExtraInfoDidChanged:)]) {
        [self.delegate textStickerInputController:self onExtraInfoDidChanged:self.extraInfos];
    }
}

#pragma mark - keyword searching
- (void)updateSearchKeywordStatus
{
    // 选词的时候或者预选词的时候不需要更新
    if (self.textView.selectedRange.length > 0 || [self p_isMarked]) {
        return;
    }

    // 先判断#的搜索 在判断@的搜索 如果都没有 那么回调取消搜索面板
    BOOL shouldSearchHashtag = [self p_handleHashtagKeywordSearchIfMatching];
    
    // 正在预选的话不需要更新搜索@的信息
    if (!shouldSearchHashtag && ![self p_isMarked]) {
        BOOL shouldSearchMention =  [self p_handleMentionKeywordSearchIfMatching];
        if (!shouldSearchMention) {
            [self p_callbackDidUpdateSearchKeyword:nil needSearch:NO searchType:ACCTextStickerExtraTypeHashtag];
            self.lastSearchRange = kNotFoundRange();
        }
    }
}

- (BOOL)p_handleHashtagKeywordSearchIfMatching
{
    if (self.hashtagExtraInfos.count >= self.maxHashtagCount) {
        return NO;
    }
    
    // 从当前光标位置一直往前搜索的长度
    NSString *forwardString = [self.textView.text substringWithRange:NSMakeRange(0, NSMaxRange(self.textView.selectedRange))];
    
    // 删除预选词的空白
    if ([self p_isMarked]) {
        
        NSString *markedString = [self.textView textInRange:self.textView.markedTextRange];
        NSInteger prefixLength = forwardString.length - markedString.length;
        NSString *suffixString = [forwardString substringWithRange:NSMakeRange(prefixLength, markedString.length)];
        if ([suffixString isEqualToString:markedString]) {
            NSString *prefix = [forwardString substringWithRange:NSMakeRange(0, prefixLength)];
            NSString *suffix = [[suffixString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] componentsJoinedByString:@""];
            forwardString = [prefix stringByAppendingString:suffix];
        }
    }
    
    // regular未包含末字符的换行的判断，这里简单判断下即可
    if (self.enableHashtagNewlineOptimize && [forwardString hasSuffix:@"\n"]) {
        return NO;
    }

    NSTextCheckingResult *match = [self.endWithHashTagRegExp firstMatchInString:forwardString options:0 range:NSMakeRange(0, forwardString.length)];
    
    if (match && match.numberOfRanges > 1) {
        NSRange range = [match rangeAtIndex:1];
        NSString *keyword = [forwardString substringWithRange:range];
        self.lastSearchRange = range;
        [self p_callbackDidUpdateSearchKeyword:keyword needSearch:YES searchType:ACCTextStickerExtraTypeHashtag];
        return YES;
    }
    
    return NO;
}

- (BOOL)p_handleMentionKeywordSearchIfMatching
{
    if (self.mentionExtraInfos.count >= self.maxMentionCount) {
        return NO;
    }
    
    if ([self p_isMarked]) {
        return NO;
    }
    
    NSString *text = self.textView.text;
    
    NSRange selectedRange = self.textView.selectedRange;
    if (selectedRange.location > text.length) {
        return NO;
    }
    
    BOOL inExtra = NO;
    NSUInteger startLocation = 0;
    for (ACCTextStickerExtraModel *extra in self.mentionExtraInfos) {
        // 光标在有效的高亮区域内, 停止搜索
        if (extra.start < selectedRange.location && extra.end > selectedRange.location) {
            inExtra = YES;
            break;
        }
        // 寻找左侧最近的可匹配空间
        if (extra.end <= selectedRange.location && extra.end > startLocation) {
            startLocation = extra.end;
        }
    }
    
    if (inExtra ||
        selectedRange.length > 0 ||
        startLocation >= selectedRange.location) {
        return NO;
    }
    
    __block NSRange searchRange = kNotFoundRange();
    // 避让话题 空格 换行 ...
    NSSet *avoidCharSet = [NSSet setWithArray:@[@"#", @" ", @"\n", @"\t"]];
    [text enumerateSubstringsInRange:NSMakeRange(startLocation, selectedRange.location - startLocation)
                             options:NSStringEnumerationReverse | NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        if ([avoidCharSet containsObject:substring]) {
            *stop = YES;
        }
        
        // 按照需求 找到光标最近@就可以了
        if ([substring isEqualToString:@"@"]) {
            searchRange.location = substringRange.location;
            *stop = YES;
        }
    }];
    
    if (kIsNotFoundRange(searchRange)) {
        return NO;
    }
    
    searchRange.length = selectedRange.location - searchRange.location;
    
    NSString *targetKeyword = [text substringWithRange:searchRange];
    
    if ([targetKeyword hasPrefix:@"@"]) {
        targetKeyword = [targetKeyword stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
    }
    if (!kIsNotFoundRange(searchRange)) {
        self.lastSearchRange = searchRange;
        [self p_callbackDidUpdateSearchKeyword:targetKeyword needSearch:YES searchType:ACCTextStickerExtraTypeMention];
        return YES;
    }
    return NO;
}

- (void)p_callbackDidUpdateSearchKeyword:(NSString *)keyword
                              needSearch:(BOOL)needSearch
                              searchType:(ACCTextStickerExtraType)searchType
{
    if ([self.delegate respondsToSelector:@selector(textStickerInputController:didUpdateSearchStatus:Keyword:searchType:)]) {
        [self.delegate textStickerInputController:self didUpdateSearchStatus:needSearch Keyword:keyword searchType:searchType];
    }
}

#pragma mark - getter
- (NSArray<ACCTextStickerExtraModel *> *)extraInfos
{
    NSMutableArray *ret = [NSMutableArray array];
    if (!ACC_isEmptyArray(self.mentionExtraInfos)) {
        [ret addObjectsFromArray:self.mentionExtraInfos];
    }
    
    if (!ACC_isEmptyArray(self.hashtagExtraInfos)) {
        [ret addObjectsFromArray:self.hashtagExtraInfos];
    }
    
    return [ret copy];
}

- (NSInteger)numberOfExtrasForType:(ACCTextStickerExtraType)extraType
{
    switch (extraType) {
        case ACCTextStickerExtraTypeMention: {
            return self.mentionExtraInfos.count;
        }
        case ACCTextStickerExtraTypeHashtag: {
            return self.hashtagExtraInfos.count;
        }
    }
    return 0;
}

#pragma mark - util
- (UITextRange *)p_textRangeFromRange:(NSRange)range {
    
    UITextPosition *beggining = self.textView.beginningOfDocument;
    UITextPosition *start = [self.textView positionFromPosition:beggining offset:range.location];
    UITextPosition *end = [self.textView positionFromPosition:start offset:range.length];
    UITextRange *textRange = [self.textView textRangeFromPosition:start toPosition:end];
    return textRange;
}
   
- (void)p_setSelectedRange:(NSRange)range
{
    UITextRange* selectionRange = [self p_textRangeFromRange:range];
    [self.textView setSelectedTextRange:selectionRange];
}

- (NSRange)p_rangeFromTextRange:(UITextRange *)textRange {
    
    if (textRange == nil) {
        return kNotFoundRange();
    }
    UITextPosition* beginning = self.textView.beginningOfDocument;
    UITextPosition* start = textRange.start;
    UITextPosition* end = textRange.end;
    NSInteger location = [self.textView offsetFromPosition:beginning toPosition:start];
    NSInteger length = [self.textView offsetFromPosition:start toPosition:end];
    return NSMakeRange(location, length);
}

- (NSRange)p_safeTextRangeWithRange:(NSRange)range
{
    NSString *text = [self p_plainText];
    if (range.location > text.length || range.location + range.length > text.length) {
       return self.textView.selectedRange;
    }
    
    return range;
}

- (BOOL)p_isMarked
{
    return (self.textView.markedTextRange && !self.textView.markedTextRange.isEmpty);
}

- (NSRange)p_markedRange
{
    if (![self p_isMarked]) {
        return kNotFoundRange();
    }
    return [self p_rangeFromTextRange:self.textView.markedTextRange];
}

- (NSString *)p_plainText
{
    return self.textView.text;
}

@end
