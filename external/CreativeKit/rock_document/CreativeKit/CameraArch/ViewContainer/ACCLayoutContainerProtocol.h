//
//  ACCLayoutContainerProtocol.h
//  CreativeKit-Pods-Aweme
//
//  Created by Liu Deping on 2021/3/15.
//

#import <Foundation/Foundation.h>
#import "ACCLayoutDefines.h"
#import "ACCRecordLayoutGuideProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCLayoutContainerProtocol <NSObject>

@property (nonatomic, strong, readonly) id<ACCRecordLayoutGuideProtocol> guide;

- (void)addSubview:(UIView *)subview viewType:(ACCViewType)viewType;
- (UIView *)viewForType:(ACCViewType)viewType;

- (void)containerViewControllerDidLoad;
- (void)containerViewControllerPostDidLoad;
- (void)applicationDidBecomeActive;
- (void)updateCommerceEnterButton;
- (void)updateSwitchModeView;
- (void)showSpeedControl:(BOOL)show animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
