//
//  ACCStickerPannelDataConfig.h
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2021/2/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCStickerPannelDataConfig : NSObject<NSCopying>

@property (nonatomic, copy) NSString *zipURI;

@property (nonatomic, copy) NSString *creationId;

@property (nonatomic, copy) NSDictionary *trackParams;

@end

NS_ASSUME_NONNULL_END
