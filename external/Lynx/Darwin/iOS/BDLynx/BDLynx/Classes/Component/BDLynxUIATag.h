//
//  BDLynxUIATag.h
//  BDLynx
//
//  Created by  wanghanfeng on 2020/2/17.
//

#import "LynxShadowNode.h"
#import "LynxUI.h"

NS_ASSUME_NONNULL_BEGIN
@class BDLynxUIATag;
@protocol BDLynxUIAtagAction <NSObject>

// 父View可实现此协议，由BDLynxUIATag通过响应链进行调用
- (void)trackClickUIAtag:(BDLynxUIATag *)UIATag;

@end

@interface BDLynxUIATag : LynxUI <UIView *>

@property(nonatomic, copy, readonly) NSString *href;
@property(nonatomic, copy, readonly) NSString *paramsString;
@property(nonatomic, copy, readonly) NSDictionary *params;
@property(nonatomic, copy, readonly) NSString *label;
@property(nonatomic, copy, readonly) NSString *identifier;
@property(nonatomic, assign, readonly) NSUInteger index;

@end

NS_ASSUME_NONNULL_END
