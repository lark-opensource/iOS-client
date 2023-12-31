//
//  BDXLynxPageViewPro.h
//  BDXElement
//
//  Created by AKing on 2020/9/20.
//

#import <Lynx/LynxUI.h>
#import "BDXPageBaseView.h"
#import "BDXLynxPageViewItemPro.h"
#import "BDXLynxFoldHeaderViewPro.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDXLynxPageViewProDelegate <NSObject>

- (void)lynxPageViewLayoutIfNeeded;

@end

@interface BDXLynxPageViewPro : LynxUI <BDXPageBaseView *>

@property(nonatomic, strong, readonly) NSMutableArray<BDXLynxPageViewItemPro *> *pageItems;
@property (nonatomic, weak) id <BDXLynxPageViewProDelegate> tagDelegate;

@end

NS_ASSUME_NONNULL_END
