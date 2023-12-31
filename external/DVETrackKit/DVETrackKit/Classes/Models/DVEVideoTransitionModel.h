//
//  DVEVideoTransitionModel.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/13.
//

#import <Foundation/Foundation.h>
#import <NLEPlatform/NLETrackSlot+iOS.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVEVideoTransitionModel : NSObject

@property (nonatomic, strong, nullable) NLETrackSlot_OC *relatedSlot;
@property (nonatomic, strong, nullable) NLETrackSlot_OC *nextSlot;

- (instancetype)initWithRelatedSlot:(NLETrackSlot_OC * _Nullable)relatedSlot
                           nextSlot:(NLETrackSlot_OC * _Nullable)nextSlot;

@end

NS_ASSUME_NONNULL_END
