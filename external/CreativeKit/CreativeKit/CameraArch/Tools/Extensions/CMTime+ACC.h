//
//  CMTime+ACC.h
//  CameraClient
//
//  Created by luochaojing on 2020/1/2.
//

#ifndef CMTime_ACC_h
#define CMTime_ACC_h

#import <CoreMedia/CMTime.h>
#import <CoreMedia/CMTimeRange.h>

/// Move the whole time forward with the same length
static CMTimeRange ACCTimeRangeOffset(CMTimeRange time, CMTime offset) {
    CMTime start = CMTimeSubtract(time.start, offset);
    CMTimeRange _time = CMTimeRangeMake(start, time.duration);
    return _time;
}

/// Minus the length of the head, the new start is at the cut
static CMTimeRange ACCTimeRangeCutHead(CMTimeRange timeRange, CMTime headDuration) {
    CMTime start = CMTimeAdd(timeRange.start, headDuration);
    CMTime end = CMTimeRangeGetEnd(timeRange);
    CMTimeRange _newRange = CMTimeRangeFromTimeToTime(start, end);
    return _newRange;
}

///
static CMTimeRange ACCTimeRangeCutBack(CMTimeRange timeRange, CMTime backDuration) {
    CMTime end = CMTimeRangeGetEnd(timeRange);
    CMTime newEnd = CMTimeSubtract(end, backDuration);
    CMTimeRange _newRange = CMTimeRangeFromTimeToTime(timeRange.start, newEnd);
    return _newRange;
}

/// Is there an intersection
static BOOL ACCTimeRangeHasIntersection(CMTimeRange one, CMTimeRange other) {
    CMTime oneEnd = CMTimeRangeGetEnd(one);
    CMTime oneStart = one.start;
    
    CMTime otherEnd = CMTimeRangeGetEnd(other);
    CMTime otherStart = other.start;
    if (CMTimeCompare(oneStart, otherEnd) >= 0 || CMTimeCompare(otherStart, oneEnd) >= 0) {
        return NO;
    }
    return YES;
}

// Returns the intersection of timerange
static CMTimeRange ACCTimeRangeIntersection(CMTimeRange one, CMTimeRange other) {
    BOOL intersect = ACCTimeRangeHasIntersection(one, other);
    if (!intersect) {
        return kCMTimeRangeZero;
    }
    
    CMTime oneEnd = CMTimeRangeGetEnd(one);
    CMTime oneStart = one.start;
       
    CMTime otherEnd = CMTimeRangeGetEnd(other);
    CMTime otherStart = other.start;
    
    CMTime _newStart = CMTimeMaximum(oneStart, otherStart);
    CMTime _newEnd = CMTimeMinimum(oneEnd, otherEnd);
    
    CMTimeRange _newRange = CMTimeRangeFromTimeToTime(_newStart, _newEnd);
    return _newRange;
}


static CMTime ACCTimeScale(CMTime time, CGFloat scale) {
    Float64 value = CMTimeGetSeconds(time);
    value = value * scale;
    CMTime _time = CMTimeMakeWithSeconds(value, 1000000);
    return _time;
}

static int64_t ACCTimeToUs(CMTime time) {
    int64_t order = 1000 * 1000; // S to us
    CGFloat timeSeconds = CMTimeGetSeconds(time);
    int64_t srcDuration = (int64_t)(timeSeconds * order);
    return srcDuration;
}


#endif /* CMTime_ACC_h */

