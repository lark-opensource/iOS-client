//
// Created by shidephen on 2020/5/6.
//

#pragma once
#ifndef MAMMONSDK_ME_MIDI_READER_H
#define MAMMONSDK_ME_MIDI_READER_H
#include "mammon_audio_io_defs.h"
#include <string>
#include <vector>
#include "me_midi_event.h"

namespace mammonengine{
/**
 * Read MIDI events from a MIDI file
 * @param path MIDI file path
 * @param track_idx track index to read
 * @return
 */
MAMMON_EXPORT std::vector<mammon_midi_event> readMidiEventsFromFile(const std::string& path, size_t track_idx = 0);

/**
 * Read notes from a MIDI file
 * @param path MIDI file path
 * @param track_idx track index to read
 * @return
 */
MAMMON_EXPORT std::vector<mammon_midi_note> readMidiNotesFromFile(const std::string& path, size_t track_idx = 0,
                                                                  bool truncate = true);

}

#endif  // MAMMONSDK_ME_MIDI_READER_H
