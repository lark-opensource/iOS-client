//
//  AWEIMGuideSelectionImageView.h
//  CameraClient-Pods-Aweme
//
//  Created by liujingchuan on 2021/9/1.
//

#import <UIKit/UIKit.h>


@protocol AWEIMGuideSelectionImageViewDelegate <NSObject>

- (void)selectionImageViewDidChangeSelected:(BOOL)selected;

@end

@interface AWEIMGuideSelectionImageView : UIImageView

@property (assign, nonatomic) BOOL isSelected;
@property (weak, nonatomic, nullable) id<AWEIMGuideSelectionImageViewDelegate> delegate;

@end

