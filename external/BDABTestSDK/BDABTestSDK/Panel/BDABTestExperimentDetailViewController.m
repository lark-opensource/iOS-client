//
//  BDABTestExperimentDetailViewController.m
//  ABSDKDemo
//
//  Created by bytedance on 2018/7/27.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "BDABTestExperimentDetailViewController.h"
#import "BDABTestManager+Cache.h"
#import "BDABTestManager+Private.h"
#import "BDABTestBaseExperiment+Private.h"
#import "BDABTestExperimentItemModel.h"

static const CGFloat kBDABTestPanelMargin = 15.0f;
static const CGFloat kBDABTestPanelLineHeight = 20.0f;

@interface BDABTestExperimentDetailViewController ()<UITextViewDelegate>

@property (nonatomic, strong) BDABTestBaseExperiment *experiment;
@property (nonatomic, strong) UILabel *keyLabel;
@property (nonatomic, strong) UILabel *ownerLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UILabel *valLabel;
@property (nonatomic, strong) UILabel *vidLabel;
@property (nonatomic, strong) UILabel *stickyLabel;
@property (nonatomic, strong) UILabel *exposureLabel;

@property (nonatomic, strong) UILabel *editValLabel;
@property (nonatomic, strong) UIButton *valCopyButton;
@property (nonatomic, strong) UITextView *resultValLabel;

@property (nonatomic, strong) UIScrollView *scrollView;

@end

@implementation BDABTestExperimentDetailViewController

- (instancetype)initWithExperiment:(BDABTestBaseExperiment *)experiment
{
    if (self = [super init]) {
        self.experiment = experiment;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(close:)];
    [self.view addSubview:self.scrollView];
    [self.scrollView addSubview:self.keyLabel];
    [self.scrollView addSubview:self.ownerLabel];
    [self.scrollView addSubview:self.descLabel];
    [self.scrollView addSubview:self.valLabel];
    [self.scrollView addSubview:self.vidLabel];
    [self.scrollView addSubview:self.stickyLabel];
    [self.scrollView addSubview:self.exposureLabel];
    [self.scrollView addSubview:self.editValLabel];
    [self.scrollView addSubview:self.valCopyButton];
    [self.scrollView addSubview:self.resultValLabel];
    [self refresh];
}

- (void)close:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

+ (NSString *)jsonStringValue:(id)value valueType:(BDABTestValueType)valueType {
    if (![NSJSONSerialization isValidJSONObject:value]) {
        return [value description];
    }
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:value options:NSJSONWritingPrettyPrinted error:&parseError];
    if (jsonData && parseError == nil) {
        NSString *result = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        if (result) {
            return result;
        }
    }
    return nil;
}

+ (id)valueForJsonString:(NSString *)string valueType:(BDABTestValueType)valueType {
    if (valueType == BDABTestValueTypeString) {
        return string;
    }
    if (valueType == BDABTestValueTypeNumber) {
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        return [f numberFromString:string];
    }
    if (valueType == BDABTestValueTypeArray || BDABTestValueTypeDictionary) {
        string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSError *jsonError;
        id value = [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&jsonError];
        if (jsonError) {
            return nil;
        }
        if (valueType == BDABTestValueTypeArray && [value isKindOfClass:[NSArray class]]) {
            return value;
        }
        if (valueType == BDABTestValueTypeDictionary && [value isKindOfClass:[NSDictionary class]]) {
            return value;
        }
        return nil;
    }
}

- (void)refresh
{
    const CGFloat kScreenWidth = [UIScreen mainScreen].bounds.size.width;
    
    CGFloat startY = 0;
    self.keyLabel.text = [NSString stringWithFormat:@"Experiment key：%@", self.experiment.key];
    self.keyLabel.frame = CGRectMake(kBDABTestPanelMargin, startY, kScreenWidth - kBDABTestPanelMargin*2, kBDABTestPanelLineHeight);
    
    startY = CGRectGetMaxY(self.keyLabel.frame);
    self.ownerLabel.text = [NSString stringWithFormat:@"Experiment owner：%@", self.experiment.owner];
    self.ownerLabel.frame = CGRectMake(kBDABTestPanelMargin, startY, kScreenWidth - kBDABTestPanelMargin*2, kBDABTestPanelLineHeight);
    
    startY = CGRectGetMaxY(self.ownerLabel.frame);
    if (self.experiment.desc.length > 0) {
        self.descLabel.text = [NSString stringWithFormat:@"Experiment description：%@", self.experiment.desc];
        self.descLabel.frame = CGRectMake(kBDABTestPanelMargin, startY, kScreenWidth - kBDABTestPanelMargin*2, 0);
        [self.descLabel sizeToFit];
        startY = CGRectGetMaxY(self.descLabel.frame);
    }
    
    self.stickyLabel.text = [NSString stringWithFormat:@"isSticky：%@", (self.experiment.isSticky ? @"yes" : @"no")];
    self.stickyLabel.frame = CGRectMake(kBDABTestPanelMargin, startY, kScreenWidth - kBDABTestPanelMargin*2, kBDABTestPanelLineHeight);
    
    startY = CGRectGetMaxY(self.stickyLabel.frame);
    self.valLabel.text = [NSString stringWithFormat:@"value：\n%@", [[self class] jsonStringValue:[self.experiment getValueWithExposure:NO] valueType:self.experiment.valueType]];
    self.valLabel.frame = CGRectMake(kBDABTestPanelMargin, startY, kScreenWidth - kBDABTestPanelMargin*2, 30);
    [self.valLabel sizeToFit];
    
    startY = CGRectGetMaxY(self.valLabel.frame);
    self.vidLabel.text = [NSString stringWithFormat:@"vid：%@", [self.experiment getResultWithExposure:NO].vid];
    self.vidLabel.frame = CGRectMake(kBDABTestPanelMargin, startY, kScreenWidth - kBDABTestPanelMargin*2, kBDABTestPanelLineHeight);
    
    startY = CGRectGetMaxY(self.vidLabel.frame);
    self.exposureLabel.text = [NSString stringWithFormat:@"exposed：%@", [self.experiment hasExposed] ? @"yes" : @"no"];
    self.exposureLabel.frame = CGRectMake(kBDABTestPanelMargin, startY, kScreenWidth - kBDABTestPanelMargin*2, kBDABTestPanelLineHeight);
    
    startY = CGRectGetMaxY(self.exposureLabel.frame);
    self.editValLabel.frame = CGRectMake(kBDABTestPanelMargin, startY, kScreenWidth - kBDABTestPanelMargin*2, kBDABTestPanelLineHeight);
    
    self.valCopyButton.frame = CGRectMake(kScreenWidth - 100 - kBDABTestPanelMargin, startY, 100, kBDABTestPanelLineHeight);
    
    startY = CGRectGetMaxY(self.editValLabel.frame);
    self.resultValLabel.text = [[self class] jsonStringValue:[[BDABTestManager sharedManager] editedItemForKey:self.experiment.key].val valueType:self.experiment.valueType];
    self.resultValLabel.frame = CGRectMake(kBDABTestPanelMargin, startY, kScreenWidth - kBDABTestPanelMargin*2, 100);

    self.scrollView.contentSize = CGSizeMake(kScreenWidth, startY);
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (textView == self.resultValLabel) {
        if (textView.text.length == 0) {
            [[BDABTestManager sharedManager] editExperimentWithKey:self.experiment.key value:nil vid:nil];
        }
        else {
            [[BDABTestManager sharedManager] editExperimentWithKey:self.experiment.key value:[[self class] valueForJsonString:textView.text valueType:self.experiment.valueType] vid:[self.experiment getResultWithExposure:NO].vid];
        }
    }
}

- (void)valCopyButtonClicked:(id)sender {
    self.resultValLabel.text = [[self class] jsonStringValue:[self.experiment getValueWithExposure:NO] valueType:self.experiment.valueType];
}

#pragma mark - accessors

- (UIScrollView *)scrollView
{
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 64)];
        _scrollView.backgroundColor = [UIColor whiteColor];
    }
    return _scrollView;
}

- (UILabel *)keyLabel
{
    if (!_keyLabel) {
        _keyLabel = [UILabel new];
        _keyLabel.font = [UIFont systemFontOfSize:15];
    }
    return _keyLabel;
}

- (UILabel *)ownerLabel
{
    if (!_ownerLabel) {
        _ownerLabel = [UILabel new];
        _ownerLabel.font = [UIFont systemFontOfSize:15];
    }
    return _ownerLabel;
}

- (UILabel *)descLabel
{
    if (!_descLabel) {
        _descLabel = [UILabel new];
        _descLabel.numberOfLines = 0;
        _descLabel.font = [UIFont systemFontOfSize:15];
    }
    return _descLabel;
}

- (UILabel *)valLabel
{
    if (!_valLabel) {
        _valLabel = [UILabel new];
        _valLabel.numberOfLines = 0;
        _valLabel.font = [UIFont systemFontOfSize:15];
    }
    return _valLabel;
}

- (UILabel *)vidLabel
{
    if (!_vidLabel) {
        _vidLabel = [UILabel new];
        _vidLabel.font = [UIFont systemFontOfSize:15];
    }
    return _vidLabel;
}

- (UILabel *)stickyLabel
{
    if (!_stickyLabel) {
        _stickyLabel = [UILabel new];
        _stickyLabel.font = [UIFont systemFontOfSize:15];
    }
    return _stickyLabel;
}

- (UILabel *)exposureLabel
{
    if (!_exposureLabel) {
        _exposureLabel = [UILabel new];
        _exposureLabel.font = [UIFont systemFontOfSize:15];
    }
    return _exposureLabel;
}

- (UILabel *)editValLabel {
    if (!_editValLabel) {
        _editValLabel = [UILabel new];
        _editValLabel.font = [UIFont systemFontOfSize:15];
        _editValLabel.text = @"Edit value(AutoSave)";
    }
    return _editValLabel;
}

- (UIButton *)valCopyButton {
    if (!_valCopyButton) {
        _valCopyButton = [UIButton new];
        [_valCopyButton setTitle:@"Copy experiment value" forState:UIControlStateNormal];
        [_valCopyButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_valCopyButton.titleLabel setFont:[UIFont systemFontOfSize:12.0]];
        [_valCopyButton addTarget:self action:@selector(valCopyButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _valCopyButton;
}

- (UITextView *)resultValLabel
{
    if (!_resultValLabel) {
        _resultValLabel = [UITextView new];
        _resultValLabel.font = [UIFont systemFontOfSize:15];
        _resultValLabel.delegate = self;
    }
    return _resultValLabel;
}

@end
