//
//  IESPrefetchDebugTemplateViewController.m
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/19.
//

#import "IESPrefetchDebugTemplateViewController.h"
#import "IESPrefetchConfigTemplate.h"
#import "IESPrefetchManager.h"
#import <ByteDanceKit/NSString+BTDAdditions.h>

@interface IESPrefetchDebugTemplateViewController () <UITextViewDelegate>

@property (nonatomic, copy) NSString *business;
@property (nonatomic, strong) UITextView *textView;

@end

@implementation IESPrefetchDebugTemplateViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (instancetype)initWithBusiness:(NSString *)business
{
    if (self = [super initWithNibName:nil bundle:nil]) {
        _business = business;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"Config Detail";
    self.view.backgroundColor = [UIColor whiteColor];
    if (self.editable) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didDone)];
    }
    [self setupTextView];
    [self addKeyboardObserver];
}

- (void)setupTextView
{
    self.textView = [[UITextView alloc] init];
    self.textView.editable = self.editable;
    self.textView.scrollEnabled = YES;
    self.textView.delegate = self;
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.textView];
    if (@available(iOS 9.0, *)) {
        NSLayoutConstraint *leadingConstraint = [self.textView.leadingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.leadingAnchor];
        NSLayoutConstraint *trailingConstraint = [self.textView.trailingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.trailingAnchor];
        NSLayoutConstraint *topConstraint = nil;
        NSLayoutConstraint *bottomConstraint = nil;
        if (@available(iOS 11.0, *)) {
            topConstraint = [self.textView.topAnchor constraintEqualToSystemSpacingBelowAnchor:self.view.safeAreaLayoutGuide.topAnchor multiplier:1.0];
            bottomConstraint = [self.view.safeAreaLayoutGuide.bottomAnchor constraintEqualToSystemSpacingBelowAnchor:self.textView.bottomAnchor multiplier:1.0];
        } else {
            topConstraint = [self.textView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor constant:8];
            bottomConstraint = [self.bottomLayoutGuide.topAnchor constraintEqualToAnchor:self.textView.bottomAnchor constant:8];
        }
        [self.view addConstraints:@[leadingConstraint, trailingConstraint, topConstraint, bottomConstraint]];
    }
    NSDictionary *json = self.configTemplate.jsonRepresentation;
    if (json) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];
        NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        self.textView.text = content;
    }
}

- (void)addKeyboardObserver
{
    [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillShowNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull noti) {
        NSValue *rectValue = [noti.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
        CGFloat keyboardHeight = [rectValue CGRectValue].size.height;
        self.textView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight, 0);
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillHideNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull noti) {
        self.textView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }];
}

- (void)didDone {
    __weak typeof(self) wSelf = self;
    void (^action)(NSString *message, BOOL exit) = ^(NSString *message, BOOL exit) {
        __strong typeof(wSelf) sSelf = wSelf;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            __strong typeof(wSelf) ssSelf = wSelf;
            if (exit) {
                [ssSelf.navigationController popViewControllerAnimated:YES];
            }
        }]];
        [sSelf presentViewController:alert animated:YES completion:nil];
    };
    NSError *error = nil;
    [self.textView.text btd_jsonDictionary:&error];
    if (self.textView.text.length > 0 && !error) {
        id<IESPrefetchLoaderProtocol> loader = [IESPrefetchManager.sharedInstance loaderForBusiness:self.business];
        [loader loadConfigurationJSON:self.textView.text];
        action(@"Load Success.", YES);
    } else {
        action(@"Config Error", NO);
    }
}

#pragma mark - UITextViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self.textView resignFirstResponder];
}

@end
