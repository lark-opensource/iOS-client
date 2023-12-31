//
//  ACCEditTRToolBarContainer.h
//  CameraClient
//
//  Created by wishes on 2020/6/2.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCEditTRBarItemContainerView.h>
#import "ACCEditToolBarContainer.h"

@interface ACCEditTRToolBarContainer : ACCEditToolBarContainer<ACCEditTRBarItemContainerView>

- (instancetype)initWithContentView:(UIView *)contentView
                           isFromIM:(BOOL)isFromIM
                      isFromKaraoke:(BOOL)isFromKaraoke
                     isFromCommerce:(BOOL)isFromCommerce
                         isFromWish:(BOOL)isFromWish;

@end


