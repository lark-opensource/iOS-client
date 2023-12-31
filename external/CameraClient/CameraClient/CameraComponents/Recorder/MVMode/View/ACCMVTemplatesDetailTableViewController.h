//
//  ACCMVTemplatesDetailTableViewController.h
//  CameraClient
//
//  Created by long.chen on 2020/3/4.
//

#import <UIKit/UIKit.h>

#import "ACCMVTemplatesDataControllerProtocol.h"
#import "ACCSlidePushContextProviderProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;
@interface ACCMVTemplatesDetailTableViewController : UIViewController<ACCSlidePushContextProviderProtocol>

@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, copy) dispatch_block_t dataChangedBlock;
@property (nonatomic, weak) id<UINavigationControllerDelegate> initialNavigaitonDelegate;
@property (nonatomic, copy) void (^didPickTemplateBlock)(id<ACCMVTemplateModelProtocol> templateModel);
@property (nonatomic, copy) void (^cancelBlock)(void);

- (instancetype)initWithDataController:(id<ACCMVTemplatesDataControllerProtocol>)dataController initialIndex:(NSUInteger)initialIndex;

@end

NS_ASSUME_NONNULL_END
