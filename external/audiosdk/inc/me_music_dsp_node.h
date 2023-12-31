//
// Created by william on 2020/6/10.
//

#pragma once

#include "me_node.h"
#include <string>
#include <atomic>

namespace Jukedeck {
    namespace MusicDSP {
        namespace Graph {
        class SourceNode;
        class INode;
        class GraphBuilder;
        class ProcessorNode;
        class GraphContainerNode;
        class RealtimeRenderingContext;
        }  // namespace Graph
    namespace Processors {
    class MidiSequencerProcessor;
    }
    }  // namespace MusicDSP
} // namespace Jukedeck


MAMMON_ENGINE_NAMESPACE_BEGIN
using namespace Jukedeck::MusicDSP;

enum class MidiEventType : uint8_t
{
    NoteOff = 128,
    NoteOn = 144,
    ControlChange = 176,
    ProgramChange = 192,
    ChannelAftertouch = 208,
    PitchBendChange = 224,
    MetaEvent = 255
};

enum class PortType
{
    Audio,
    Midi,
    ParameterChange
};

enum class PortDirection
{
    Input,
    Output
};

class MAMMON_EXPORT MDSPSubNode {
    friend class MDSPNode;
public:
    MDSPSubNode (
        std::shared_ptr<Graph::GraphBuilder> graph_builder,
        std::string const & node_id,
        std::shared_ptr<Graph::INode> subnode,
        std::shared_ptr<Processors::MidiSequencerProcessor> midi_sequencer_ptr = nullptr);

    std::shared_ptr<MDSPSubNode> connect(
                std::shared_ptr<MDSPSubNode> other,
                PortType port_type = PortType::Audio,
                int upstream_index = 0,
                int downstream_index = 0);

    void exposePort(PortDirection port_direction, PortType port_type, int node_port_index, int graph_port_index);

    std::string getNodeID();

    // Following functions can only be called when
    // the subnode is a midi-sequencer.
    // An exception will be thrown if called
    // by nodes other than midi-sequencer.
    void addNote(
                float beat_position,
                float duration,
                int pitch,
                float normalised_velocity,
                int channel);

    void deleteNote (int nodeID);
    void deleteNote(
        float beat_position,
        int pitch,
        int channel = 0);
    void clearAllNotes();

    void play();
    void stop();

    void setMaxBeats(double max_beat);
    void setIsLooping(bool is_looping = true);
    void setGrooveTimingStrength(float groove_timing_strength);
    void setGrooveVelocityStrength(float groove_velocity_strength);

    double getBeatPosition() const;
    bool isPlay() const;
    int whichLoop() const;

    bool addMidiEvent(
        int second_byte,
        int third_byte,
        double quantise_duration_beats = 0.0,
        double quantise_lateness_threshold = 0.0,
        int channel = 0);
    bool deleteMidiEvent(
        int second_byte,
        int third_byte,
        double quantise_duration_beats = 0.0,
        double quantise_lateness_threshold = 0.0,
        int channel = 0);

private:
    std::shared_ptr<Graph::GraphBuilder> graph_builder_;
    std::string node_id_;
    std::shared_ptr<Processors::MidiSequencerProcessor> midi_sequencer_ptr_;
    int midi_port_ = -1;
    bool midi_port_set_ = false;
    std::shared_ptr<Graph::RealtimeRenderingContext> graph_context_ = nullptr;
    bool is_play_ = false;
    double max_beat_ = 8;
};

class MAMMON_EXPORT MDSPNode : public Node {
public:
    static std::shared_ptr<MDSPNode> create();
    static std::shared_ptr<Graph::INode> createMDSPGraphFromFile(const std::string& json_path);
    static std::shared_ptr<Graph::INode> createMDSPGraphFromString(const std::string& json_string);

    ~MDSPNode() override = default;

    mammonengine::audiograph::NodeType type() const override {
        return mammonengine::audiograph::NodeType::MDSPNode;
    }

    Node* connect(Node* other) override;
    int process(int port, mammonengine::RenderContext& rc) override;

    std::shared_ptr<Node> getSharedPtr() override {
        return shared_from_this();
    }

    // deprecated api, will be removed in the next release
    int prepare(double sample_rate, int max_block_size);

    // deprecated api, will be removed in the next release
    bool setParameter(int port_index, int parameter_index, float normalised_parameter_value);


    bool emplaceMidiEvent (int port_index, MidiEventType type, int channel,int second_byte, int third_byte);
    bool emplaceMidiEventQuantised (
        int port_index,
        MidiEventType type,
        int channel,
        int second_byte,
        int third_byte,
        double quantise_duration_beats = 0,
        double quantise_lateness_threshold = 0);

    void setTempo(double value);

    bool dynamicParameterChange(int port_index, int parameter_index, float normalised_parameter_value);


    int loadMDSPGraph(std::shared_ptr<Graph::INode> mdsp_inode);

    void addSearchPath(std::string path);

    std::shared_ptr<MDSPSubNode> createSubNode(
                    std::string const& processor_name,
                    std::string const& build_settings_json = "{}",
                    std::string const& node_id = "");

    std::shared_ptr<MDSPSubNode> createSubNodeFromFilePath(
        std::string const & file_path,
        std::string const & node_id = "");
    std::shared_ptr<MDSPSubNode> createSubNodeFromFileURI(
        std::string const & file_uri,
        std::string const & node_id = "");

    int build();
    void saveGraphToJson(std::string const & file_name);

    // The following is about dynamicParameterChangeByName
    /**
     * @brief Load graph json from a path
     * @param path
     * @return
     */
    int loadMDSPGraphFromFile(const std::string& path);
    /**
     * @brief Load graph json from a string in memory
     * @param str
     * @return
     */
    int loadMDSPGraphFromString(const std::string& str);
    /**
     * @brief Push parameter on real time
     * @param port_idx PC port index
     * @param para_name Encoded parameter name
     * @param normalised_parameter_value Normalized float value.
     */
    bool dynamicParameterChangeByName(int port_idx, const std::string& para_name, float normalised_parameter_value);

    /**
     * @brief Get mapping list for exposed parameter
     * @return <"port_id:param", idx>
     */
    std::map<std::string, int> getParameterPortMapping() const;

    int prepareEx(NodeProcessingConfig config) override;

    // End of dynamicParameterChangeByName
private:
    MDSPNode();

    void notifyMidiNodes(std::shared_ptr<Graph::RealtimeRenderingContext> context_);

private:
    class Impl;
    std::shared_ptr<Impl> impl_;
    std::atomic<bool> prepared_{false};
    std::atomic<bool> loading_{false};
    std::shared_ptr<Graph::GraphBuilder> graph_builder_;
    static int subnode_id_;
    std::vector<std::shared_ptr<MDSPSubNode>> midi_nodes_list_ = {};
    std::shared_ptr<Graph::GraphContainerNode> graph_ = nullptr;
};
}
