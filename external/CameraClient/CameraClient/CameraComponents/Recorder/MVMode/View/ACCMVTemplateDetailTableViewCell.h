//
//  ACCMVTemplateDetailTableViewCell.h
//  CameraClient
//
//  Created by long.chen on 2020/3/6.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCMVTemplateDetailViewController;
@protocol ACCMVTemplateModelProtocol;

@interface ACCMVTemplateDetailTableViewCell : UITableViewCell

@property (nonatomic, strong, readonly) ACCMVTemplateDetailViewController *viewController;
@property (nonatomic, strong, readonly) id<ACCMVTemplateModelProtocol> templateModel;

@property (nonatomic, strong) NSIndexPath *indexPath;

@property (nonatomic, weak) UIViewController *parentVC;

+ (NSString *)cellidentifier;

- (void)updateWithTemplateModel:(id<ACCMVTemplateModelProtocol>)templateModel;

- (void)play;
- (void)pause;
- (void)stop;

- (void)reset;

@end

NS_ASSUME_NONNULL_END
