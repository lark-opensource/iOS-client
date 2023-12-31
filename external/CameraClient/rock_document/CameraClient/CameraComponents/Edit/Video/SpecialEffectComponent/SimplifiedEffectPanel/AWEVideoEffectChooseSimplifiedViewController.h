//
//  AWEVideoEffectChooseSimplifiedViewController.h
//  Indexer
//
//  Created by Daniel on 2021/11/5.
//

#import <UIKit/UIKit.h>
#import <CreativeKit/ACCPanelViewProtocol.h>

@class AWEVideoPublishViewModel;
@protocol ACCEditServiceProtocol;

FOUNDATION_EXPORT void * const AWEVideoEffectChooseSimplifiedViewControllerContext;

@interface AWEVideoEffectChooseSimplifiedViewController : UIViewController <ACCPanelViewProtocol>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithModel:(AWEVideoPublishViewModel *)publishModel editService:(id<ACCEditServiceProtocol>)editService;

- (void)downloadEffectAtIndex:(NSInteger)index;

@end
