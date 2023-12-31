//
//  AWEInfoStickerEditViewProtocol.h
//  Pods
//
//  Created by 赖霄冰 on 2019/7/30.
//

#import <Foundation/Foundation.h>
@class AWEInteractionStickerModel;

NS_ASSUME_NONNULL_BEGIN

@protocol AWEInfoStickerEditViewProtocol <NSObject>

//for challenge
@property (nonatomic, strong) AWEInteractionStickerModel *interactionStickerInfo;

@end

NS_ASSUME_NONNULL_END
