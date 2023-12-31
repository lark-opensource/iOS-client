//
//  BDXLynxFoldViewProItem.h
//  BDXElement
//
//  Created by AKing on 2020/9/24.
//

#import <Lynx/LynxUI.h>

NS_ASSUME_NONNULL_BEGIN

@class BDXLynxFoldHeaderViewPro;

@protocol BDXLynxFoldHeaderViewProDelegate <NSObject>

- (void)lynxFoldHeaderLayoutIfNeeded:(BDXLynxFoldHeaderViewPro *)lynxFoldHeader;

@end

@interface BDXLynxFoldHeaderViewPro : LynxUI <UIView *>

@property (nonatomic, assign, readonly) BOOL fold;
@property (nonatomic, weak) id<BDXLynxFoldHeaderViewProDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
