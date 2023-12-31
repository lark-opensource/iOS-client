//
//  BDXBridgeShowModalMethod.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/6.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeShowModalMethod : BDXBridgeMethod

@end

@interface BDXBridgeShowModalMethodParamModel : BDXBridgeModel

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, assign) BOOL showCancel;
@property (nonatomic, copy) NSString *cancelText;
@property (nonatomic, strong) UIColor *cancelColor;
@property (nonatomic, copy) NSString *confirmText;
@property (nonatomic, strong) UIColor *confirmColor;
@property (nonatomic, assign) BOOL tapMaskToDismiss;

@end

@interface BDXBridgeShowModalMethodResultModel : BDXBridgeModel

@property (nonatomic, assign) BDXBridgeModalActionType action;

@end

NS_ASSUME_NONNULL_END
