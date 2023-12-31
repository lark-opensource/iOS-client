//
//  AWECoverTextDraftModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Fengfanhua.byte on 2020/4/21.
//

#import <Mantle/Mantle.h>
#import <CreationKitArch/AWEInteractionStickerModel.h>
#import <CreationKitArch/AWEStoryTextImageModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWECoverTextModel : MTLModel<MTLJSONSerializing>

@property (nonatomic, assign) BOOL isStoryText; // Text
@property (nonatomic, assign) BOOL isNone;//
@property (nonatomic, copy) NSArray<NSString *> *texts;

@property (nonatomic, strong) AWEStoryTextImageModel *textModel;
@property (nonatomic, copy) NSString *textEffectId;

@property (nonatomic, strong) AWEInteractionStickerLocationModel *location;
@property (nonatomic, assign) NSUInteger cursorLoc;

@end

NS_ASSUME_NONNULL_END
