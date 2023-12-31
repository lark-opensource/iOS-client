//
//  HTSVideoDefines.h
//  Pods
//
// Created by he Hai on 16 / 8 / 7
//
//

typedef double HTSVideoSpeed;

extern HTSVideoSpeed const HTSVideoSpeedVerySlow;
extern HTSVideoSpeed const HTSVideoSpeedSlow;
extern HTSVideoSpeed const HTSVideoSpeedNormal;
extern HTSVideoSpeed const HTSVideoSpeedFast;
extern HTSVideoSpeed const HTSVideoSpeedVeryFast;

static inline BOOL HTSVideoSpeedEqual(HTSVideoSpeed speed1, HTSVideoSpeed speed2) {
    return ABS(speed1 - speed2) < FLT_EPSILON;
};

static inline HTSVideoSpeed HTSSpeedForIndex(NSInteger index)
{
    switch (index) {
        case 0:
            return HTSVideoSpeedVerySlow;
        case 1:
            return HTSVideoSpeedSlow;
        case 3:
            return HTSVideoSpeedFast;
        case 4:
            return HTSVideoSpeedVeryFast;
        case 2:
        default:
            return HTSVideoSpeedNormal;
    }
}

static inline NSUInteger HTSIndexForSpeed(HTSVideoSpeed speed)
{
    if (HTSVideoSpeedEqual(speed, HTSVideoSpeedVerySlow)) {
        return 0;
    } else if (HTSVideoSpeedEqual(speed, HTSVideoSpeedSlow)) {
        return 1;
    } else if (HTSVideoSpeedEqual(speed, HTSVideoSpeedNormal)) {
        return 2;
    } else if (HTSVideoSpeedEqual(speed, HTSVideoSpeedFast)) {
        return 3;
    } else if (HTSVideoSpeedEqual(speed, HTSVideoSpeedVeryFast)) {
        return 4;
    }
    return 2;
}

