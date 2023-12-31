//
//  ACCMomentBIMResult+WCTTableCoding.h
//  Pods
//
//  Created by Pinka on 2020/6/2.
//

#import "ACCMomentBIMResult.h"
#import "ACCMomentMediaAsset+WCTTableCoding.h"
#import <BDWCDB/WCDB/WCDB.h>

@interface ACCMomentBIMResult (WCTTableCoding) <WCTTableCoding>

WCDB_PROPERTY(uid)
WCDB_PROPERTY(locationName)
WCDB_PROPERTY(checkModDate)
WCDB_PROPERTY(faceVertifyFeatures)
WCDB_PROPERTY(faceFeatures)
WCDB_PROPERTY(momentTags)
WCDB_PROPERTY(isPorn)
WCDB_PROPERTY(isLeader)
WCDB_PROPERTY(scoreInfo)
WCDB_PROPERTY(scoreInfos)
WCDB_PROPERTY(similarityData)
WCDB_PROPERTY(reframeInfos)
WCDB_PROPERTY(simId)
WCDB_PROPERTY(peopleIds)
WCDB_PROPERTY(orientation)
WCDB_PROPERTY(imageExif)
WCDB_PROPERTY(videoModelString)
WCDB_PROPERTY(videoCreateDateString)
WCDB_PROPERTY(didProcessGEO)
WCDB_PROPERTY(c3Feature)

@end
