//
//  ACCPublishServiceSaveAlbumHandle.h
//  CameraClient
//
//  Created by ZZZ on 2021/8/17.
//

#import <Foundation/Foundation.h>

@protocol ACCPublishServiceSaveAlbumDelegate <NSObject>

@required

- (void)saveAlbumDidFinishWithError:(nullable NSError *)error;

@optional
- (void)didChangeProgress:(CGFloat)progress;

@end

@protocol ACCPublishServiceSaveAlbumHandle <NSObject>

@required

@property (nonatomic, weak, nullable) id <ACCPublishServiceSaveAlbumDelegate> delegate;

- (void)cancel;

- (void)execute;

@end
