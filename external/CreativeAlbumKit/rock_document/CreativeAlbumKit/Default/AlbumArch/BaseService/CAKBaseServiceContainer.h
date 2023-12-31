//
//  CAKBaseServiceContainer.h
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/8.
//

#import <Foundation/Foundation.h>

#import <IESInject/IESInject.h>

@interface CAKBaseServiceContainer : IESStaticContainer

+ (instancetype _Nonnull)sharedContainer;

@end
