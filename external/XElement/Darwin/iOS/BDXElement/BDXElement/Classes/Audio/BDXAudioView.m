//
//  BDXAudioView.m
//  BDXElement-Pods-Aweme
//
//  Created by DylanYang on 2020/9/25.
//

#import "BDXAudioView.h"
@protocol BDXAudioViewControllerDelegate<NSObject>
-(void)viewControllerWillAppear;
-(void)viewControllerDidDisappear;
@end

@interface BDXAudioViewController : UIViewController
@property(nonatomic, weak) id<BDXAudioViewControllerDelegate> delegate;
@end

@implementation BDXAudioViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.delegate viewControllerWillAppear];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self.delegate viewControllerDidDisappear];
}

@end

@interface BDXAudioView()<BDXAudioViewControllerDelegate>
@property(nonatomic, strong) BDXAudioViewController *lifeCycleVc;
@end

@implementation BDXAudioView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.lifeCycleVc = [[BDXAudioViewController alloc] init];
        self.lifeCycleVc.delegate = self;
        [self addSubview:self.lifeCycleVc.view];
    }
    return self;
}

- (void)viewControllerWillAppear {
    [self.delegate audioViewWillAppear:self];
}

- (void)viewControllerDidDisappear {
    [self.delegate audioViewDidDisappear:self];
}


@end


