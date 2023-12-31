//
// Created by lvzhuliang on 2020/5/7.
//

#ifndef MAMMONSDK_ME_AMBISONIC_ROTATOR_NODE_H
#define MAMMONSDK_ME_AMBISONIC_ROTATOR_NODE_H

#include "me_node.h"
#include "geometry/me_geometry.h"

MAMMON_ENGINE_NAMESPACE_BEGIN
class AmbisonicRotatorNode : public Node {
public:
    // Constructor
    explicit AmbisonicRotatorNode(int order);

    static std::shared_ptr<AmbisonicRotatorNode> create(int order);
    int process(int port, RenderContext& rc) override;
    bool cleanUp() override {
        return true;
    };
    std::shared_ptr<Node> getSharedPtr() override {
        return shared_from_this();
    };
    audiograph::NodeType type() const override {
        return audiograph::NodeType::AmbisonicRotatorNode;
    }

    /*set rotation
     *
     * positive X: right
     * positive Y: up
     * positive Z: back (out of screen)
     *
     * roll: rotation around axis x, counterclockwise in plane yz
     * pitch: rotation around axis y, counterclockwise in plane xz
     * yaw: rotation around aix z, counterclockwise in plane xy
     * */
    void setRotation(float roll, float pitch, float yaw);

    int getOrder() {
        return order_;
    }

private:
    int order_;
    WorldRotation source_rotation_;
    WorldPosition temp_world_position_;
    WorldPosition temp_rotated_world_position_;
};
}

#endif  // MAMMONSDK_ME_AMBISONIC_ROTATOR_NODE_H
