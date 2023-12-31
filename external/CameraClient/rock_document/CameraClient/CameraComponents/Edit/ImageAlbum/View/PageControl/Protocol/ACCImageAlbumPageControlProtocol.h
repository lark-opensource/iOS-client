//
//  ACCImageAlbumPageControlProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/10/15.
//

#import <UIKit/UIKit.h>

@protocol ACCImageAlbumPageControlProtocol

@property (nonatomic, assign) NSInteger currentPageIndex;
@property (nonatomic, assign) NSInteger totalPageNum;

- (void)updateCurrentPageIndex:(NSInteger)currentPageIndex;
- (void)resetTotalPageNum:(NSInteger)totalPageNum currentPageIndex:(NSInteger)currentPageIndex;

@end
