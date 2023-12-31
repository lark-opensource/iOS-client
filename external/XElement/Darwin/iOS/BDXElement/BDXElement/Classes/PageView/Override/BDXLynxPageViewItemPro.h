//
//  BDXLynxPageViewItemPro.h
//  BDXElement
//
//  Created by AKing on 2020/9/21.
//

#import <Lynx/LynxUI.h>
#import "BDXPageListView.h"

NS_ASSUME_NONNULL_BEGIN

@class BDXPageItemViewPro;

@protocol BDXPageItemViewProTagDelegate <NSObject>

- (void)tagDidChanged:(BDXPageItemViewPro *)view;

@end


@interface BDXPageItemViewPro : BDXPageListView

@end

@interface BDXLynxPageViewItemPro : LynxUI <BDXPageItemViewPro *>

@property (nonatomic, copy, readonly) NSString *tag;

@property (nonatomic, weak) id <BDXPageItemViewProTagDelegate> tagDelegate;

@end

NS_ASSUME_NONNULL_END
