//
//  DVEBorderEditView.h
//  DVETrackKit
//
//  Created by bytedance on 2021/7/6.
//
//  虚线框
#import <UIKit/UIKit.h>
@class DVEEditItem;
@class DVEEditTransform;
NS_ASSUME_NONNULL_BEGIN

@interface DVEBorderEditView : UIView
- (void)updateWithElem:(DVEEditItem *)elem;
- (void)applyTransform:(DVEEditTransform *)transform;
@end

NS_ASSUME_NONNULL_END
