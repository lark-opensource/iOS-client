//
//  ACCEditTRToolBarContainer.h
//  CameraClient
//
//  Created by wishes on 2020/6/2.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCBarItemContainerView.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/AWEEditActionItemView.h>
#import <CreativeKit/ACCEditBarItemContainerView.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^EditToolBarMoreClickEvent)(BOOL isFold);

@interface ACCEditToolBarContainer : NSObject<ACCEditBarItemContainerView>

@property (nonatomic, assign) NSInteger maxUnfoldCount;

- (instancetype)initWithContentView:(UIView *)contentView;

- (NSArray<AWEEditAndPublishViewData *>*)adaptBarItemToViewData;

- (NSArray<ACCBarItem*> *)sortedBarItem;

@end

NS_ASSUME_NONNULL_END
