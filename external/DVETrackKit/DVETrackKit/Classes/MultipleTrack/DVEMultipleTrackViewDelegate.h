//
//  DVEMultipleTrackViewDelegate.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DVEMultipleTrackViewDelegate <NSObject>

- (UIScrollView * _Nullable)wrapScrollView;

@end

NS_ASSUME_NONNULL_END
