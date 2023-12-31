//
//  DVEVideoAnimationChangePayload.h
//  NLEEditor
//
//  Created by bytedance on 2021/4/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVEVideoAnimationChangePayload : NSObject

@property (nonatomic, copy) NSString *slotID;
@property (nonatomic, assign) CGFloat duration;

- (instancetype)initWithSlotId:(NSString *)slotId duration:(CGFloat)duration;

@end

NS_ASSUME_NONNULL_END
