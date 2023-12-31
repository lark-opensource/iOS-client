//
//  BDAutoTrackDevEventController.m
//  RangersAppLog-RangersAppLogDevTools
//
//  Created by bytedance on 2022/10/27.
//

#import <Foundation/Foundation.h>
#import "BDAutoTrackDevEvent.h"
#import "UIView+Toast.h"
#import "BDAutoTrackDropDownLabel.h"
#import "BDAutoTrackDevEventCell.h"
#import "BDAutoTrackDevToolsHolder.h"
#import "BDAutoTrackDevEventController.h"

@interface BDAutoTrackDevEventController()<UITableViewDelegate, UITableViewDataSource,UITextFieldDelegate> {
    UIView *settingsView;
    
    BDAutoTrackDropDownLabel *statusLabel;
    BDAutoTrackDropDownLabel *typeLabel;
    
    UIView *searchView;
    UITextField *searchTextField;
    
    UITableView *eventTable;
}

@property (nonatomic, strong) BDAutoTrackDevEvent *eventManager;

@property (nonatomic, strong) NSArray *statusList;
@property (nonatomic, strong) NSArray *typeList;

@property (nonatomic, assign) NSInteger type;
@property (nonatomic, assign) NSInteger status;
@property (nonatomic, copy) NSString *filterKeyword;

@property (nonatomic, strong) NSArray<BDAutoTrackDevEventData *> *eventList;

@end

@implementation BDAutoTrackDevEventController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.statusList = @[
        @(-1),
        @(BDAutoTrackEventStatusCreated),
        @(BDAutoTrackEventStatusSaved),
        @(BDAutoTrackEventStatusReported),
        @(BDAutoTrackEventStatusSaveFailed),
    ];
    
    self.typeList = @[
        @(-1),
        @(BDAutoTrackEventAllTypeLaunch),
        @(BDAutoTrackEventAllTypeTerminate),
        @(BDAutoTrackEventAllTypeProfile),
        @(BDAutoTrackEventAllTypeEventV3),
        @(BDAutoTrackEventAllTypeUIEvent),
    ];
    
    self.status = -1;
    self.type = -1;
    self.eventManager = [BDAutoTrackDevEvent shared];
    self.eventList = [self.eventManager list];
//    NSLog(@"didload >>> size: %lu", self.eventList.count);
    
    __weak BDAutoTrackDevEventController *_self = self;
    [self.eventManager setEventAddBlock:^(BDAutoTrackDevEventData *event) {
        if (_self) {
            [_self search];
        }
    }];
    [self.eventManager setEventChangeBlock:^(BDAutoTrackDevEventData *event) {
//        NSLog(@"trigger event change >>> %@ %@", event.name, event.statusStrList.lastObject);
        if (_self) {
            BDAutoTrackDevEventController *s_self = _self;
            [s_self->eventTable reloadData];
        }
    }];
    
    [[BDAutoTrackDevToolsHolder shared] setTrackerChangeBlock:^(BDAutoTrack *tracker) {
        if (_self) {
            _self.status = -1;
            _self.type = -1;
            _self.eventList = [_self.eventManager list];
            BDAutoTrackDevEventController *s_self = _self;
            [s_self->eventTable reloadData];
        }
    }];
    
    [self layoutUI];
}

- (void)search {
    self.eventList = [self.eventManager search:self.filterKeyword type:self.type status:self.status];
//    NSLog(@"search: type -> %ld >>> %ld", self.type, self.eventList.count);
    [eventTable reloadData];
}

#pragma mark - layout

- (CGFloat)safeTop {
    if (self.navigationController.navigationBar) {
        return CGRectGetHeight(self.navigationController.navigationBar.bounds);
    }
    return 0.0f;
}

- (CGFloat)safeBottom {
    if (self.tabBarController.tabBar) {
        return CGRectGetHeight(self.tabBarController.tabBar.bounds);
    }
    return 0.0f;
}

- (void)layoutUI {
    [self settingsView];
    [self searchView];
    [self eventTable];
    
    searchView.layer.shadowColor = [UIColor blackColor].CGColor;
    searchView.layer.shadowRadius = 2.0f;
    searchView.layer.shadowOffset = CGSizeMake(2.0f, 2.0f);
    searchView.layer.shadowOpacity = 0.2f;
     
    [self.view addSubview:eventTable];
    [self.view addSubview:settingsView];
    [self.view addSubview:searchView];
    
    settingsView.translatesAutoresizingMaskIntoConstraints = NO;
    searchView.translatesAutoresizingMaskIntoConstraints = NO;
    eventTable.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[settings]-0-|" options:0 metrics:@{} views:@{@"settings":settingsView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[search]-0-|" options:0 metrics:@{} views:@{@"search":searchView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[table]-0-|" options:0 metrics:@{} views:@{@"table":eventTable}]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-top-[settings(44)]-0-[search(52)]-0-[table]-bottom-|" options:0 metrics:@{@"top":@([self safeTop]),@"bottom":@([self safeBottom])} views:@{@"table":eventTable,@"settings":settingsView,@"search":searchView}]];
}

- (UIView *)settingsView {
    if (settingsView) {
        return settingsView;
    }
    settingsView = [[UIView alloc] init];
    
    statusLabel = [BDAutoTrackDropDownLabel new];
    statusLabel.delegate = self;
    
    typeLabel = [BDAutoTrackDropDownLabel new];
    typeLabel.delegate = self;
    
    [settingsView addSubview:statusLabel];
    [settingsView addSubview:typeLabel];
    
    statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    typeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [settingsView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[status]-[type(status)]-|"
                                                                         options:0
                                                                         metrics:@{}
                                                                           views:@{@"status": statusLabel,
                                                                                   @"type": typeLabel
                                                                                 }]];
    [settingsView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-4-[status]-4-|"
                                                                         options:0
                                                                         metrics:@{}
                                                                           views:@{@"status": statusLabel}]];
    [settingsView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-4-[type]-4-|"
                                                                         options:0
                                                                         metrics:@{}
                                                                           views:@{@"type": typeLabel}]];
    
    return settingsView;
}

- (UIView *)searchView {
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

- (UITableView *)eventTable {
    if (eventTable) {
        return eventTable;
    }
    eventTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    eventTable.delegate = self;
    eventTable.dataSource = self;
    return eventTable;
}

#pragma mark - TextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    self.filterKeyword = textField.text;
    [self search];
    [textField resignFirstResponder];
    
    BDAutoTrackDevToolsMonitor *monitor = [BDAutoTrackDevToolsHolder shared].monitor;
    [monitor track:kBDAutoTrackDevToolsSearchEvent value:self.filterKeyword];
    return YES;
}

#pragma mark - UITableViewDelegate & UITableViewDatasource

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    static NSString *loggerReuseId = @"bdautotracker_dev_event";
    BDAutoTrackDevEventCell *cell = [tableView dequeueReusableCellWithIdentifier:loggerReuseId];
    if (!cell) {
        cell = [[BDAutoTrackDevEventCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:loggerReuseId];
    }
    BDAutoTrackDevEventData *event = [self.eventList objectAtIndex:indexPath.row];
    cell.event = event;
    [cell update];
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.eventList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    BDAutoTrackDevEventData *event = [self.eventList objectAtIndex:indexPath.row];
    return [BDAutoTrackDevEventCell estimateHeight:event];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    BDAutoTrackDevEventData *event = [self.eventList objectAtIndex:indexPath.row];
    return [BDAutoTrackDevEventCell estimateHeight:event];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    BDAutoTrackDevEventData *event = [self.eventList objectAtIndex:indexPath.row];
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.alignment = NSTextAlignmentLeft;
    NSMutableAttributedString *message = [[NSMutableAttributedString alloc] initWithString:event.propertiesJson attributes:@{
        NSParagraphStyleAttributeName: paragraph,
        NSFontAttributeName: [UIFont systemFontOfSize:12.0f weight:UIFontWeightRegular],
        NSForegroundColorAttributeName: [UIColor blackColor],
    }];
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"详细信息"
                                   message:@""
                                   preferredStyle:UIAlertControllerStyleAlert];
    [alert setValue:message forKey:@"attributedMessage"];

    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"复制" style:UIAlertActionStyleDefault
       handler:^(UIAlertAction * action) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = event.propertiesJson;
        
        UIWindow *window = [[[UIApplication sharedApplication] windows] firstObject];
        [window bd_makeToast:@"已复制到剪贴板" duration:[BDCSToastManager defaultDuration] position:BDCSToastPositionCenter];
    }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel
       handler:^(UIAlertAction * action) {}];

    [alert addAction:defaultAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
    
    BDAutoTrackDevToolsMonitor *monitor = [BDAutoTrackDevToolsHolder shared].monitor;
    NSMutableDictionary *params = [NSMutableDictionary new];
    [params setValue:event.name forKey:@"event"];
    [monitor track:kBDAutoTrackDevToolsClickEvent params:params];
}

#pragma mark - dropdown delegate

- (NSUInteger)numbersOfdropDownItems:(id)label {
    if (label == statusLabel) {
        return self.statusList.count;
    } else if (label == typeLabel) {
        return self.typeList.count;
    }
    return 0;
}


- (NSString *)dropDownLabel:(id)label selectedIndex:(NSUInteger)index {
    if (label == statusLabel) {
        NSInteger status = [[self.statusList objectAtIndex:index] intValue];
        if (status == -1) {
            return @"ALL";
        }
        return [BDAutoTrackDevEventData status2String:status];
    } else if (label == typeLabel){
        NSInteger type = [[self.typeList objectAtIndex:index] intValue];
        if (type == -1) {
            return @"ALL";
        }
        return [BDAutoTrackDevEventData type2String:type];
    }
    return @"";
}

- (void)dropDownLabelDidUpdate:(id)label {
    if (label == typeLabel) {
        self.type = [[self.typeList objectAtIndex:typeLabel.selectedIndex] intValue];
    } else if (label == statusLabel) {
        self.status = [[self.statusList objectAtIndex:statusLabel.selectedIndex] intValue];
    }
    [self search];
}


@end
