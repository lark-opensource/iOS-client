//
//  DVEMultipleTrackViewCellViewModel.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/23.
//

#import <Foundation/Foundation.h>
#import "DVEMediaContext.h"

NS_ASSUME_NONNULL_BEGIN

@class DVEMultipleTrackViewCellViewModel;
@protocol DVEMultipleTrackViewCellModelDelegate <NSObject>

- (void)multipleTrackViewCellModel:(DVEMultipleTrackViewCellViewModel *)cellModel
                            slotId:(NSString *)slotId
                             state:(UIGestureRecognizerState)state;

@end

@interface DVEMultipleTrackViewCellViewModel : NSObject

@property (nonatomic, strong) DVEMediaContext *context;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, strong, nullable) NLETimeSpaceNode_OC *segment;
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *icon;
@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) CGFloat timeScale;
@property (nonatomic, weak) id<DVEMultipleTrackViewCellModelDelegate> delegate;

- (instancetype)initWithContext:(DVEMediaContext *)context
                        segment:(NLETimeSpaceNode_OC * _Nullable)segment
                          frame:(CGRect)frame
                backgroundColor:(UIColor *)backgroundColor
                          title:(NSString * _Nullable)title
                           icon:(NSString * _Nullable)icon
                      timeScale:(CGFloat)timeScale;

@end

NS_ASSUME_NONNULL_END
