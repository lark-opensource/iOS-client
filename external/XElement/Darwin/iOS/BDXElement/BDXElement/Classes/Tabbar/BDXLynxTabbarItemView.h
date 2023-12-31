//
//  BDXLynxTabbarItemView.h
//  Lynx
//
//  Created by bytedance on 2020/12/1.
//

#import <Lynx/LynxUI.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDXTabbarItemView : UIView
@property (nonatomic) NSString *tabTag;
@end

@interface BDXLynxTabbarItemView : LynxUI <BDXTabbarItemView *>

@end

NS_ASSUME_NONNULL_END
