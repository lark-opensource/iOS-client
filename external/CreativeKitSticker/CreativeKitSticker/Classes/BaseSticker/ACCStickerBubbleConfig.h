//
//  ACCStickerBubbleConfig.h
//  CameraClient
//
//  Created by Yangguocheng on 2020/6/9.
//

#import "ACCStickerBubbleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCStickerBubbleConfig : NSObject

@property (nonatomic, assign) ACCStickerBubbleAction actionType;
@property (nonatomic, copy) void (^callback)(ACCStickerBubbleAction actionType);

@end

NS_ASSUME_NONNULL_END
