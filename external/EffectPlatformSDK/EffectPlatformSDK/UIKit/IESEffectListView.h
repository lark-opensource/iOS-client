//
//  IESEffectListView.h
//
//  Created by Keliang Li on 2017/10/30.
//  Copyright © 2017年 keliang0420. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IESEffectModel, IESEffectListView, IESEffectUIConfig;
@protocol IESEffectListViewDelegate <NSObject>
@required
- (void)effectListView:(IESEffectListView *)listView didSelectedEffectAtIndex:(NSInteger)index;
- (void)effectListView:(IESEffectListView *)listView didDownloadEffectWithId:(NSString *)effectId withError:(NSError *)error duration:(CFTimeInterval)duration;

@end

@interface IESEffectListView : UIView
@property (nonatomic, weak) id<IESEffectListViewDelegate> delegate;
- (void)updateWithModels:(NSArray<IESEffectModel *> *)models
           selectedIndex:(NSInteger)selectedIndex;
- (instancetype)initWithFrame:(CGRect)frame
                     uiConfig:(IESEffectUIConfig *)config;
@end


