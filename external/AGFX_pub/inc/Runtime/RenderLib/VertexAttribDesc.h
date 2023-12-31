/**
 * @file VertexAttribDesc.h
 * @author Andrew Wu (andrew.wu@bytedance.com)
 * @brief vertex attribute definition
 * @version 1.0.0
 * @date 2019-11-13
 * @copyright Copyright (c) 2019 Bytedance Inc. All rights reserved.
 */
#ifndef VertexAttribDesc_h
#define VertexAttribDesc_h

#include "Gaia/AMGPrerequisites.h"
#include "Gaia/Image/AMGImageType.h"

NAMESPACE_AMAZING_ENGINE_BEGIN

/**
 * @brief vertex attribute type
 */
enum class AMGVertexAttribType
{
    POSITION = 0,       //!< position
    NORMAL,             //!< normal
    TANGENT,            //!< tangent
    COLOR,              //!< color, 0-1
    INDICES,            //!< indices
    WEIGHT,             //!< weight
    TEXCOORD0,          //!< texcoord0
    TEXCOORD1,          //!< texcoord1
    TEXCOORD2,          //!< texcoord2
    TEXCOORD3,          //!< texcoord3
    TEXCOORD4,          //!< texcoord4
    TEXCOORD5,          //!< texcoord5
    TEXCOORD6,          //!< texcoord6
    TEXCOORD7,          //!< texcoord7
    TEXCOORD3D0,        //!< texcoord3D 0
    TEXCOORD3D1,        //!< texcoord3D 1
    TEXCOORD3D2,        //!< texcoord3D 2
    TEXCOORD3D3,        //!< texcoord3D 3
    BINORMAL,           //!< binormal
    COLOR1,             //!< color1
    COLOR2,             //!< color2
    COLOR3,             //!< color3
    POSITION_OFFSET,    //!< position offset
    NORMAL_OFFSET,      //!< normal offset
    TANGENT_OFFSET,     //!< tangent offset
    BINORMAL_OFFSET,    //!< binormal offset
    USER_DEFINE0 = 100, //!< user define0
    USER_DEFINE1,       //!< user define1
    USER_DEFINE2,       //!< user define2
    USER_DEFINE3,       //!< user define3
    UNKOWN,             //!< UNKONW, must be at the end of enum
    SIZE
};

constexpr const char* toString(const AMGVertexAttribType& vertexAttribType)
{
    switch (vertexAttribType)
    {
        case AMGVertexAttribType::POSITION:
            return "POSITION";
        case AMGVertexAttribType::NORMAL:
            return "NORMAL";
        case AMGVertexAttribType::TANGENT:
            return "TANGENT";
        case AMGVertexAttribType::COLOR:
            return "COLOR";
        case AMGVertexAttribType::INDICES:
            return "INDICES";
        case AMGVertexAttribType::WEIGHT:
            return "WEIGHT";
        case AMGVertexAttribType::TEXCOORD0:
            return "TEXCOORD0";
        case AMGVertexAttribType::TEXCOORD1:
            return "TEXCOORD1";
        case AMGVertexAttribType::TEXCOORD2:
            return "TEXCOORD2";
        case AMGVertexAttribType::TEXCOORD3:
            return "TEXCOORD3";
        case AMGVertexAttribType::TEXCOORD4:
            return "TEXCOORD4";
        case AMGVertexAttribType::TEXCOORD5:
            return "TEXCOORD5";
        case AMGVertexAttribType::TEXCOORD6:
            return "TEXCOORD6";
        case AMGVertexAttribType::TEXCOORD7:
            return "TEXCOORD7";
        case AMGVertexAttribType::TEXCOORD3D0:
            return "TEXCOORD3D0";
        case AMGVertexAttribType::TEXCOORD3D1:
            return "TEXCOORD3D1";
        case AMGVertexAttribType::TEXCOORD3D2:
            return "TEXCOORD3D2";
        case AMGVertexAttribType::TEXCOORD3D3:
            return "TEXCOORD3D3";
        case AMGVertexAttribType::BINORMAL:
            return "BINORMAL";
        case AMGVertexAttribType::COLOR1:
            return "COLOR1";
        case AMGVertexAttribType::COLOR2:
            return "COLOR2";
        case AMGVertexAttribType::COLOR3:
            return "COLOR3";
        case AMGVertexAttribType::POSITION_OFFSET:
            return "POSITION_OFFSET";
        case AMGVertexAttribType::NORMAL_OFFSET:
            return "NORMAL_OFFSET";
        case AMGVertexAttribType::TANGENT_OFFSET:
            return "TANGENT_OFFSET";
        case AMGVertexAttribType::BINORMAL_OFFSET:
            return "BINORMAL_OFFSET";
        case AMGVertexAttribType::USER_DEFINE0:
            return "USER_DEFINE0T";
        case AMGVertexAttribType::USER_DEFINE1:
            return "USER_DEFINE1";
        case AMGVertexAttribType::USER_DEFINE2:
            return "USER_DEFINE2";
        case AMGVertexAttribType::USER_DEFINE3:
            return "USER_DEFINE3";
        default:
            return "UNKOWN";
    }
}

/**
 * @brief vertex attribute
 */
class AMAZING_EXPORT VertexAttrib
{
public:
    /// get component count
    uint32_t getComponentCount() const { return m_Attrib_Type != AMGVertexAttribType::UNKOWN ? ComponentCountMap()[(int)m_Attrib_Type] : m_Component_Count; }
    /// set component case AMGVertexAttribType::count : return "count"; valid when m_Attrib_Type is AMGVertexAttribType::UNKOWN
    void setComponentCount(uint32_t count) { m_Component_Count = count; }

    /// get component size
    uint32_t getComponentSize() const { return sizeof(float); }

    /// get data type
    AMGDataType getDataType() const { return m_Type; }
    /// set data type
    void setDataType(AMGDataType type) { m_Type = type; }

    /// set attribute type
    void setAttribType(AMGVertexAttribType type) { m_Attrib_Type = type; }
    /// get attribute type
    AMGVertexAttribType getAttribType() const { return m_Attrib_Type; }
    /// set attribute offset
    void setAttribOffset(int32_t offset) { m_Attrib_offset = offset; }
    /// get attribute offset
    int32_t getAttribOffset() const { return m_Attrib_offset; }

    /// set attribute binding index
    void setAttribBindingIndex(int32_t index) { m_Attrib_binding_index = index; }
    /// get attribute binding index
    int32_t getAttribBindingIndex() const { return m_Attrib_binding_index; }

    /// set attribute binding name
    void setAttribBindingName(const std::string& name) { m_Name = name; }
    /// get attribute binding name
    const std::string& getAttribBindingName() const { return m_Name; }

private:
    // 属性分量数映射表 | Attribute component number mapping table
    static const uint32_t* ComponentCountMap();
    // 属性偏移 | Attribute offset
    int32_t m_Attrib_offset = 0;
    // 属性绑定序号 | Property binding sequence number
    int32_t m_Attrib_binding_index = 0;

    // 属性类型 | Attribute type
    AMGVertexAttribType m_Attrib_Type = AMGVertexAttribType::SIZE;

    // valid when type is unknown
    uint32_t m_Component_Count = 0;

    std::string m_Name = "";
    AMGDataType m_Type = AMGDataType::F32;
};

NAMESPACE_AMAZING_ENGINE_END

#endif
