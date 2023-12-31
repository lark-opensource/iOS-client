#ifdef __cplusplus
#pragma once
#include "Bach/Base/BachAlgorithmBuffer.h"

#include "Gaia/AMGPrimitiveVector.h"
#include "Gaia/AMGRefBase.h"
#include "Gaia/AMGSharePtr.h"

NAMESPACE_BACH_BEGIN

class AMAZING_EXPORT NaviAvatarDriveInfo : public AmazingEngine::RefBase
{
public:
    // A floating point vector to store the 52 blendshape weights.
    AmazingEngine::FloatVector blendshapeWeights;

    // A 4x4 matrix that transforms the face geometry from its original (object)
    // coordinate system to the camera coordinate system.
    AmazingEngine::Matrix4x4f modelView;
};

class AMAZING_SDK_EXPORT NaviAvatarDriveBuffer : public BachBuffer
{
public:
    // Assume that we just have one NaviAvatarDriveInfo to return now e.g. we
    // only process facial animation data for a single user.
    AmazingEngine::SharePtr<NaviAvatarDriveInfo> m_naviAvatarDrive;
};

NAMESPACE_BACH_END
#endif