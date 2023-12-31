//
//  ACCBeautyProtocol.h
//  Pods
//
//  Created by liyingpeng on 2020/6/4.
//

#ifndef ACCBeautyProtocol_h
#define ACCBeautyProtocol_h

#import "ACCCameraWrapper.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, AWEFaceReshapeStrategy) {
    AWEFaceReshapeStrategyNormal,
    AWEFaceReshapeStrategyNewGenderSame,
    AWEFaceReshapeStrategyNewGenderMale,
    AWEFaceReshapeStrategyNewGenderFemale,
};

@protocol ACCBeautyProtocol <ACCCameraWrapper>

@property (nonatomic, assign) BOOL forceApply;
@property (nonatomic, assign) BOOL acc_maleDetected;

- (BOOL)replaceComposerNodesWithNewTag:(NSArray *)newNodes old:(NSArray *)oldNodes;
- (void)appendComposerNodesWithTags:(NSArray *)nodes;
- (void)removeComposerNodesWithTags:(NSArray *)nodes;
- (BOOL)updateComposerNode:(NSString *)node key:(NSString *)key value:(CGFloat)value;

- (void)detectFace:(nullable void (^)(BOOL))resultBlock;
- (void)turnLensSharpen:(BOOL)isOn;

@end

NS_ASSUME_NONNULL_END

#endif /* ACCBeautyProtocol_h */
