//
//  ACCPhotoConfigProtocol.h
//  Aweme
//
//  Created by Shichen Peng on 2021/10/11.
//

#ifndef ACCPhotoConfigProtocol_h
#define ACCPhotoConfigProtocol_h

#import <Foundation/Foundation.h>
#include <stdint.h>

@protocol ACCPhotoConfigProtocol <NSObject>

@property (nonatomic, assign, readonly) CGFloat minPhotoRatio;
@property (nonatomic, assign, readonly) CGFloat maxPhotoRatio;

@property (nonatomic, assign, readonly) NSInteger minAssetsSelectionCount;
@property (nonatomic, assign, readonly) NSInteger maxAssetsSelectionCount;

@end

#endif /* ACCPhotoConfigProtocol_h */
