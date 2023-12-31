//
//  DVEAttachable.h
//  NLEEditor
//
//  Created by bytedance on 2021/4/17.
//

#ifndef DVEAttachable_h
#define DVEAttachable_h


typedef NS_ENUM(NSUInteger, DVEAttachDirection) {
    DVEAttachDirectionLeft,
    DVEAttachDirectionRight,
};

typedef NS_ENUM(NSUInteger, DVEAttachPanPosition) {
    DVEAttachPanPositionLeft,
    DVEAttachPanPositionRight,
};


@protocol DVEAttachDatasource <NSObject>

// [CMTime]
@property (nonatomic, copy, readonly) NSArray<NSValue *> *attachablePoints;

@end

@protocol DVEAttachDelegate <NSObject>

- (CGFloat)attachPoint:(CGFloat)point direction:(DVEAttachDirection)direction;

- (NSArray<NSNumber *> *)attachPoints:(NSArray<NSNumber *> *)points
                            direction:(DVEAttachDirection)direction;

@end

@protocol DVEAttachable<NSObject, DVEAttachDelegate, DVEAttachDatasource>

@end

#endif /* DVEAttachable_h */
