#ifndef _HDR_DETECT_EXPORT_H_
#define _HDR_DETECT_EXPORT_H_

struct ExpParams{
    int luma_min_threshold = 66;
    int luma_max_threshold = 25;
    double dayParams[8];
    double nightParams[8];
    int useDefault;
    int iso;
    int iso_min;
    int iso_max;
    double expTime;
    double expMinTime;
    double expMaxTime;
    int luma_trigger1;
    int luma_trigger2;
    int luma_trigger3;
    int luma_trigger4;
    float luma_trigger;
};

struct CaptureParams {
    int luma_trigger1;
    int luma_trigger2;
    int luma_trigger3;
    int luma_trigger4;

    int nr_minThres;
    int nr_maxThres;
    int nr_thres;

    float luma_trigger;
    float contrast_trigger;
    float dynamic_trigger;
    float over_trigger;
    float under_trigger;
};

struct IsoInfo {
    int iso;
    int iso_range_min;
    int iso_range_max;
};

class hdr_detect_export {
public:
    hdr_detect_export();
    ~hdr_detect_export();
public:
    int init(int width, int height, bool rbswap = false, bool needY = true);
    int init_exp(int width, int height);

    int detect(const unsigned char *src, int *feinfos, int fecount, int &scene, float &confidence);

    //return 0:night
    //return 1:day_normal
    //return 2:day_abnormal
    int detect(int texid, int *feinfos, int fecount, int &scene, float &confidence, int orient = 0);

    int detect_darklight(int texID, int *feinfos, int fecount, int &scene, int iso, int iso_min = 100, int iso_max = 6400,int scene_case = 0);

    int detect_exp(int texID,double &ev,double &score,ExpParams &params);

    int detect_exp(int texID,int *feinfos,int fecount,double &ev,double &score,ExpParams &params);

    //return 
    //return 
    //return 
    int detect_capture(int texID, IsoInfo &iso, CaptureParams &capture, int &needNR, int &isNight);
private:
    void *m_pdetect;    
};

#endif
