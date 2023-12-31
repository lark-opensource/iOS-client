//
//  DVEMultipleTrackViewModel.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/23.
//

#import <Foundation/Foundation.h>
#import <NLEPlatform/NLEModel+iOS.h>
#import "DVEMultipleTrackViewCellViewModel.h"
#import "DVEMediaContext.h"
#import "DVEMultipleTrackViewProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class DVEMultipleTrackView;
@protocol DVEMultipleTrackViewModelDelegate <NSObject>

- (DVEMultipleTrackView *)trackView;

@end

@interface DVEMultipleTrackViewModel : NSObject<DVEMultipleTrackViewDataSource,
DVEMultipleTrackViewClickDelegate,
DVEMultipleTrackMoveProtocol,
DVEMultipleTrackTailInsertProtocol,
DVEMultipleTrackClipProtocol>

@property (nonatomic, copy) NSArray<NSArray<DVEMultipleTrackViewCellViewModel *> *> *cellViewModels;
@property (nonatomic, strong) DVEMediaContext *context;
@property (nonatomic, weak) id<DVEMultipleTrackViewModelDelegate> delegate;
@property (nonatomic, assign) CGSize layoutSize;
@property (nonatomic, assign) NLETrackType type;

- (instancetype)initWithContext:(DVEMediaContext *)context;

- (void)reloadDataIfNeeded;

- (NSString *)cellIdentifierAtIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
