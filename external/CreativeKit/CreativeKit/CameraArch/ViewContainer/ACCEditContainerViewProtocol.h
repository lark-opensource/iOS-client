//
//  ACCEditContainerView.h
//  AWEStudio
//
//  Created by guochenxiang on 2019/11/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditContainerViewProtocol <NSObject>

@property (nonatomic, strong) void(^videoPlayerTappedBlock)(UIView *sender);

@property (nonatomic, copy, nullable) dispatch_block_t interactionBlock;

/// toggle play button presentation
/// @param display YES to display
/// @return YES means toggle does occur
- (BOOL)displayPlayButton:(BOOL)display;

@end

NS_ASSUME_NONNULL_END
