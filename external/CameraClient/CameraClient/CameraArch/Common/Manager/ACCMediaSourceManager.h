//
//  ACCMediaSourceManager.h
//  Pods
//
//  Created by Pinka on 2020/5/14.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>


NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSInteger, ACCMediaSourceType) {
    ACCMediaSourceType_Image = 1 << 0,
    ACCMediaSourceType_Video = 1 << 1,
};

@interface ACCMediaSourceManager : NSObject

- (void)assetWithType:(ACCMediaSourceType)type
            ascending:(BOOL)ascending
   configFetchOptions:(nullable void(^)(PHFetchOptions *fetchOptions))configBlock
           completion:(nullable void(^)(PHFetchResult<PHAsset *> * _Nullable result))completion;

@end

NS_ASSUME_NONNULL_END
