//
//  CAKBaseServiceContainer+Loading.h
//  CreativeAlbumKit
//
//  Created by yuanchang on 2021/1/8.
//

#import "CAKBaseServiceContainer.h"
#import "CAKLoadingProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface CAKBaseServiceContainer (Loading)

IESProvides(CAKLoadingProtocol);

@end

NS_ASSUME_NONNULL_END
