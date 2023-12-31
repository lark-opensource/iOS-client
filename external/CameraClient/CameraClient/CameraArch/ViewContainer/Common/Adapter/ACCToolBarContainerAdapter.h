//
//  ACCToolBarContainerAdapter.h
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/6/1.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCRecorderBarItemContainerView.h>
#import <CreativeKit/ACCEditTRBarItemContainerView.h>

#import "ACCToolBarContainerPageEnum.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCToolBarContainerAdapter : NSObject<ACCRecorderBarItemContainerView, ACCEditTRBarItemContainerView>
- (instancetype)initWithContentView:(UIView *)contentView Page:(ACCToolBarContainerPageEnum)page;
- (void)forceInsertWithBarItemIdsArray:(NSArray<NSValue *> *)ids;
- (void)resetShrinkState;
@end

NS_ASSUME_NONNULL_END
