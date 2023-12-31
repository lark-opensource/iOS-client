//
//  BDXLynxPageView.h
//  BDXElement
//
//  Created by AKing on 2020/9/20.
//

#import <Lynx/LynxUI.h>
#import "LynxOLEContainerScrollView.h"
#import "BDXLynxPageViewItem.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDXPageViewProtocol <NSObject>

@required
-(void)didSelectPage:(LynxUI *)page;

@optional

-(void)itemSizeDidChange:(UIView *)view;

@end

@interface BDXPageView : UIView

@property (nonatomic, strong) NSArray<BDXLynxPageViewItem *> *datas;
@property (nonatomic, weak) id<BDXPageViewProtocol> viewDelegate;
@end

@interface BDXPageView()<OLEContainerTabbarScrollAble>

@end

@interface BDXLynxPageView : LynxUI <BDXPageView *>

- (nullable UIView *)currentSelectedPageView;

@end

NS_ASSUME_NONNULL_END
