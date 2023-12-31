
// DLLOGE, DLLOGW, DLLOGI are enabled in release mode

#define DLLOGE( s, ... ) NSLog(@"dlLog-Error %s:%d %@", __FUNCTION__, __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__])

#define DLLOGW( s, ... ) NSLog(@"dlLog-Warning %s:%d %@", __FUNCTION__, __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__])

#define DLLOGI( s, ... ) NSLog(@"dlLog-Info %s:%d %@", __FUNCTION__, __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__])

// DLDLLOGD, DLLOGT are disabled in release mode
//#define DOWNLOADER_DEBUG
#ifdef DOWNLOADER_DEBUG

#define DLLOGD( s, ... ) NSLog(@"dlLog-Debug %s:%d %@", __FUNCTION__, __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__])

#define DLLOGT( s, ... ) NSLog(@"dlLog-Trace %s:%d %@", __FUNCTION__, __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__])

#define DLTICK  NSDate *startTime = [NSDate date]
#define DLTOCK  DLLOGD(@"dlLog-took time: %f seconds.", -[startTime timeIntervalSinceNow])

#else

#define DLLOGD( s, ... )

#define DLLOGT( s, ... )

#define DLTICK
#define DLTOCK

#endif

#define ENTER DLDLLOGD(@"dlLog-Enter.")
#define EXIT  DLDLLOGD(@"dlLog-Exit.")
