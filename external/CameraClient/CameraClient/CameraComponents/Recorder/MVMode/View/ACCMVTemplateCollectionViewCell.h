//
//  ACCMVTemplateCollectionViewCell.h
//  CameraClient
//
//  Created by long.chen on 2020/3/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCMVTemplateModelProtocol;
@interface ACCMVTemplateCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIImageView *coverImageView;

@property (nonatomic, copy) NSString *creationID;

+ (NSString *)cellIdentifier;

+ (CGFloat)cellHeightForModel:(id<ACCMVTemplateModelProtocol>)templateModel withWidth:(CGFloat)width;

- (void)updateWithTemplateModel:(id<ACCMVTemplateModelProtocol>)templateModel;

@end

NS_ASSUME_NONNULL_END
