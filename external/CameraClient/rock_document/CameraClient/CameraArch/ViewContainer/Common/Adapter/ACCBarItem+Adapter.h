//
//  ACCBarItem+Adapter.h
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/6/22.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCBaritem.h>

NS_ASSUME_NONNULL_BEGIN

// add some property to accbarItem, combine them to accBarItem.h if use this
typedef NS_ENUM(NSUInteger, ACCBarItemFunctionType) {
    ACCBarItemFunctionTypeDefault = 0,  // use tool, not hide toolbar
    ACCBarItemFunctionTypeCover = 1 // show pandel or add VC, hide toolbar
};

@interface ACCBarItem (Adapter)
@property (nonatomic, assign) ACCBarItemFunctionType type;
@property (nonatomic, copy, nullable) dispatch_block_t showBubbleBlock;
@end

NS_ASSUME_NONNULL_END
