//
//  BDXBridgeShowActionSheetMethod.h
//  BDXBridgeKit
//
//  Created by suixudong on 2021/4/2.
//

#import "BDXBridgeMethod.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeShowActionSheetMethod : BDXBridgeMethod

@end

#pragma mark - Param

@interface BDXBridgeActionSheetActions : BDXBridgeModel

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, assign) BDXBridgeActionSheetActionsType type;

@end

@interface BDXBridgeShowActionSheetMethodParamModel : BDXBridgeModel

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSArray<BDXBridgeActionSheetActions *> *actions;

@end

#pragma mark - Result

@interface BDXBridgeActionSheetDetail : BDXBridgeModel

@property (nonatomic, assign) NSInteger index;

@end

@interface BDXBridgeShowActionSheetMethodResultModel : BDXBridgeModel

@property (nonatomic, assign) BDXBridgeActionSheetActionType action;
@property (nonatomic, copy) BDXBridgeActionSheetDetail *detail;

@end

NS_ASSUME_NONNULL_END
