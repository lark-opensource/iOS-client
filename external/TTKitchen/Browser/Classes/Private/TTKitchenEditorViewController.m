//
//  TTKitchenEditorViewController.m
//  Pods
//
//  Created by SongChai on 2018/4/18.
//

#import "TTKitchenEditorViewController.h"
#import "TTKitchenManager.h"

NSNotificationName const kTTKitchenEditorSuccessNotification = @"kTTKitchenEditorSuccessNotification";

@interface TTKitchenEditorViewController ()

@property (nonatomic, strong) TTKitchenModel *kitchenModel;
@property (nonatomic, strong) UILabel *keyLabel;
@property (nonatomic, strong) UITextView *valueTextView;

@end

@implementation TTKitchenEditorViewController

- (instancetype)initWithKitchenModel:(TTKitchenModel *)kitchenModel {
    if (self = [super init]) {
        self.kitchenModel = kitchenModel;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"修改" style:UIBarButtonItemStylePlain target:self action:@selector(setActionFired:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(close:)];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.keyLabel = [[UILabel alloc] init];
    self.keyLabel.numberOfLines = 1;
    self.keyLabel.text = self.kitchenModel.summary;
    self.keyLabel.numberOfLines = 0;
    self.keyLabel.lineBreakMode = NSLineBreakByCharWrapping;
    [self.view addSubview:self.keyLabel];
    
    self.valueTextView = [[UITextView alloc] init];
    self.valueTextView.layer.borderColor = [UIColor blackColor].CGColor;
    self.valueTextView.layer.borderWidth = 1.f;
    self.valueTextView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.valueTextView.autocorrectionType = UITextAutocorrectionTypeNo;
    [self.view addSubview:self.valueTextView];
    
    [self refreshValueTextView:self.kitchenModel];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.keyLabel.frame = CGRectMake(10, CGRectGetMaxY(self.navigationController.navigationBar.frame) + 20, CGRectGetWidth(self.view.frame) - 20, 50);
    CGSize maxLabelSize = CGSizeMake(CGRectGetWidth(self.view.frame) - 20, FLT_MAX);
    [self.keyLabel sizeThatFits:maxLabelSize];
    self.valueTextView.frame = CGRectMake(10, CGRectGetMaxY(self.keyLabel.frame) + 20, CGRectGetWidth(self.view.frame) - 20, 300);
}

- (void)refreshValueTextView:(TTKitchenModel *)model {
    self.valueTextView.text = [model text];
}

- (void)setActionFired:(id)sender {
    NSError *error;
    [_kitchenModel textFieldAction:self.valueTextView.text error:&error];
    
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"修改失败" message:error.domain delegate:nil cancelButtonTitle:@"关闭" otherButtonTitles:nil];
        [alert show];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kTTKitchenEditorSuccessNotification object:nil];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)close:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
@end
