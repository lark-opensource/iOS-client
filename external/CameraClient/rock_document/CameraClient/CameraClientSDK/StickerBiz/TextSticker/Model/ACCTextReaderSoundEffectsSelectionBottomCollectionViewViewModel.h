//
//  ACCTextReaderSoundEffectsSelectionBottomCollectionViewViewModel.h
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/2/25.
//

#import <Foundation/Foundation.h>

#import "ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCTextReaderSoundEffectsSelectionBottomCollectionViewViewModel : NSObject

@property (nonatomic, strong, nullable) NSIndexPath *selectedIndexPath;
@property (nonatomic, copy) NSString *audioText;
@property (nonatomic, copy) NSString *originalSpeakerID; // the speakerID before editing
@property (nonatomic, copy) NSArray<ACCTextReaderSoundEffectsSelectionBottomCollectionViewCellModel *> *cellModels;

- (void)useDefaultSpeaker;
- (void)fetchTextReaderTimbreListWithCompletion:(void (^)(NSError *))completion;

@end

NS_ASSUME_NONNULL_END
