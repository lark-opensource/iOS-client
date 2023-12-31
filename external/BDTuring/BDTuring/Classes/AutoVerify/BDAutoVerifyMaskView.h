//
//  BDAutoVerifyMaskView.h
//  BDTuring
//
//  Created by yanming.sysu on 2020/8/9.
//

#import <UIKit/UIKit.h>
#import "BDAutoVerifyConstant.h"

NS_ASSUME_NONNULL_BEGIN

@class BDAutoVerifyDataModel, BDAutoVerify;

@interface BDAutoVerifyMaskView : UIView

@property (nonatomic, strong) BDAutoVerifyDataModel *dataModel;
@property (nonatomic, assign) double startTimeStamp;
@property (nonatomic, readonly) BDAutoVerifyViewType type;

- (instancetype)initWithVerify:(BDAutoVerify *)verify frame:(CGRect)frame;

@end

NS_ASSUME_NONNULL_END
