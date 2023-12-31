//
//  DVETrackUIModel.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/19.
//

#import <Foundation/Foundation.h>
#import <NLEPlatform/NLETrackSlot+iOS.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVETrackUIModel : NSObject

@property (nonatomic, copy) NSArray<NLETimeSpaceNode_OC *> *slots;
@property (nonatomic, assign) NLETrackType trackType;
@property (nonatomic, assign) NSInteger layer;

@end

NS_ASSUME_NONNULL_END
