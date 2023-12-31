//
//  AWEInteractionVideoReplyStickerModel.h
//  Indexer
//
//  Created by Daniel on 2021/8/23.
//

#import <CameraClient/AWEInteractionStickerModel+DAddition.h>
#import <CameraClientModel/ACCVideoReplyModel.h>

@interface AWEInteractionVideoReplyStickerModel : AWEInteractionStickerModel

@property (nonatomic, strong, nullable) ACCVideoReplyModel *videoReplyUserInfo;

@end
