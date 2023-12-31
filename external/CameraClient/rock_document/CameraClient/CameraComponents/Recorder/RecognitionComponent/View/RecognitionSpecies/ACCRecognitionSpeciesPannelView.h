//
//  ACCRecognitionSpeciesPannelView.h
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/6/18.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCRecognitionSpeciesPanelViewModel;

@interface ACCRecognitionSpeciesPannelView : UIView

@property (nonatomic, copy) void (^closePanelCallback) (void);
@property (nonatomic, strong) ACCRecognitionSpeciesPanelViewModel *panelViewModel;
@property (nonatomic, assign, readonly) NSInteger currentSelectedIndex;

- (void)resetDefaultSelectionIndex:(NSUInteger)index;
- (void)resetSelectionAsDefault;

@end

NS_ASSUME_NONNULL_END
