//
//  BDAutoTrackDevLogger.m
//  RangersAppLog-RangersAppLogDevTools
//
//  Created by bytedance on 6/28/22.
//

#import "BDAutoTrackDevLogger.h"
#import "BDAutoTrackLoggerCell.h"
#import "BDAutoTrackDropDownLabel.h"
#import "BDAutoTrackVisualLogger.h"
#import "BDAutoTrackInspector.h"
#import "BDAutoTrack+Private.h"
#import "RangersLogManager.h"
#import "BDAutoTrackDevToolsHolder.h"

@interface BDAutoTrackDevLogger ()<UITableViewDelegate, UITableViewDataSource,UITextFieldDelegate> {
    
    dispatch_queue_t    _timerQueue;
    void*               _timerQueueKey;
    dispatch_source_t   _timer;
    
    UIView *settingsView;
    
    BDAutoTrackDropDownLabel *levelLabel;
    BDAutoTrackDropDownLabel *moduleLabel;
    
    UIView *searchView;
    UITextField *searchTextField;
    
    UISwitch *autoScrollSwitch;
    
    
    
    UITableView *logsTable;
    
    
   
    NSArray *existsModules;
}

@property (nonatomic, weak) BDAutoTrackVisualLogger *visualLogger;

@property (nonatomic, copy) NSString        *filterModule;
@property (nonatomic, assign) VETLOG_LEVEL  filterLevel;
@property (nonatomic, copy) NSString        *filterKeyword;

@property (nonatomic, strong) NSArray<RangersLogObject *> *filteredLogs;

@end

@implementation BDAutoTrackDevLogger

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    _timerQueue = dispatch_queue_create([@"dev.logger.timer" UTF8String], DISPATCH_QUEUE_SERIAL);
    _timerQueueKey = &_timerQueueKey;
    void *nonNullUnusedPointer = (__bridge void *)self;
    dispatch_queue_set_specific(_timerQueue, _timerQueueKey, nonNullUnusedPointer, NULL);
    
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view.
    BDAutoTrack *track = self.inspector.currentTracker;
    [[track.logger loggers] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:BDAutoTrackVisualLogger.class]) {
            self.visualLogger = obj;
        }
    }];
    self.filterModule = @"ALL";
    self.filterLevel = VETLOG_LEVEL_DEBUG;
    [self updateExistsModules];
    [self layoutUI];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self startTimer];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self stopTimer];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}


#pragma mark - Logs

- (void)startTimer
{
    if (!_timer) {
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _timerQueue);
        dispatch_source_set_event_handler(_timer, ^{
            [self reloadLogs];
        });
        dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW,  1.0f * NSEC_PER_SEC, 1 * NSEC_PER_SEC);
        dispatch_resume(_timer);
    }
}

- (void)stopTimer
{
    if (_timer) {
        dispatch_source_cancel(_timer);
        _timer = NULL;
    }
}



- (void)reloadLogs
{
    dispatch_block_t block = ^{
        
        NSArray *logs = [self.visualLogger currentLogs];
        
        NSPredicate * moduleFilter = [NSPredicate predicateWithFormat:@"module = %@",self.filterModule];
        if (![@"ALL" isEqualToString:self.filterModule?:@""]) {
            logs = [logs filteredArrayUsingPredicate:moduleFilter];
        }
        if (self.filterLevel != VETLOG_LEVEL_DEBUG) {
            NSPredicate * levelFilter;
            switch (self.filterLevel) {
                case VETLOG_LEVEL_ERROR: {
                    levelFilter = [NSPredicate predicateWithFormat:@"flag in (%@)",@[@(VETLOG_FLAG_ERROR)]];
                    break;
                }
                case VETLOG_LEVEL_WARN: {
                    levelFilter = [NSPredicate predicateWithFormat:@"flag in (%@)",@[@(VETLOG_FLAG_ERROR),@(VETLOG_FLAG_WARN)]];
                    break;
                }
                default:
                    levelFilter = [NSPredicate predicateWithFormat:@"flag in (%@)",@[@(VETLOG_FLAG_ERROR),@(VETLOG_FLAG_WARN),@(VETLOG_FLAG_INFO)]];
                    break;
            }
            logs = [logs filteredArrayUsingPredicate:levelFilter];
        }
        
        if (self.filterKeyword.length > 0) {
            NSPredicate * keywordFilter = [NSPredicate predicateWithFormat:@"message CONTAINS[cd] %@",self.filterKeyword];
            logs = [logs filteredArrayUsingPredicate:keywordFilter];
        }
    
        dispatch_async(dispatch_get_main_queue(), ^{
            self.filteredLogs = logs;
            [self->logsTable reloadData];
            if (self->autoScrollSwitch.on) {
                [self scrollToBottom];
            }
        });
        
    };
    
    if (dispatch_get_specific(_timerQueueKey)){
        block();
    }
    else{
        dispatch_async(_timerQueue, block);
    }
}

- (void)scrollToBottom
{
    if ([[self filteredMessageLogs] count] > 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:([[self filteredMessageLogs] count] - 1) inSection:0];
        [self->logsTable scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    }
}

#pragma mark - layout

- (CGFloat)safeTop
{
    if (self.navigationController.navigationBar) {
        return CGRectGetHeight(self.navigationController.navigationBar.bounds);
    }
    return 0.0f;
}

- (CGFloat)safeBottom
{
    if (self.tabBarController.tabBar) {
        return CGRectGetHeight(self.tabBarController.tabBar.bounds);
    }
    return 0.0f;
}

#pragma mark - UI


- (void)layoutUI
{
    [self settingsView];
    [self searchView];
    [self logsTable];
    
    searchView.layer.shadowColor = [UIColor blackColor].CGColor;
    searchView.layer.shadowRadius = 2.0f;
    searchView.layer.shadowOffset = CGSizeMake(2.0f, 2.0f);
    searchView.layer.shadowOpacity = 0.2f;
     
    [self.view addSubview:logsTable];
    [self.view addSubview:settingsView];
    [self.view addSubview:searchView];
    
    
    settingsView.translatesAutoresizingMaskIntoConstraints = NO;
    searchView.translatesAutoresizingMaskIntoConstraints = NO;
    logsTable.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[settings]-0-|" options:0 metrics:@{} views:@{@"settings":settingsView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[search]-0-|" options:0 metrics:@{} views:@{@"search":searchView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[table]-0-|" options:0 metrics:@{} views:@{@"table":logsTable}]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-top-[settings(44)]-0-[search(52)]-0-[table]-bottom-|" options:0 metrics:@{@"top":@([self safeTop]),@"bottom":@([self safeBottom])} views:@{@"table":logsTable,@"settings":settingsView,@"search":searchView}]];
    
}


- (UITableView *)logsTable
{
    if (logsTable) {
        return logsTable;
    }
    logsTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    logsTable.delegate = self;
    logsTable.dataSource = self;
    return logsTable;
}

- (UIView *)settingsView
{
    if (settingsView) {
        return settingsView;
    }
    settingsView = [[UIView alloc] init];
    
    levelLabel = [BDAutoTrackDropDownLabel new];
    levelLabel.delegate = self;
    
    moduleLabel = [BDAutoTrackDropDownLabel new];
    moduleLabel.delegate = self;
    
    [settingsView addSubview:levelLabel];
    [settingsView addSubview:moduleLabel];
    
    autoScrollSwitch = [UISwitch new];
    autoScrollSwitch.on = NO;
    [settingsView addSubview:autoScrollSwitch];
    
    levelLabel.translatesAutoresizingMaskIntoConstraints = NO;
    moduleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    autoScrollSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    
    [settingsView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[level]-[module(level)]-[switch(60)]-|"
                                                                         options:0
                                                                         metrics:@{}
                                                                           views:@{@"level": levelLabel,
                                                                                   @"module": moduleLabel,
                                                                                   @"switch": autoScrollSwitch
                                                                                 }]];
    [settingsView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-4-[level]-4-|"
                                                                         options:0
                                                                         metrics:@{}
                                                                           views:@{@"level": levelLabel}]];
    [settingsView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-4-[module]-4-|"
                                                                         options:0
                                                                         metrics:@{}
                                                                           views:@{@"module": moduleLabel}]];
    
    [settingsView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[switch]-|"
                                                                         options:0
                                                                         metrics:@{}
                                                                           views:@{@"switch": autoScrollSwitch}]];
    
    
    
    
    return settingsView;
}

- (UIView *)searchView
{
    if (searchView) {
        return searchView;
    }
    searchView = [[UIView alloc] init];
    
    searchTextField = [[UITextField alloc] init];
    
    searchTextField.borderStyle = UITextBorderStyleRoundedRect;
    searchTextField.placeholder = @"Enter your keywords ...";
    searchTextField.font = [UIFont systemFontOfSize:14.0f weight:UIFontWeightRegular];
    searchTextField.textAlignment = NSTextAlignmentCenter;
    searchTextField.delegate = self;
    
    [searchView addSubview:searchTextField];
    searchTextField.translatesAutoresizingMaskIntoConstraints = NO;
    
    [searchView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[text]-|" options:0 metrics:@{} views:@{@"text":searchTextField}]];
    [searchView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[text]-|" options:0 metrics:@{} views:@{@"text":searchTextField}]];
    
    return searchView;
}


#pragma mark - TextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    self.filterKeyword = textField.text;
    [self reloadLogs];
    [textField resignFirstResponder];
    
    BDAutoTrackDevToolsMonitor *monitor = [BDAutoTrackDevToolsHolder shared].monitor;
    [monitor track:kBDAutoTrackDevToolsSearchLog value:self.filterKeyword];
    return YES;
}

#pragma mark - UITableViewDelegate & UITableViewDatasource

- (NSArray<RangersLogObject *> *)filteredMessageLogs
{
    return self.filteredLogs;
}


- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    static NSString *loggerReuseId = @"bdautotracker_dev_logger";
    BDAutoTrackLoggerCell *cell = [tableView dequeueReusableCellWithIdentifier:loggerReuseId];
    if (!cell) {
        cell = [[BDAutoTrackLoggerCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:loggerReuseId];
    }
    RangersLogObject *log = [[self filteredMessageLogs] objectAtIndex:indexPath.row];
    cell.log = log;
    [cell update];
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self filteredMessageLogs] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RangersLogObject *log = [[self filteredMessageLogs] objectAtIndex:indexPath.row];
    return [BDAutoTrackLoggerCell estimateHeight:log];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RangersLogObject *log = [[self filteredMessageLogs] objectAtIndex:indexPath.row];
    return [BDAutoTrackLoggerCell estimateHeight:log];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    RangersLogObject *log = [[self filteredMessageLogs] objectAtIndex:indexPath.row];
    BDAutoTrackDevToolsMonitor *monitor = [BDAutoTrackDevToolsHolder shared].monitor;
    NSMutableDictionary *params = [NSMutableDictionary new];
    [params setValue:log.message forKey:@"log"];
    [monitor track:kBDAutoTrackDevToolsClickLog params:params];
}

#pragma mark - dropdown delegate

- (void)updateExistsModules
{
    NSMutableArray *modules = [[[self.visualLogger currentModules] sortedArrayWithOptions:0 usingComparator:^NSComparisonResult(NSString*  _Nonnull obj1, NSString*  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }] mutableCopy];
    [modules insertObject:@"ALL" atIndex:0];
    existsModules = [modules copy];
}

- (NSUInteger)numbersOfdropDownItems:(id)label
{
    if (label == levelLabel) {
        return 4;
    } else if (label == moduleLabel) {
        [self updateExistsModules];
        return [existsModules count];
    }
    return 0;
}


- (NSString *)dropDownLabel:(id)label selectedIndex:(NSUInteger)index
{
    if (label == moduleLabel) {
        return [existsModules objectAtIndex:index];
    } else if (label == levelLabel){
        switch (index) {
            case 0:
                return @"DEBUG";
            case 1:
                return @"INFO";
            case 2:
                return @"WARN";
            default:
                return @"ERROR";
        }
    }
    return @"";
}

- (void)dropDownLabelDidUpdate:(id)label
{
    if (label == moduleLabel) {
        self.filterModule = [existsModules objectAtIndex:moduleLabel.selectedIndex];
    } else if (label == levelLabel) {
        switch (levelLabel.selectedIndex) {
            case 0:
                self.filterLevel = VETLOG_LEVEL_DEBUG;
                break;
            case 1:
                self.filterLevel = VETLOG_LEVEL_INFO;
                break;
            case 2:
                self.filterLevel = VETLOG_LEVEL_WARN;
                break;
            default:
                self.filterLevel = VETLOG_LEVEL_ERROR;
        }
    }
    [self reloadLogs];
}


@end
