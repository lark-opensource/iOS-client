//
//  vc_scene_config_manager.h

#ifndef vc_scene_config_manager_hpp
#define vc_scene_config_manager_hpp
#pragma once

#include "vc_scene.h"
#include <list>
#include <mutex>
#include <stdio.h>

VC_NAMESPACE_BEGIN

typedef std::map<std::string, std::shared_ptr<VCScene>> SceneConfigMap;
typedef std::list<std::shared_ptr<VCScene>> SceneConfigList;

class VCSceneManager final {
public:
    VCSceneManager();
    ~VCSceneManager();

public:
    void createScene(std::shared_ptr<VCScene> &config);
    void switchToScene(const std::string &sceneId);
    void destroyScene(const std::string &sceneId);
    std::shared_ptr<VCScene> getSceneConfig(const std::string &sceneId);
    std::string getCurrentSceneId();

public:
    int addMedia(const std::shared_ptr<VCMediaInfo> &mediaInfo,
                 const std::string &sceneId = std::string());
    void addPlaceholderMedia(std::shared_ptr<VCMediaInfo> &mediaInfo,
                             const std::string &sceneId = std::string());
    void removeMedia(const std::string &mediaId,
                     const std::string &sceneId = std::string());
    void removeAllMedia(const std::string &sceneId = std::string());
    void focusMedia(const std::string &mediaId, int focusType, bool isPlay);
    void playingInfo(const std::string &mediaId, const std::string &fileHash);
    std::shared_ptr<VCMediaInfo>
    getMedia(const std::string &mediaId,
             const std::string &sceneId = std::string());
    MediaInfoList allMedias(const std::string &sceneId = std::string());
    MediaInfoVector getNextMedias(const std::string &mediaId, int count = 5);
    std::shared_ptr<VCMediaInfo> getFocusMedia(void);

    int getSceneNum();
    int getAllMediasNum();

#ifdef __BUILD_FOR_DY__
public:
    int addRecord(const std::shared_ptr<VCPlayRecord> &playRecord,
                  const std::string &sceneId = std::string());
    PlayRecordList getPlayRecords(VCStrCRef sceneId = VCString());
    PlayRecordList getAllPlayRecords();
    int getTotalRecordCount(VCStrCRef sceneId);
#endif

private:
    VCScene::Ptr _getScene(VCStrCRef sceneId);

private:
    static const int k_max_scene_count = 30;

private:
    int mMaxSceneCnt{k_max_scene_count};
    SceneConfigMap mConfigMap;
    SceneConfigList mConfigList;
    std::shared_ptr<VCScene> mCurrentConfig{nullptr};
    shared_mutex mScenesMutex;
    shared_mutex mCurrentSceneMutex;

#ifdef __BUILD_FOR_DY__
private: // record
    shared_mutex mRecordMutex;
    size_t mMaxRecordSize{60};
    int mTotalRecordCount{0};
    PlayRecordList mAllPlayRecords;
#endif

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCSceneManager);
};

VC_NAMESPACE_END
#endif /* vc_scene_config_manager_hpp */
