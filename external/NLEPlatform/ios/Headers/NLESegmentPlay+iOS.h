//
//  NLESegmentPlay+iOS.h
//  NLEPlatform
//
//  Created by bytedance on 2020/12/7.
//

#import <Foundation/Foundation.h>
#import "NLESegment+iOS.h"
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface NLESegmentPlay_OC : NLESegment_OC

@property (nonatomic, copy) NSString *cover;
@property (nonatomic, assign) float coverScale;
@property (nonatomic, copy)NLEResourceNode_OC* avFile;

- (NLEResourceType)getType;

- (NLEResourceNode_OC*)getResNode;

@end

NS_ASSUME_NONNULL_END
