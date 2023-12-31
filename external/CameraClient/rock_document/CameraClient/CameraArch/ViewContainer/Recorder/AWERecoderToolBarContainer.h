//
//  AWERecoderToolBarContainer.h
//  AWEStudio
//
//  Created by Liu Deping on 2020/3/25.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreativeKit/ACCRecorderBarItemContainerView.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWERecoderToolBarContainer : NSObject <ACCRecorderBarItemContainerView>

- (instancetype)initWithContentView:(UIView *)contentView;

@end

NS_ASSUME_NONNULL_END
