//
//  ACCASSMusicListViewControllerProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Zhihao Zhang on 2021/3/9.
//

#import <Foundation/Foundation.h>

#import "ACCSingleMusicRecommenVideosTableViewCellProtocol.h"
#import "ACCSearchMusicRecommendedVideosModelProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCASSMusicListViewControllerProtocol <NSObject>

- (Class)studioSingleMusicRecommendVideosTableCellClass;

- (UITableViewCell<ACCSingleMusicRecommenVideosTableViewCellProtocol> *)initiaLStudioSingleMusicRecommenVideosTableViewCellWithReuseIdentifier:(NSString *)reuseIdentifier;

- (CGFloat)singleMusicRecommenVideosTableViewCellHeightWithModel:(id<ACCSearchMusicRecommendedVideosModelProtocol>)model isFirst:(BOOL)isFirst;

@end

NS_ASSUME_NONNULL_END
