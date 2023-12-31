//
//  DVEMultipleTrackController.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/29.
//

#import <Foundation/Foundation.h>
#import "DVEMultipleTrackView.h"
#import "DVEMediaContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEMultipleTrackController : NSObject

@property (nonatomic, strong) DVEMultipleTrackView *trackView;

- (instancetype)initWithContext:(DVEMediaContext *)context;

- (void)updateWithMultipleTrackMode:(DVEMultipleTrackType)multipleTrackMode hidden:(BOOL)hidden;

@end

NS_ASSUME_NONNULL_END
