//
//  NLESegmentImage_OC.h
//  NLEPlatform
//
//  Created by bytedance on 2021/3/25.
//

#import <Foundation/Foundation.h>

#import "NLEStyCrop+iOS.h"
#import "NLEStyCanvas+iOS.h"
#import "NLEResourceNode+iOS.h"
#import "NLESegment+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLESegmentImage_OC : NLESegment_OC

@property (nonatomic, strong) NLEStyCrop_OC *crop;
@property (nonatomic, strong) NLEStyCanvas_OC *canvasStyle;
@property (nonatomic, strong) NLEResourceNode_OC *imageFile;

- (float)alpha;

- (void)setAlpha:(float)alpha;

- (NLEResourceType)getType;

- (NLEResourceNode_OC *)getResNode;

@end

NS_ASSUME_NONNULL_END
