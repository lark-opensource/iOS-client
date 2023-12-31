//
//  IESLiveResouceBundle+Style.h
//  Pods
//
//  Created by Zeus on 17/1/6.
//
//

#import "IESLiveResouceBundle.h"
#import "UIView+IESLiveResouceStyle.h"
@class IESLiveResouceStyleModel;

@interface IESLiveResouceBundle (Style)

- (IESLiveResouceStyleModel * (^)(NSString *))style;

@end
