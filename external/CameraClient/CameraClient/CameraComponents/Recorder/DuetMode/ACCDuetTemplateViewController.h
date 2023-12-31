//
//  ACCDuetTemplateViewController.h
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/10/15.
//

#import <CameraClient/ACCAwemeModelProtocolD.h>
#import "ACCSlidingTabViewController.h"

@interface ACCDuetTemplateViewController : UIViewController

@property (nonatomic, strong, nullable) AWEVideoPublishViewModel *publishViewModel;
@property (nonatomic, copy) dispatch_block_t closeBlock;
@property (nonatomic, copy) dispatch_block_t willEnterDetailVCBlock;
@property (nonatomic, copy) dispatch_block_t didAppearBlock;
@property (nonatomic, assign) NSInteger initialSelectedIndex;

@end

