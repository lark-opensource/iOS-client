//
//  BDXLynxRefreshView.h
//  BDXElement
//
//  Created by AKing on 2020/10/12.
//

#import <Lynx/LynxUI.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDXRefreshView : UIView

@end

@interface BDXLynxRefreshView : LynxUI <BDXRefreshView *>

@property (nonatomic, strong, readonly) UIScrollView *scrollView;

@end

NS_ASSUME_NONNULL_END
