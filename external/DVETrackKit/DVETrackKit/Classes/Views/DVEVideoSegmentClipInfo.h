//
//  DVEVideoSegmentClipInfo.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/27.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, DVEVideoSegmentClipType) {
    DVEVideoSegmentClipTypeNone,
    DVEVideoSegmentClipTypeHead,
    DVEVideoSegmentClipTypeTail,
    DVEVideoSegmentClipTypeBoth,
    DVEVideoSegmentClipTypeClipping,
    DVEVideoSegmentClipTypeClippingLeft,
};


/*
 public enum VideoSegmentClipType {//变量 缓存clip偏移的宽度。用来计算转场icon的位置
     case none, head(CGFloat), tail(CGFloat), both(CGFloat, CGFloat), clipping, clippingLeft
 }
 */

NS_ASSUME_NONNULL_BEGIN

@interface DVEVideoSegmentClipInfo : NSObject

@property (nonatomic, assign) DVEVideoSegmentClipType clipType;

@property (nonatomic, assign) CGFloat headOffset;
@property (nonatomic, assign) CGFloat tailOffset;
@property (nonatomic, assign) CGFloat bothPreOffset;
@property (nonatomic, assign) CGFloat bothOffset;

+ (instancetype)infoForType:(DVEVideoSegmentClipType)type;
+ (instancetype)infoForHead:(CGFloat)offset;
+ (instancetype)infoForTail:(CGFloat)offset;
+ (instancetype)infoForBoth:(CGFloat)preOffset offset:(CGFloat)offset;

@end

NS_ASSUME_NONNULL_END
