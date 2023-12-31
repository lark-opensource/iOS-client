//
//  ACCRecodInputDataProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/8/23.
//

#import <Foundation/Foundation.h>
#import "AWEVideoPublishViewModel.h"
#import "ACCAwemeModelProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCRecodInputDataProtocol <NSObject>

@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, strong) id<ACCMusicModelProtocol> sameStickerMusic;
@property (nonatomic,   copy) NSString *ugcPathRefer;

@end

NS_ASSUME_NONNULL_END
