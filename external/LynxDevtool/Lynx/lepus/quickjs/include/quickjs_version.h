#ifndef QUICKJS_VERSION_H
#define QUICKJS_VERSION_H

#include <stdint.h>
#include <stdio.h>
#define FEATURE_LEPUSNG_DEBUGINFO_OUTSIDE "2.5"

typedef struct Version {
  int major, minor, revision, build;
} Version;

void VersionInit(Version* v, const char* version);
uint8_t VersionLessOrEqual(Version v1, Version other);
uint8_t IsHigherOrEqual(const char* targetV, const char* baseV);

#endif /* QUICKJS_VERSION_H */
