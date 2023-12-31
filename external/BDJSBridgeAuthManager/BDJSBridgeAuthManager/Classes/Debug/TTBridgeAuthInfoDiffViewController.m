//
//  TTBridgeAuthInfoDiffViewController.m
//  TTBridgeUnify
//
//  Created by liujinxing on 2020/8/21.
//

#import "TTBridgeAuthInfoDiffViewController.h"

#pragma mark - TTBridgeAuthInfoDiffCellItem

@interface TTBridgeAuthInfoDiffCellItem ()

@property (nonatomic, assign) TTBridgeAuthInfoDiffStatus status;

@end

@implementation TTBridgeAuthInfoDiffCellItem

- (instancetype)initWithChannelName:(NSString *)channelName domainName:(NSString *)domainName status:(NSNumber *)status target:(id)target action:(__nullable SEL)action{
    self = [super initWithChannelName:channelName domainName:domainName target:target action:action];
    if (self){
        _status = status.integerValue;
    }
    if(_status == TTBridgeAuthInfoNewAdded){
        self.title = [NSString stringWithFormat:@" %@ (Added)",self.domainName];
    }
    else if(_status == TTBridgeAuthInfoDeleted){
        self.title = [NSString stringWithFormat:@" %@ (Deleted)",self.domainName];
    }
    else{
        self.title = [NSString stringWithFormat:@" %@ (Updated)",self.domainName];
    }
    return self;
}

@end

#pragma mark - TTBridgeAuthInfoDiffDetailViewController

@interface TTBridgeAuthInfoDiffDetailViewController : UIViewController

@property(nonatomic, strong) UILabel *label;
@property(nonatomic, strong) STDebugTextView *textView;
@property(nonatomic, strong) STDebugTextView *comparedTextView;
@property(nonatomic, strong) UILabel *comparedLabel;
@property(nonatomic, strong) NSMutableArray<NSDictionary *> *authInfos;
@property(nonatomic, strong) NSMutableArray<NSDictionary *> *comparedAuthInfos;

- (instancetype)initWithDomain:(NSString *)domain authInfo:(NSArray<NSDictionary *> *)authInfo comparedAuthInfos:(NSArray<NSDictionary *> *)comparedAuthInfo;

@end

@implementation TTBridgeAuthInfoDiffDetailViewController

- (instancetype)initWithDomain:(NSString *)domain authInfo:(NSArray<NSDictionary *> *)authInfo comparedAuthInfos:(NSArray<NSDictionary *> *)comparedAuthInfo{
    self = [super init];
    if (self){
        _authInfos = [NSMutableArray arrayWithArray:authInfo];
        _comparedAuthInfos = [NSMutableArray arrayWithArray:comparedAuthInfo];
        self.title = domain;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.label];
    [self.view addSubview:self.textView];
    [self.view addSubview:self.comparedLabel];
    [self.view addSubview:self.comparedTextView];
}

- (UILabel *)label{
    if(!_label){
        CGFloat x = 0;
        CGFloat y = 44.f + [UIApplication sharedApplication].statusBarFrame.size.height;
        CGFloat witdh = self.view.frame.size.width;
        CGFloat height = 40;
        _label = [[UILabel alloc]initWithFrame:CGRectMake(x, y, witdh, height)];
        _label.text = @"Inner Gecko Piper AllowList";
        _label.backgroundColor = [UIColor whiteColor];
    }
    return _label;
}

- (STDebugTextView *)textView{
    if (!_textView){
        CGFloat x = 0;
        CGFloat y = self.label.frame.origin.y + self.label.frame.size.height;
        CGFloat witdh = self.view.bounds.size.width;
        CGFloat height = self.view.bounds.size.height / 2 - y;
        _textView = [[STDebugTextView alloc] initWithFrame:CGRectMake(x, y, witdh, height)];
        _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.authInfos enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull authInfo, NSUInteger idx, BOOL * _Nonnull stop) {
            [_textView appendText:[authInfo readableString]];
        }];
        [_textView setContentOffset:CGPointZero animated:NO];
    }
    return _textView;
}

- (UILabel *)comparedLabel{
    if (!_comparedLabel){
        CGFloat x = 0;
        CGFloat y = self.view.frame.size.height / 2;
        CGFloat width = self.view.frame.size.width;
        CGFloat heigit = 40;
        _comparedLabel = [[UILabel alloc]initWithFrame:CGRectMake(x, y, width, heigit)];
        _comparedLabel.text = @"Online Gecko Piper AllowList";
        _comparedLabel.backgroundColor = [UIColor whiteColor];
    }
    return _comparedLabel;
}

- (STDebugTextView *)comparedTextView{
    if (!_comparedTextView){
        CGFloat x = 0;
        CGFloat y = self.comparedLabel.frame.origin.y + self.comparedLabel.frame.size.height;
        CGFloat width = self.view.frame.size.width;
        CGFloat heigit = self.view.frame.size.height / 2 - 40;
        _comparedTextView = [[STDebugTextView alloc] initWithFrame:CGRectMake(x, y, width, heigit)];
        _comparedTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.comparedAuthInfos enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull authInfo, NSUInteger idx, BOOL * _Nonnull stop) {
            [_comparedTextView appendText:[authInfo readableString]];
        }];
        [_comparedTextView setContentOffset:CGPointZero animated:NO];
    }
    return _comparedTextView;
}

@end

#pragma mark - TTBridgeAuthInfoDiffViewController

@interface TTBridgeAuthInfoDiffViewController ()

@property (nonatomic, copy) NSString *accessKey;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary <NSString *, NSNumber *>*> *diffChannels;

@property (nonatomic, copy) NSDictionary *comparedJson;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary *> *comparedChannels;

@end

@implementation TTBridgeAuthInfoDiffViewController

- (instancetype)initWithTitle:(NSString *)title JSON:(NSDictionary *)json ComparedJSON:(NSDictionary *)comparedJson accessKey:(NSString *)accessKey{
    self = [super initWithTitle:title JSON:json accessKey:accessKey];
    if (self){
        _comparedJson = comparedJson.copy;
        _accessKey = accessKey;
    }
    return self;
}

- (void)loadDataSource{
    NSMutableArray *dataSource = [NSMutableArray array];
    [self.diffChannels enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull channelName, NSDictionary<NSString *,NSNumber *> * _Nonnull domains, BOOL * _Nonnull stop) {
        NSMutableArray <TTBridgeAuthInfoDiffCellItem *> *itemArray = NSMutableArray.new;
        [domains enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull domainName, NSNumber * _Nonnull status, BOOL * _Nonnull stop) {
            TTBridgeAuthInfoDiffCellItem * cellItem = [[TTBridgeAuthInfoDiffCellItem alloc]initWithChannelName:channelName domainName:domainName status:status target:self action:@selector(showDomainAuthRuleDiffs:)];
            [itemArray addObject:cellItem];
        }];
        NSString *sectionTitle = [channelName stringByAppendingFormat:@" (%lu items)",(unsigned long)[itemArray count]];
        STTableViewSectionItem *sectionItem = [[STTableViewSectionItem alloc]initWithSectionTitle:sectionTitle items:itemArray];
        [dataSource addObject:sectionItem];
    }];
    self.dataSource = dataSource;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    __block BOOL noDiff = YES;
    [self.diffChannels enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull channelName, NSDictionary<NSString *,NSNumber *> * _Nonnull domains, BOOL * _Nonnull stop) {
        if ([domains count] != 0){
            noDiff = NO;
            *stop = YES;
        }
    }];
    if (noDiff){
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Information" message:@"Online Gecko Piper AllowList is same with inner ones." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:true completion:nil];
    }
}

- (NSMutableDictionary<NSString *, NSDictionary <NSString *, NSNumber *> *> *)diffChannels{
    if (_diffChannels){
        return _diffChannels;
    }
    NSArray<NSDictionary *> *array = [self.json valueForKeyPath:[NSString stringWithFormat:@"data.packages.%@",self.accessKey]];
    NSMutableDictionary<NSString *, NSMutableDictionary *> *channels = NSMutableDictionary.new;
    [array enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull channel, NSUInteger idx, BOOL * _Nonnull stop) {
        [channels setValue:[NSMutableDictionary dictionaryWithDictionary:channel] forKey: channel[@"channel"]];
    }];
    self.channels = channels;
    
    channels = NSMutableDictionary.new;
    array = [self.comparedJson valueForKeyPath:[NSString stringWithFormat:@"data.packages.%@",self.accessKey]];
    [array enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull channel, NSUInteger idx, BOOL * _Nonnull stop) {
        [channels setValue:[NSMutableDictionary dictionaryWithDictionary:channel] forKey: channel[@"channel"]];
    }];
    self.comparedChannels = channels;
    
    NSMutableSet<NSString *> *allChannels = NSMutableSet.new;
    [allChannels addObjectsFromArray:self.channels.allKeys];
    [allChannels addObjectsFromArray:self.comparedChannels.allKeys];
    NSMutableDictionary<NSString *, NSDictionary <NSString *, NSNumber *> *> *diffChannels = NSMutableDictionary.new;
    [allChannels enumerateObjectsUsingBlock:^(NSString * _Nonnull channelName, BOOL * _Nonnull stop) {
        NSDictionary <NSString *, NSArray<NSDictionary *> *> *content = [[self.channels objectForKey:channelName] objectForKey:@"content"];
        NSDictionary <NSString *, NSArray<NSDictionary *> *> *comparedContent = [[self.comparedChannels objectForKey:channelName] objectForKey:@"content"];
        NSMutableSet<NSString *> *allDomains = NSMutableSet.new;
        [allDomains addObjectsFromArray:content.allKeys];
        [allDomains addObjectsFromArray:comparedContent.allKeys];
        NSMutableDictionary <NSString *, NSNumber *>*diffDomains = NSMutableDictionary.new;
        [allDomains enumerateObjectsUsingBlock:^(NSString * _Nonnull domainName, BOOL * _Nonnull stop) {
            NSArray<NSDictionary *> *domainRules = [content objectForKey:domainName];
            NSArray<NSDictionary *> *comparedDomainRules = [comparedContent objectForKey:domainName];
            if (![domainRules isEqualToArray:comparedDomainRules]){
                NSNumber *status;
                if (!domainRules){
                    status = [NSNumber numberWithInteger:TTBridgeAuthInfoNewAdded];
                }
                else if(!comparedDomainRules){
                    status = [NSNumber numberWithInteger:TTBridgeAuthInfoDeleted];
                }
                else{
                    status = [NSNumber numberWithInteger:TTBridgeAuthInfoUpdated];
                }
                [diffDomains setValue:status forKey:domainName];
            }
        }];
        [diffChannels setValue:diffDomains forKey:channelName];
    }];
    return diffChannels;
}

- (void)showDomainAuthRuleDiffs:(TTBridgeAuthInfoDiffCellItem *)item {
    NSArray<NSDictionary *> *authInfos = [self.channels valueForKeyPath:[NSString stringWithFormat:@"%@.content.%@",item.channelName,item.domainName]];
    NSArray<NSDictionary *> *comparedauthInfos = [self.comparedChannels valueForKeyPath:[NSString stringWithFormat:@"%@.content.%@",item.channelName,item.domainName]];
    TTBridgeAuthInfoDiffDetailViewController *diffDetailVC = [[TTBridgeAuthInfoDiffDetailViewController alloc]initWithDomain:item.domainName authInfo:authInfos comparedAuthInfos:comparedauthInfos];
    [self.navigationController pushViewController:diffDetailVC animated:YES];
}

@end
