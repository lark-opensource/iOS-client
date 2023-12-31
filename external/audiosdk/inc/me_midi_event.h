//
// Created by shidephen on 2020/5/6.
//

#ifndef MAMMONSDK_ME_MIDI_EVENT_H
#define MAMMONSDK_ME_MIDI_EVENT_H

// MIDI Event types
#define MAMMON_MIDI_NOTE_OFF 128
#define MAMMON_MIDI_NOTE_ON 144
#define MAMMON_MIDI_CONTROL_CHANGE 176
#define MAMMON_MIDI_PROGRAM_CHANGE 192
#define MAMMON_MIDI_CHANNEL_AFTER_TOUCH 208
#define MAMMON_MIDI_PITCH_BEND_CHANGE 224
#define MAMMON_MIDI_META_EVENT 255

struct mammon_midi_event {
    double time_ms;
    int event_type;
    int channel_index;
    int second_byte;
    int third_byte;
};

struct mammon_midi_note {
    double time_ms;
    double duration_ms;
    int pitch;
    int velocity;
};

#endif  // MAMMONSDK_ME_MIDI_EVENT_H
