//
//  ACCMomentMediaAsset+WCTTableCoding.h
//  Pods
//
//  Created by Pinka on 2020/5/19.
//

#import "ACCMomentMediaAsset.h"
#import <BDWCDB/WCDB/WCDB.h>

@interface ACCMomentMediaAsset (WCTTableCoding) <WCTTableCoding>

WCDB_PROPERTY(scanDate)
WCDB_PROPERTY(didProcessed)
WCDB_PROPERTY(localIdentifier)
WCDB_PROPERTY(mediaType)
WCDB_PROPERTY(mediaSubtypes)
WCDB_PROPERTY(pixelWidth)
WCDB_PROPERTY(pixelHeight)
WCDB_PROPERTY(creationDate)
WCDB_PROPERTY(modificationDate)
WCDB_PROPERTY(latitude)
WCDB_PROPERTY(longitude)
WCDB_PROPERTY(duration)

@end
