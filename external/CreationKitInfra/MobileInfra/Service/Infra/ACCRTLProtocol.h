//
//  ACCRTLProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/8/19.

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCRTLViewType) {
    ACCRTLViewTypeAuto,
    ACCRTLViewTypeInherit,
    ACCRTLViewTypeNormal,
    ACCRTLViewTypeFlip,
    ACCRTLViewTypeNormalWithAllDescendants,
    ACCRTLViewTypeFlipWithAllDescendants,
};


@protocol ACCRTLProtocol <NSObject>

- (void)setRTLTypeWithView:(UIView *)view type:(ACCRTLViewType)type;

- (void)obj:(NSObject *)obj addRTLExecuteBlock:(void (^)(void))reloadBlock;

- (BOOL)isRTL;

- (BOOL)enableRTL;

- (CGAffineTransform)accrtl_basicTransformFor:(CALayer *)layer;

- (void)disableOperationsCollectionForAttributedString:(NSMutableAttributedString *)attributedString;

- (void)set_awertlAlignmentWithTextView:(UITextView *)textView alignment:(NSTextAlignment)alignment;

@end

FOUNDATION_STATIC_INLINE id<ACCRTLProtocol> ACCRTL() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCRTLProtocol)];
}

NS_ASSUME_NONNULL_END
