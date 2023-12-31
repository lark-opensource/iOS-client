//
//  AWEStickerPickerHashtagView.h
//  CameraClient-Pods-Aweme
//
//  Created by Syenny on 2021/5/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEStickerPickerHashtagView;

@protocol AWEStickerPickerHashtagViewDelegate <NSObject>

- (void)stickerPickerHashtagView:(AWEStickerPickerHashtagView *)hashtagView didSelectCellWithTitle:(NSString *)title indexPath:(NSIndexPath *)indexPath;

@end

@interface AWEStickerPickerHashtagView : UIView

@property (nonatomic, weak) id<AWEStickerPickerHashtagViewDelegate> delegate;

@property (nonatomic, strong) NSArray<NSString *> *hashtagsList;

@end

NS_ASSUME_NONNULL_END
