//
//  ACCRecognitionCategoryCell.h
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/6/18.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SSRecognizeResult;

@interface ACCRecognitionSpeciesCell : UICollectionViewCell

- (void)configWithData:(SSRecognizeResult *)data at:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
