//
//  ACCDuetTemplateCell.h
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/10/20.
//

#import <CameraClient/ACCAwemeModelProtocolD.h>
#import <UIKit/UIKit.h>


@protocol ACCAwemeModelProtocol;
@interface ACCDuetTemplateCell : UICollectionViewCell

@property (nonatomic, strong, nonnull) UIImageView *coverImageView;
+ (NSString *)cellIdentifier;
- (void)updateWithTemplateModel:(id<ACCAwemeModelProtocolD> _Nonnull)templateModel;

@end

