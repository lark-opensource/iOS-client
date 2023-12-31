//
//  AWESingleMusicTableViewCell.h
//  AWEStudio
//
//  Created by 李彦松 on 2018/9/10.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWEASMusicCellProtocol.h"
#import "AWESingleMusicView.h"

#import <CreationKitArch/ACCMusicModelProtocol.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT const CGFloat kMusicViewContentPadding;

@class AWEMusicCollectionData;
@class AWESingleMusicView;

@interface AWESingleMusicTableViewCell : UITableViewCell <AWEASMusicCellProtocol, AWESingleMusicViewDelegate>

@property (nonatomic, assign) BOOL showExtraTopPadding;
@property (nonatomic, assign) BOOL needShowPGCMusicInfo;
@property (nonatomic, assign) BOOL showClipButton;
@property (nonatomic, assign) CGFloat topPadding;

+ (CGFloat)heightWithMusic:(id<ACCMusicModelProtocol>)model baseHeight:(CGFloat)baseHeight;

- (instancetype)initWithNewMusicPlayerTypeWithStyle:(UITableViewCellStyle)style
                                    reuseIdentifier:(NSString *)reuseIdentifier
                                          newPlayer:(BOOL)newPlayer;

@end

NS_ASSUME_NONNULL_END
