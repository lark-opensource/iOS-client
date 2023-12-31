#ifndef DEBUGROUTER_EVENTS_H_
#define DEBUGROUTER_EVENTS_H_

namespace debugrouter {
namespace protocol {

constexpr const char *kDebugStateConnecting =
    "{\"event\": \"debugState\", \"data\": \"connecting\"}";
constexpr const char *kDebugStateConnected =
    "{\"event\": \"debugState\", \"data\": \"connected\"}";
constexpr const char *kDebugStateDisconnected =
    "{\"event\": \"debugState\", \"data\": \"disconnected\"}";

constexpr const char *kStopAtEntryEnable =
    "{\"event\": \"stopAtEntry\", \"data\": true}";
constexpr const char *kStopAtEntryDisable =
    "{\"event\": \"stopAtEntry\", \"data\": false}";

constexpr const char *kEventType4OpenCard = "openCard";

constexpr const char *kInvalidTempalteUrl = "___UNKNOWN___";

} // namespace protocol
} // namespace debugrouter

#endif
