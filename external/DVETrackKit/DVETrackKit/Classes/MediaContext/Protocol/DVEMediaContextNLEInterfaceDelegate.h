//
//  DVEMediaContextNLEInterfaceDelegate.h
//  DVETrackKit
//
//  Created by bytedance on 2021/9/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class NLETrackSlot_OC, NLEResourceNode_OC;

@protocol DVEMediaContextNLEInterfaceDelegate <NSObject>

- (AVURLAsset *)mediaDelegateAssetFromSlot:(NLETrackSlot_OC *)slot;

- (NSString *)mediaDelegateGetAbsolutePathWithResource:(NLEResourceNode_OC *)resourceNode;

@end

NS_ASSUME_NONNULL_END
