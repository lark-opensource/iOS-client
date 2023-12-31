//
//  AWEAutoCaptionsEditViewController.h
//  Pods
//
//  Created by lixingdong on 2019/9/2.
//

#import <UIKit/UIKit.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitRTProtocol/ACCEditPreviewProtocol.h>

@class VEEditorSession, AWEStudioCaptionModel;

@interface AWEAutoCaptionsEditViewController : UIViewController

@property (nonatomic, strong) NSString *enterFrom;

@property (nonatomic, weak) id <ACCEditPreviewProtocol> previewService;

@property (nonatomic, copy) void (^didDismissBlock)(CGFloat startTime, NSInteger currentIndex);
@property (nonatomic, copy) void (^savedBlock)(NSMutableArray<AWEStudioCaptionModel *> *captions, NSInteger currentIndex);

- (instancetype)initWithReferExtra:(NSDictionary *)referExtra captions:(NSMutableArray<AWEStudioCaptionModel *> *)captions selectedIndex:(NSInteger)selectedIndex;

@end
