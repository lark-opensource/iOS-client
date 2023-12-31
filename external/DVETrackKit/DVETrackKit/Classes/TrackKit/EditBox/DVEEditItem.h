//
//  DVEEditItem.h
//  TTVideoEditorDemo
//
//  created by bytedance on 2020/12/10.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DVEEditTransform.h"
NS_ASSUME_NONNULL_BEGIN

@interface DVEEditItem : NSObject

@property (nonatomic) NSInteger stikerId;
@property (nonatomic, copy) NSString *resourceId;   // 对应NLE的segmentId
@property (nonatomic) CGFloat minScale;
@property (nonatomic) CGFloat maxScale;
@property (nonatomic) CGSize size;
@property (nonatomic) BOOL isNormalSticker;
@property (nonatomic) int order;
@property (nonatomic) CGFloat boxSizeScale;
@property (nonatomic) DVEEditTransform *transform;
@property (nonatomic, copy) NSArray<DVEEditItem *> *borderElements;

- (instancetype)initWithStickerId:(NSInteger)stickerid resourceId:(NSString *)resourceId size:(CGSize)size order:(int)order;

- (BOOL)hitTestWithPointInCanvasView:(CGPoint)point;

- (BOOL)hitTestWithPointInCanvasView:(CGPoint)point
                                size:(CGSize)size
                           transform:(DVEEditTransform *)transform;

@end

NS_ASSUME_NONNULL_END
