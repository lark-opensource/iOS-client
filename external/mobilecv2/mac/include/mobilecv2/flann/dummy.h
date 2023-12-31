
#ifndef MOBILECV2_FLANN_DUMMY_H_
#define MOBILECV2_FLANN_DUMMY_H_

namespace mobilecv2flann
{

#if (defined WIN32 || defined _WIN32 || defined WINCE) && defined CVAPI_EXPORTS
__declspec(dllexport)
#endif
void dummyfunc();

}


#endif  /* OPENCV_FLANN_DUMMY_H_ */
