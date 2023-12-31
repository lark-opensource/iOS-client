//
//  ACCEditContainerView.h
//  AWEStudio
//
//  Created by guochenxiang on 2019/11/8.
//

#import <UIKit/UIKit.h>
#import <CreativeKit/ACCEditContainerViewProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCEditContainerView : UIView <ACCEditContainerViewProtocol>

@property (nonatomic, copy, nullable) dispatch_block_t interactionBlock;

@end

NS_ASSUME_NONNULL_END
