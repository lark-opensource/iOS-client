//
//  CAKAlbumSwitchBottomView.h
//  CreativeAlbumKit-Pods-Aweme
//
//  Created by shaohua yang on 2/4/21.
//

#import "CAKAlbumBottomViewProtocol.h"

@interface CAKAlbumSwitchBottomView : UIView<CAKAlbumBottomViewProtocol>

@property (nonatomic, strong, nullable) UILabel *titleLabel; // ignored

@property (nonatomic, strong, nullable) UIButton *nextButton;

- (instancetype _Nonnull)initWithSwitchBlock:(void (^ _Nullable)(BOOL selected))block multiSelect:(BOOL)isMultiSelect;

@end
