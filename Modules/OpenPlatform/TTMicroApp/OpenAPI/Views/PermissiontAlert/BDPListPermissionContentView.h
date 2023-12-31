//
//  BDPListPermissionContentView.h
//  Timor
//
//  Created by liuxiangxin on 2019/6/17.
//

#import <UIKit/UIKit.h>

@class BDPListPermissionContentView;

@protocol BDPListPermissionContentViewDelegate <NSObject>

- (void)contentView:(BDPListPermissionContentView *_Nonnull)contentView didUpdateSelectedIndexes:(NSArray<NSNumber *> *_Nullable)selectedIndexs;

@end

NS_ASSUME_NONNULL_BEGIN

@interface BDPListPermissionContentView : UIView
@property (nonatomic, assign) BOOL enableNewStyle;
@property (nonatomic, copy, readonly) NSArray<NSString *> *titleList;
@property (nonatomic, weak) id<BDPListPermissionContentViewDelegate> delegate;

- (instancetype)initWithTitleList:(NSArray<NSString *> *)titleList isNewStyle:(BOOL)enableNewStyle;
- (NSArray<NSNumber *> *)selectedIndexs;

@end

NS_ASSUME_NONNULL_END
