//
//  ACCToolBarContainer.h
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/6/1.
//

#import <Foundation/Foundation.h>
#import "ACCToolBarCommonProtocol.h"
#import "ACCToolBarContainerPageEnum.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCToolBarContainer : NSObject <ACCToolBarCommonProtocol>

- (instancetype)initWithContentView:(UIView *)contentView Page:(ACCToolBarContainerPageEnum)page;
- (void)forceInsertWithBarItemIdsArray:(NSArray<NSValue *> *)ids;
- (void)onPanelViewDismissed;
- (void)resetShrikState;

@end

NS_ASSUME_NONNULL_END
