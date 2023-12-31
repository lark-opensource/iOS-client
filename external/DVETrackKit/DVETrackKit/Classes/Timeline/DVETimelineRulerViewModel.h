//
//  DVETimelineRulerViewModel.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/12.
//

#import <Foundation/Foundation.h>
#import "DVEMediaContext.h"
#import "DVERulerModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVETimelineRulerViewModel : NSObject

@property (nonatomic, strong, readonly) DVEMediaContext *context;

- (instancetype)initWithContext:(DVEMediaContext *)context;

- (DVERulerModel * _Nullable)buildRulerModel;
- (NSString *)formateReference:(CGFloat)reference;

@end

NS_ASSUME_NONNULL_END
