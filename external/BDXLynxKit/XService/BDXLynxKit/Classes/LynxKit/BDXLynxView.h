//
//  BDXLynxView.h
//  BDXLynx
//
//  Created by bill on 2020/2/4.
//

#import <BDXServiceCenter/BDXLynxKitProtocol.h>
#import <Lynx/BDLynxBridge.h>
#import <Lynx/LynxModule.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// 需要改成 object
@interface BDXLynxView : UIView <BDXLynxViewProtocol>

- (instancetype)initWithFrame:(CGRect)frame params:(nullable BDXLynxKitParams*)params;

@end

NS_ASSUME_NONNULL_END
