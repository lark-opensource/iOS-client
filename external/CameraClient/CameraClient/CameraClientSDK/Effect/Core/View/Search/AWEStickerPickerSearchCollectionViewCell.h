//
//  AWEModernStickerSearchCollectionViewCell.h
//  CameraClient-Pods-Aweme
//
//  Created by Syenny on 2021/5/18.
//

#import <Foundation/Foundation.h>

#import "AWEStickerPickerSearchView.h"
#import "AWEStickerPickerModel.h"
#import "AWEStickerPickerUIConfigurationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface AWEStickerPickerSearchCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) AWEStickerPickerModel *model;

@property (nonatomic, strong, readonly) AWEStickerPickerSearchView *searchView;

+ (NSString *)identifier;

- (void)updateUIConfig:(id<AWEStickerPickerUIConfigurationProtocol>)config;

@end

NS_ASSUME_NONNULL_END
