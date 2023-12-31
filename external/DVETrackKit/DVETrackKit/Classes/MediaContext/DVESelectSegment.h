//
//  DVESelectSegment.h
//  NLEEditor
//
//  Created by bytedance on 2021/4/10.
//

#import <Foundation/Foundation.h>
#import <NLEPlatform/NLEModel+iOS.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVESelectSegment : NSObject

@property (nonatomic, strong, nullable) NLETrackSlot_OC *slot;

- (instancetype)initWithSlot:(NLETrackSlot_OC *)slot;

@end

NS_ASSUME_NONNULL_END
