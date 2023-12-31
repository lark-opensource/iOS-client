//
//  ACCMomentMediaAsset.mm
//  Pods
//
//  Created by Pinka on 2020/5/19.
//

#import "ACCMomentMediaAsset+WCTTableCoding.h"
#import "ACCMomentMediaAsset.h"
#import <BDWCDB/WCDB/WCDB.h>

@implementation ACCMomentMediaAsset

WCDB_IMPLEMENTATION(ACCMomentMediaAsset)
WCDB_SYNTHESIZE(ACCMomentMediaAsset, scanDate)
WCDB_SYNTHESIZE(ACCMomentMediaAsset, didProcessed)
WCDB_SYNTHESIZE(ACCMomentMediaAsset, localIdentifier)
WCDB_SYNTHESIZE(ACCMomentMediaAsset, mediaType)
WCDB_SYNTHESIZE(ACCMomentMediaAsset, mediaSubtypes)
WCDB_SYNTHESIZE(ACCMomentMediaAsset, pixelWidth)
WCDB_SYNTHESIZE(ACCMomentMediaAsset, pixelHeight)
WCDB_SYNTHESIZE(ACCMomentMediaAsset, creationDate)
WCDB_SYNTHESIZE(ACCMomentMediaAsset, modificationDate)
WCDB_SYNTHESIZE(ACCMomentMediaAsset, duration)

WCDB_PRIMARY(ACCMomentMediaAsset, localIdentifier)

@synthesize lastInsertedRowID;

- (instancetype)initWithPHAsset:(PHAsset *)asset
{
    self = [super init];
    
    if (self) {
        _localIdentifier = [asset.localIdentifier copy];
        _mediaType = asset.mediaType;
        _mediaSubtypes = asset.mediaSubtypes;
        _pixelWidth = asset.pixelWidth;
        _pixelHeight = asset.pixelHeight;
        _creationDate = asset.creationDate;
        _modificationDate = asset.modificationDate;
        _duration = asset.duration;
    }
    
    return self;
}
  
@end
