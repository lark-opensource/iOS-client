//
//  CAKBaseServiceContainer+Toast.h
//  CreativeAlbumKit
//
//  Created by yuanchang on 2021/1/8.
//

#import "CAKBaseServiceContainer.h"
#import "CAKToastProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface CAKBaseServiceContainer (Toast)

IESProvides(CAKToastProtocol);

@end

NS_ASSUME_NONNULL_END
