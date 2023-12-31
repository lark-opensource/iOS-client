//
//  ACCImageAlbumCropViewController.h
//  Indexer
//
//  Created by admin on 2021/11/8.
//

#import <UIKit/UIKit.h>
#import "ACCImageAlbumItemModel.h"

typedef void(^ConfirmBlock)(ACCImageAlbumItemCropInfo *cropInfo);
typedef void(^CancelBlock)(void);

@interface ACCImageAlbumCropViewController : UIViewController

- (instancetype)initWithData:(ACCImageAlbumItemModel *)imageAlbumItem
           commonTrackParams:(NSDictionary *)commonTrackParams
                confirmBlock:(ConfirmBlock)confirmBlock
                 cancelBlock:(CancelBlock)cancelBlock;

@end
