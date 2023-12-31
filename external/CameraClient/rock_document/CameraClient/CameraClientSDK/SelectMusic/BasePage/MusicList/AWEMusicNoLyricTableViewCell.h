//
//  AWEMusicNoLyricTableViewCell.h
//  AWEStudio
//  normal music card
//  Created by Liu Deping on 2019/10/9.
//

#import <UIKit/UIKit.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEMusicNoLyricTableViewCell : UITableViewCell

- (void)configWithMusicModel:(id<ACCMusicModelProtocol>)model;

@end

NS_ASSUME_NONNULL_END
