//
//  ACCRecognitionSpeciesDataSource.h
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/6/18.
//

#import <Foundation/Foundation.h>
#import "ACCSpeciesInfoCardsView.h"

NS_ASSUME_NONNULL_BEGIN

@class SSImageTags;

@interface ACCRecognitionSpeciesDataSource : NSObject<ACCSpeciesInfoCardsViewDataSource>

@property (nonatomic, strong) SSImageTags *tags;

@end 

NS_ASSUME_NONNULL_END
