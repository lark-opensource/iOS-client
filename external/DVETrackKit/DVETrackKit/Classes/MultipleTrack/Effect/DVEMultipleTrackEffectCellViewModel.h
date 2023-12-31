//
//  DVEMultipleTrackEffectCellViewModel.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/27.
//

#import <UIKit/UIKit.h>
#import "DVEMultipleTrackViewCellViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEMultipleTrackEffectCellViewModel : DVEMultipleTrackViewCellViewModel

@property (nonatomic, copy) NSString *tagTitle;

- (instancetype)initWithContext:(DVEMediaContext *)context
                        segment:(NLETimeSpaceNode_OC *)segment
                          frame:(CGRect)frame
                backgroundColor:(UIColor *)backgroundColor
                          title:(NSString *)title
                       tagTitle:(NSString *)tagTitle
                           icon:(NSString *)icon
                      timeScale:(CGFloat)timeScale;

@end

NS_ASSUME_NONNULL_END
