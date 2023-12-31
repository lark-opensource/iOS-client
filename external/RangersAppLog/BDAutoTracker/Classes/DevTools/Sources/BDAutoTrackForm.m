//
//  BDAutoTrackForm.m
//  RangersAppLog-RangersAppLogDevTools
//
//  Created by bytedance on 6/29/22.
//

#import "BDAutoTrackForm.h"




@implementation BDAutoTrackFormElement

+ (instancetype)elementUsingBlock:(void (^ __nullable)(BDAutoTrackFormElement *))action
                      stateUpdate:(void (^ __nullable)(BDAutoTrackFormElement *))update
                     defaultTitle:(NSString *)defTitle
                     defualtValue:(id)defVal;
{
    BDAutoTrackFormElement *ele = [BDAutoTrackFormElement new];
    ele.stateUpdate = [update copy];
    ele.action = [action copy];
    ele.title = defTitle;
    ele.val = defVal;
    return ele;
}

+ (NSArray<BDAutoTrackFormElement *> *)transform:(id)collection
{
    NSMutableArray *elements = [NSMutableArray array];
    if ([collection isKindOfClass:NSDictionary.class]) {
        NSDictionary *dictTarget = (NSDictionary *)collection;
        
        [[dictTarget.allKeys sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(NSString*  _Nonnull obj1, NSString*  _Nonnull obj2) {
                    return [obj1 compare:obj2 options:(NSCaseInsensitiveSearch)];
                }] enumerateObjectsUsingBlock:^(id  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
                    [elements addObject:[[BDAutoTrackFormElement elementUsingBlock:nil stateUpdate:nil defaultTitle:key defualtValue:dictTarget[key]] enableCopy]];
                }];
        
        [dictTarget enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            
        }];
    } else if ([collection isKindOfClass:NSArray.class]) {
        NSArray *arrayTarget = (NSArray *)collection;
        [[arrayTarget sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            return [obj1 compare:obj2 options:(NSCaseInsensitiveSearch)];
        }] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [elements addObject:[[BDAutoTrackFormElement elementUsingBlock:nil stateUpdate:nil defaultTitle:@"" defualtValue:obj] enableCopy]];
        }];
    } else if ([collection isKindOfClass:NSSet.class]) {
        NSSet *setTarget = (NSSet *)collection;
        [elements addObjectsFromArray:[BDAutoTrackFormElement transform:setTarget.allObjects]];
    }
    return elements;
}

- (instancetype)enableCopy
{
    self.copyEnabled = YES;
    return self;
}

- (instancetype)displayValType
{
    self.valType = YES;
    return self;
}

- (id)cellForTable:(UITableView *)table
{
    static NSString *identifier = @"BDAutoTrackFormElement";
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.textLabel.text = self.title;
    cell.detailTextLabel.text = [self displayVal];
    
    return cell;
    
}

- (BOOL)isBoolNumber:(NSNumber *)num
{
    CFTypeID boolID = CFBooleanGetTypeID(); // the type ID of CFBoolean
    CFTypeID numID = CFGetTypeID((__bridge CFTypeRef)(num)); // the type ID of num

    return numID == boolID;
}

- (NSString *)displayVal
{
    id val = self.val;
    NSString *val_str = nil;
    NSString *val_type = NSStringFromClass([val class]);
    if ([val isKindOfClass:NSString.class]) {
        val_str =  val;
    } else if ([val isKindOfClass:NSNumber.class]) {
        if ([self isBoolNumber:val]) {
            val_str = [val boolValue] ? @"YES" : @"NO";
            val_type = @"BOOL";
        } else {
            return [val stringValue];
        }
    } else if ([val isKindOfClass:NSArray.class]) {
        return @"Array [...]";
    } else if ([val isKindOfClass:NSDictionary.class]) {
        return @"Dictionary {...}";
    }
    
    if (self.valType && val_str) {
        return [NSString stringWithFormat:@"(%@) %@", val_type, val_str];
    }
    return val_str;
}

- (NSString *)rawValue
{
    id val = self.val;
    NSString *val_str = nil;
    NSString *val_type = NSStringFromClass([val class]);
    if ([val isKindOfClass:NSString.class]) {
        val_str =  val;
    } else if ([val isKindOfClass:NSNumber.class]) {
        if ([self isBoolNumber:val]) {
            val_str = [val boolValue] ? @"YES" : @"NO";
            val_type = @"BOOL";
        } else {
            return [val stringValue];
        }
    } else if ([val isKindOfClass:NSArray.class] || [val isKindOfClass:NSDictionary.class]) {
        if ([NSJSONSerialization isValidJSONObject:val]) {
            NSData *data = [NSJSONSerialization dataWithJSONObject:val options:NSJSONWritingPrettyPrinted error:nil];
            NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            return str;
            
        } else {
            return @"Invalid JSON";
        }
    }
    
    if (self.valType && val_str) {
        return [NSString stringWithFormat:@"(%@) %@", val_type, val_str];
    }
    return val_str;
}

@end


@interface BDAutoTrackForm()<UITableViewDelegate, UITableViewDataSource> {
    
}

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation BDAutoTrackForm

- (instancetype)init
{
    if (self = [super init]) {
        if (@available(iOS 13.0, *)) {
            self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
        } else {
            self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        }
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
    }
    return self;
}

- (void)embedIn:(UIViewController *)container
{
    if (!container) {
        return;
    }
    self.container = container;
    [self.container.view addSubview:self.tableView];
    
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.container.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[table]-0-|" options:0 metrics:@{} views:@{@"table":self.tableView}]];
    [self.container.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[table]-0-|" options:0 metrics:@{} views:@{@"table":self.tableView}]];
    
}

- (void)reload
{
    [self.tableView reloadData];
}


#pragma mark - Delegate & Datasource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    BDAutoTrackFormGroup *group = [self.groups objectAtIndex:section];
    return group.title ?: @"";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.groups count];
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    BDAutoTrackFormGroup *group = [self.groups objectAtIndex:section];
    return [group.elements count];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    BDAutoTrackFormGroup *group = [self.groups objectAtIndex:indexPath.section];
    BDAutoTrackFormElement *ele = [group.elements objectAtIndex:indexPath.row];
    
    if (ele.stateUpdate) {
        ele.stateUpdate(ele);
    }
    return [ele cellForTable:tableView];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BDAutoTrackFormGroup *group = [self.groups objectAtIndex:indexPath.section];
    BDAutoTrackFormElement *ele = [group.elements objectAtIndex:indexPath.row];
    if (ele.action) {
        ele.action(ele);
    } else {
        
        if (!ele.copyEnabled) {
            return;
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:ele.title message:[ele rawValue] preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = [ele rawValue];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    
        }]];
        [self.container presentViewController:alert animated:YES completion:nil];
        
    }
}

@end





@implementation BDAutoTrackFormGroup

+ (instancetype)groupWithTitle:(NSString *)title
                      elements:(NSArray<BDAutoTrackFormElement *> *)elements
{
    BDAutoTrackFormGroup *group = [BDAutoTrackFormGroup new];
    group.title = title;
    group.elements = elements;
    return group;
}

@end
