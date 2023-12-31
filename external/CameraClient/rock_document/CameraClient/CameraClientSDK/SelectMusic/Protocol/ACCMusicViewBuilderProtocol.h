//
//  ACCMusicViewBuilderProtocol.h
//  AWEStudio
//
//  Created by xiaojuan on 2020/9/4.
//

#import <UIKit/UIKit.h>
#import "ACCMusicEnumDefines.h"
#import "AWEMusicCollectionData.h"

#ifndef ACCMusicViewBuilderProtocol_h
#define ACCMusicViewBuilderProtocol_h

@protocol ACCMusicViewBuilderProtocol <NSObject>

- (UIView *)buildFeedbackEntranceViewWithIcon:(UIImage *)icon iconSize:(CGSize)iconSize normalText:(NSString *)normalText normalTextColor:(UIColor *)normalColor highlightText:(NSString *)highlightText highlightTextColor:(UIColor *)hightlightColor fontSize:(CGFloat)fontSize highlightTapAction:(dispatch_block_t)tapAction;

- (NSString *)searchLynxCollectMusicNotification;

- (NSString *)searchLynxShootNotification;

- (NSString *)searchLynxAudioPlayNotification;

- (NSString *)searchLynxEditMusicNotification;

- (CGFloat)heightForDynamicMusicCollectionCellWithData:(AWEMusicCollectionData *)data;

- (__kindof UITableViewCell * _Nullable)cellForDymaicMusicCollectionCellWithData:(AWEMusicCollectionData *)data tableView:(UITableView *)tableView delegate:(id)delegate;

- (void)tableViewCellsTriggerAppear:(UITableView *)tableView;

- (void)tableViewCellsTriggerDisappear:(UITableView *)tableView;

- (void)tableViewCellTriggerShow:(UITableViewCell *)cell;

- (void)tableViewCellTriggerHide:(UITableViewCell *)cell;


- (NSArray<NSString *> *)router_pathComponentArrayOfSchema:(NSString *)schema;

- (void)transitionWithURLString:(NSString *)URL completion:(void(^)(UIViewController *))completion;

- (void)transitionWithURLString:(NSString *)URL appendQuires:(NSDictionary *)quires completion:(void(^)(UIViewController *))completion;

@end

#endif /* ACCMusicViewBuilderProtocol_h */
