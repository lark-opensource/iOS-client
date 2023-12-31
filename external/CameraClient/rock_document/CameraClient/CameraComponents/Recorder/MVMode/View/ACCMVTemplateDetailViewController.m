//
//  ACCMVTemplateDetailViewController.m
//  CameraClient
//
//  Created by long.chen on 2020/3/6.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitArch/ACCMVTemplateModelProtocol.h>
#import "ACCMVTemplateVideoPlayViewController.h"
#import "ACCMVTemplateInteractionViewController.h"

#import <Masonry/View+MASAdditions.h>

@interface ACCMVTemplateDetailViewController ()

@property (nonatomic, strong) ACCMVTemplateVideoPlayViewController *videoPlayViewController;
@property (nonatomic, strong) ACCMVTemplateInteractionViewController *interactionViewController;

@end

@implementation ACCMVTemplateDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self addChildViewController:self.videoPlayViewController];
    [self.view addSubview:self.videoPlayViewController.view];
    [self.videoPlayViewController didMoveToParentViewController:self];
    ACCMasMaker(self.videoPlayViewController.view, {
        make.edges.equalTo(self.view);
    });
    
    [self addChildViewController:self.interactionViewController];
    [self.view addSubview:self.interactionViewController.view];
    [self.interactionViewController didMoveToParentViewController:self];
    ACCMasMaker(self.interactionViewController.view, {
        make.edges.equalTo(self.view);
    });
    
    self.videoPlayViewController.interactionDelegate = self.interactionViewController;
    self.interactionViewController.videoPlayDelegate = self.videoPlayViewController;
}

- (void)setTemplateModel:(id<ACCMVTemplateModelProtocol>)templateModel
{
    _templateModel = templateModel;
    self.videoPlayViewController.templateModel = templateModel;
    self.interactionViewController.templateModel = templateModel;
}

- (void)play
{
    [self.videoPlayViewController play];
}

- (void)pause
{
    [self.videoPlayViewController pause];
}

- (void)stop
{
    [self.videoPlayViewController stop];
}

- (void)reset
{
    [self.videoPlayViewController reset];
}

- (void)setDidPickTemplateBlock:(void (^)(id<ACCMVTemplateModelProtocol> _Nonnull))didPickTemplateBlock
{
    _didPickTemplateBlock = [didPickTemplateBlock copy];
    self.interactionViewController.didPickTemplateBlock = _didPickTemplateBlock;
}

- (void)setIndexPath:(NSIndexPath *)indexPath
{
    _indexPath = indexPath;
    self.interactionViewController.indexPath = indexPath;
}

- (void)setPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    _publishModel = publishModel;
    self.interactionViewController.publishModel = publishModel;
    self.videoPlayViewController.publishModel = publishModel;
}

#pragma mark - Getters

- (ACCMVTemplateVideoPlayViewController *)videoPlayViewController
{
    if (!_videoPlayViewController) {
        _videoPlayViewController = [ACCMVTemplateVideoPlayViewController new];
    }
    return _videoPlayViewController;
}

- (ACCMVTemplateInteractionViewController *)interactionViewController
{
    if (!_interactionViewController) {
        _interactionViewController = [ACCMVTemplateInteractionViewController new];
    }
    return _interactionViewController;
}

@end
