//
//  AWECaptionTableViewCell.h
//  Pods
//
//  Created by lixingdong on 2019/8/30.
//

#import <UIKit/UIKit.h>
#import <CreationKitArch/AWEStudioCaptionModel.h>

@class AWEStudioCaptionModel;

@interface AWECaptionCollectionViewCell : UICollectionViewCell

+ (NSString *)identifier;

@property (nonatomic, strong, readonly) UILabel *captionLabel;
@property (nonatomic, assign, readonly) BOOL textHighlighted;

- (void)configCellWithCaptionModel:(AWEStudioCaptionModel *)caption;
- (void)configCaptionHighlight:(BOOL)highlighted;

@end

@interface AWECaptionTableViewCell : UITableViewCell

+ (NSString *)identifier;

@property (nonatomic, copy) void (^textFieldWillReturnBlock)(AWEStudioCaptionModel *model, NSRange tailRange);
@property (nonatomic, copy) void (^audioPlayBlock)(CGFloat startTime, CGFloat endTime);

- (void)configCellWithCaptionModel:(AWEStudioCaptionModel *)caption;

- (void)configCaptionHighlight:(BOOL)highlighted;

- (void)switchEditMode:(BOOL)isEditMode;

@end
