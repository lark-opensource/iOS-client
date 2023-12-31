//
//  DVETargetIndex.h
//  NLEPlatform
//
//  Created by bytedance on 2021/4/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVETargetIndex : NSObject

@property (nonatomic, assign) NSInteger trackIndex;
@property (nonatomic, assign) NSInteger slotIndex;

- (instancetype)initWithTrackIndex:(NSInteger)trackIndex slotIndex:(NSInteger)slotIndex;

@end

NS_ASSUME_NONNULL_END
