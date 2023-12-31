//
//  BDXLynxSvgView.h
//  BDXElement
//
//  Created by pacebill on 2020/3/19.
//

#import <Lynx/LynxUI.h>

NS_ASSUME_NONNULL_BEGIN
@interface BDXLynxViewSvg : UIView
@end

@interface BDXLynxSvgView : LynxUI <BDXLynxViewSvg *>

@property (nonatomic, copy) NSString *src;
@property (nonatomic, copy) NSString *content;
- (void)updateLayoutIfNeed;

@end

NS_ASSUME_NONNULL_END
