//
//  ACCMVTemplateDetailTableViewCell.m
//  CameraClient
//
//  Created by long.chen on 2020/3/6.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCMVTemplateDetailTableViewCell.h"
#import "ACCMVTemplateDetailViewController.h"
#import <CreationKitArch/ACCMVTemplateModelProtocol.h>

#import <Masonry/View+MASAdditions.h>

@interface ACCMVTemplateDetailTableViewCell ()

@property (nonatomic, strong, readwrite) ACCMVTemplateDetailViewController *viewController;
@property (nonatomic, strong, readwrite) id<ACCMVTemplateModelProtocol> templateModel;

@end

@implementation ACCMVTemplateDetailTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

+ (NSString *)cellidentifier
{
    return NSStringFromClass(self.class);
}

- (void)updateWithTemplateModel:(id<ACCMVTemplateModelProtocol>)templateModel
{
    _templateModel = templateModel;
    self.viewController.templateModel = templateModel;
}

- (void)play
{
    [self.viewController play];
}

- (void)pause
{
    [self.viewController pause];
}

-(void)stop
{
    [self.viewController stop];
}

- (void)reset
{
    [self.viewController reset];
}

- (void)setParentVC:(UIViewController *)parentVC
{
    if (_parentVC != parentVC) {
        _parentVC = parentVC;
        if (parentVC) {
            [self _addChildVC];
        } else {
            [self _removeChildVC];
        }
    }
}

- (void)_addChildVC
{
    if (self.viewController) {
        [self _removeChildVC];
    }
    
    self.viewController = [ACCMVTemplateDetailViewController new];
    [self.contentView addSubview:self.viewController.view];
    [self.viewController didMoveToParentViewController:self.parentVC];
    ACCMasMaker(self.viewController.view, {
        make.edges.equalTo(self);
    });
}

- (void)_removeChildVC
{
    [self.viewController.view removeFromSuperview];
    [self.viewController willMoveToParentViewController:nil];
    [self.viewController removeFromParentViewController];
}

- (void)setIndexPath:(NSIndexPath *)indexPath
{
    _indexPath = indexPath;
    self.viewController.indexPath = indexPath;
}

@end
