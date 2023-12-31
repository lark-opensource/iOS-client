//
//  AWEStickerPickerHashtagCollectionViewCell.h
//  CameraClient-Pods-Aweme
//
//  Created by Syenny on 2021/5/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEStickerPickerHashtagCollectionViewCell : UICollectionViewCell

@property (nonatomic, copy) NSString *title;

+ (NSString *)identifier;

- (void)configCellWithTitle:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
