//
//  PreloadViewController.m
//  BDTuring
//
//  Created by yanming.sysu on 2020/9/3.
//

#import "PreloadViewController.h"
#import "BDTuring+Preload.h"
#import "BDTuringVerifyModel.h"
#import "BDDebugFeedTuring.h"
#import "BDTuringVerifyModel+Creator.h"

@interface PreloadViewController ()

@property (nonatomic, strong) UIButton *preloadButton;

@property (nonatomic, strong) UIButton *startButton;

@property (nonatomic, strong) BDTuringVerifyModel *model;

@end

@implementation PreloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.preloadButton = [[UIButton alloc] initWithFrame:CGRectMake(100, 200, 200, 42)];
    [self.preloadButton setTitle:@"开始预加载" forState:UIControlStateNormal];
    [self.preloadButton setBackgroundColor:[UIColor brownColor]];
    [self.preloadButton addTarget:self action:@selector(preloadAction) forControlEvents:UIControlEventTouchUpInside];
    
    self.startButton = [[UIButton alloc] initWithFrame:CGRectMake(100, 300, 200, 42)];
    [self.startButton setTitle:@"弹出验证码" forState:UIControlStateNormal];
    [self.startButton setBackgroundColor:[UIColor brownColor]];
    [self.startButton addTarget:self action:@selector(startAction) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.preloadButton];
    [self.view addSubview:self.startButton];
    
    self.model = [BDTuringVerifyModel preloadModel];
}


- (void)preloadAction {
    [[BDDebugFeedTuring sharedInstance].turing preloadVerifyViewWithModel:self.model];
}

- (void)startAction {
    [[BDDebugFeedTuring sharedInstance].turing popVerifyViewWithModel:self.model];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
