//
//  BDXLynxTabbarItemPro.h
//  BDXElement
//
//  Created by hanzheng on 2021/3/17.
//

#import <Foundation/Foundation.h>
#import <Lynx/LynxUI.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^BDXLynxTabbarItemProSelectedBlock)(BOOL selected);

@class BDXTabbarItemProView;

@protocol BDXTabbarItemProViewDelegate <NSObject>

- (void)widthDidChanged:(BDXTabbarItemProView *)view;

@end

@interface BDXTabbarItemProView: UIView

@property (nonatomic, weak, nullable) id<BDXTabbarItemProViewDelegate> delegate;

@end

@interface BDXLynxTabbarItemPro : LynxUI <BDXTabbarItemProView *>
// set defaut selected item, if mult tabbarpro-item set this prop to true, the last one will be selected
@property (nonatomic) BOOL selected;

@property (nonatomic) NSString *tabTag;

@property (nonatomic, strong) BDXLynxTabbarItemProSelectedBlock selectedBlock;

@end

NS_ASSUME_NONNULL_END
