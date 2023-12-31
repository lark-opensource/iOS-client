//
//  TTKitchenSearchHistoryView.m
//  TTKitchen
//
//  Created by zhanghuipei on 2021/6/9.
//

#import "TTKitchenSearchHistoryView.h"
#import <MMKV/MMKV.h>

static NSString *kSearchHistoryIdentify = @"TTKitchenSettingsSearchHistoryRecord";
static NSString *kTTKitchenSearchHistoryViewCell = @"TTKitchenSearchHistoryViewCell";
static NSUInteger const kTableViewCellHeight = 30;

@interface TTKitchenSearchHistoryView() <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray<NSString *> *searchHistoryRecords;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation TTKitchenSearchHistoryView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        _searchHistoryRecords = [[MMKV defaultMMKV] getObjectOfClass:[NSArray class] forKey:kSearchHistoryIdentify];
        [self addSubview:self.tableView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.tableView.frame = self.bounds;
}

- (void)showInView:(UIView *)parent {
    if ([parent.subviews containsObject:self]) {//historyview是否在browserview中
        return;
    }
    
    [parent addSubview:self];
    
    self.frame = CGRectMake(0, self.frame.origin.y, self.frame.size.width, self.searchHistoryRecords.count * kTableViewCellHeight);
}

- (void)removeSearchHistoryViewFromSuperview {
    [self removeFromSuperview];
}

#define MAX_SEARCH_KEYWORD_COUNT 5 // 搜索记录的最大数量

- (void)saveSearchKeyword:(NSString *)keyword {
    if (keyword == nil || keyword.length == 0) {
        return;
    }
    
    NSMutableArray<NSString *> *searchRecordsM = self.searchHistoryRecords.mutableCopy;
    if (searchRecordsM == nil) {
        searchRecordsM = [[NSMutableArray alloc] init];
    }
    
    if ([keyword isEqualToString:searchRecordsM.firstObject] == YES) {
        return;
    }
    
    if ([searchRecordsM containsObject:keyword]) {//在搜索历史里面
        [searchRecordsM removeObject:keyword];
        [searchRecordsM insertObject:keyword atIndex:0];
        [[MMKV defaultMMKV] setObject:searchRecordsM forKey:kSearchHistoryIdentify];
        self.searchHistoryRecords = searchRecordsM.copy;
        [self updateUI];
        return;
    }
    
    if (searchRecordsM.count >= MAX_SEARCH_KEYWORD_COUNT) {
        [searchRecordsM removeObjectAtIndex:MAX_SEARCH_KEYWORD_COUNT - 1];
    }
    
    [searchRecordsM insertObject:keyword atIndex:0];
    [[MMKV defaultMMKV] setObject:searchRecordsM forKey:kSearchHistoryIdentify];
    self.searchHistoryRecords = searchRecordsM.copy;
    [self updateUI];
}

- (void)updateUI {
    self.frame = CGRectMake(0,
                            self.frame.origin.y,
                            self.frame.size.width,
                            self.searchHistoryRecords.count * kTableViewCellHeight);
    [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate && UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.searchHistoryRecords.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kTableViewCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *searchKey = [self.searchHistoryRecords objectAtIndex:indexPath.row];
    if ([self.delegate respondsToSelector:@selector(searchHistoryView:didClickHistoryButton:)]) {
        [self.delegate searchHistoryView:self didClickHistoryButton:searchKey];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *searchKey = [self.searchHistoryRecords objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTTKitchenSearchHistoryViewCell];
    cell.textLabel.text = searchKey;
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    return cell;
}

#pragma mark - setter & getter

- (UITableView *)tableView {
    if (_tableView == nil) {
        _tableView = [[UITableView alloc] init];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = UIColor.clearColor;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kTTKitchenSearchHistoryViewCell];
    }
    return _tableView;
}

@end
