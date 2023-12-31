#pragma once

//Save Midi Stream Option for SaveMidiToFile
#define MIDI_SAVING_OPTION_DEFAULT (-1)

#ifdef __X_NATIVE__
#include "..\stdx.h"

#else

#include <stdint.h>
#include <inttypes.h>

typedef uint8_t BYTE;

#ifndef _MINWINDEF_
typedef uint32_t DWORD;
#endif

typedef uint16_t WORD;

#ifndef __cplusplus

typedef uint8_t bool;
#define true 1
#define false 0

#endif

#include <stdio.h>

//int ReadNoMSBNumber32(FILE* File, DWORD* Value);
void WriteNoMSBNumber32(FILE* File, DWORD Value);

#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef BYTE MIDI_CHANNEL;
typedef int8_t MIDI_VALUE;
typedef int16_t MIDI_VALUE_COMBINED;
typedef int64_t MIDI_TICK;
typedef long double MIDI_TIME;

typedef long double MIDI_FLOAT;

#pragma pack(push,1)

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wpragmas"
#pragma GCC diagnostic ignored "-Wgnu-anonymous-struct"
#pragma GCC diagnostic ignored "-Wpedantic"
#pragma GCC diagnostic ignored "-Wnested-anon-types"

typedef union MIDI_DUAL_VALUE
{
    MIDI_VALUE_COMBINED Value;
    struct SEPARATED_DUAL
    {
        MIDI_VALUE MSB:7;
        MIDI_VALUE LSB:7;
    } SeparatedDual;
} MIDI_DUAL_VALUE;

typedef struct MIDI_EVENT
{
	int Length;
    union
    {
        void* Data;
        char* DataAsString;
        BYTE* DataAsBytes;
    };
	union
	{
		DWORD Event;
		BYTE Events[4];
		struct
		{
			BYTE MetaKind;
			BYTE SubKind;
		};
		struct
		{
			MIDI_CHANNEL Channel:4;
			BYTE Kind:4;
			union
			{
				MIDI_VALUE Values[3];
				struct
				{
					MIDI_VALUE Note;
					MIDI_VALUE Velocity;
				};
				struct
				{
					MIDI_VALUE Key;
					MIDI_VALUE KeyPressure;
				};
				struct
				{
					MIDI_VALUE Controller;
					MIDI_VALUE ControlValue;
				};
				MIDI_VALUE Program;
				MIDI_VALUE ChannlePressure;
                MIDI_DUAL_VALUE Wheel;
			};
		};
	};
} MIDI_EVENT;

#pragma GCC diagnostic pop

typedef struct MIDI_CHUNK
{
	DWORD DeltaTime;	
	MIDI_EVENT Event;
} MIDI_CHUNK;


typedef struct MIDI_TRACK
{
	int ChunkCount;
	MIDI_CHUNK* Chunks;
} MIDI_TRACK;

typedef struct MIDI_HEADER
{
	int8_t Format;
	WORD TimeBase;
	WORD TrackCount;
} MIDI_HEADER;


typedef struct
{
    MIDI_TICK Tick;
    MIDI_TIME Time; // Microseconds
    MIDI_FLOAT BPM; // Beats per Minute
} TEMPO_CHUNK;

typedef struct
{
    MIDI_TICK Tick;
    WORD BPM; //Beats per Measure, A
    WORD Beat;    //B
    WORD Measure;
} MBT_CHUNK;


typedef struct MIDI_STREAM
{
  MIDI_HEADER Header;
  MIDI_TRACK* Tracks;
  int TempoTrackSize;
  TEMPO_CHUNK* TempoTrack;
  int MBTTrackSize;
  MBT_CHUNK* MBTTrack;
} MIDI_STREAM;

//Other Information
typedef struct MIDI_TRACK_INFO
{
	char* Name;
	MIDI_CHANNEL Channel;
	MIDI_VALUE Program;
    MIDI_VALUE BankH;
    MIDI_VALUE BankL;
	MIDI_VALUE Volume;
	MIDI_VALUE Pan;
    MIDI_TICK Offset;
} MIDI_TRACK_INFO;

typedef struct MIDI_MBT
{
	int Measure;
	int Beat;
	int Tick;
} MIDI_MBT;

typedef struct HMSF 
{
	int FPS;
	int Hour;
	BYTE Minute;
	BYTE Second;
	int Frame;
} HMSF;

#pragma pack(pop)

//Midi
MIDI_STREAM* CreateMidiStream(void);
void DestroyMidiStream(MIDI_STREAM* MidiStream);

MIDI_STREAM* LoadMidiFromFile(const char* FileName);
MIDI_STREAM* LoadMidiFromMem(const void* Content, int Size);

bool SaveMidiToFile(const MIDI_STREAM* MidiStream, const char* FileName, int8_t Format);

MIDI_STREAM* ChangeMidiFormat(const MIDI_STREAM* MidiStream, int8_t Format);

void RefreshMidiStream(MIDI_STREAM* MidiStream);

// Internal API, use with care
void MidiStreamFixEOT(MIDI_STREAM* MidiStream);

//Call if you change tempo or add/del events with delta-time
void DirtyMidiStream(MIDI_STREAM* MidiStream);

//Time
WORD GetMidiTimeBase(const MIDI_STREAM* MidiStream);
void SetMidiTimeBase(MIDI_STREAM* MidiStream,WORD TimeBase,bool ChangeTick);

MIDI_TICK GetMidiLength(const MIDI_STREAM* MidiStream); 

//Track
void RemoveEmptyMidiTrack(MIDI_STREAM* MidiStream);

int GetMidiTracks(const MIDI_STREAM* MidiStream);

MIDI_TRACK* GetMidiTrack(const MIDI_STREAM* MidiStream, int Index);
MIDI_TRACK* AddMidiTrack(MIDI_STREAM* MidiStream);

void RemoveMidiTracks(MIDI_STREAM* MidiStream);
void RemoveMidiTrack(MIDI_STREAM* MidiStream,int Index);
void DestroyMidiTrack(MIDI_TRACK* MidiTrack);

MIDI_TICK GetMidiTrackLength(const MIDI_TRACK* MidiTrack);


//Chunk (Event)
void RemoveMidiEvent(MIDI_TRACK* MidiTrack,int Index);
void DestroyMidiEvent(MIDI_CHUNK* MidiChunk);

int GetMidiTrackEvents(const MIDI_TRACK* MidiTrack);

MIDI_CHUNK* AddMidiEvent(MIDI_TRACK* MidiTrack);
MIDI_CHUNK* InsertMidiEvent(MIDI_TRACK* MidiTrack, MIDI_TICK Tick);

int GetMidiEventAtTick(const MIDI_TRACK* MidiTrack, MIDI_TICK Tick, DWORD* Distance);
MIDI_CHUNK* GetMidiEvent(const MIDI_TRACK* MidiTrack, int Index);

MIDI_TICK GetMidiEventOffset(const MIDI_TRACK* MidiTrack, int Index);

//Kind
int GetMidiEventLengthFromKind(MIDI_EVENT *event);

//Event
void ClearMidiEvent(MIDI_EVENT* MidiEvent);
void DupMidiEvent(MIDI_EVENT* Dst,const MIDI_EVENT* Src);

//MIDI Message
void SetMidiNoteOn(MIDI_EVENT* MidiEvent, MIDI_CHANNEL Channel, MIDI_VALUE Note, MIDI_VALUE Velocity);
void SetMidiNoteOff(MIDI_EVENT* MidiEvent, MIDI_CHANNEL Channel, MIDI_VALUE Note);
void SetMidiKeyAfter(MIDI_EVENT* MidiEvent, MIDI_CHANNEL Channel, MIDI_VALUE Key, MIDI_VALUE KeyPressure);
void SetMidiController(MIDI_EVENT* MidiEvent, MIDI_CHANNEL Channel, MIDI_VALUE Controller,MIDI_VALUE ControlValue);
void SetMidiProgram(MIDI_EVENT* MidiEvent, MIDI_CHANNEL Channel, MIDI_VALUE Program);
void SetMidiChannelPressure(MIDI_EVENT* MidiEvent, MIDI_CHANNEL Channel, MIDI_VALUE ChannlePressure);
void SetMidiWheel(MIDI_EVENT* MidiEvent, MIDI_CHANNEL Channel, MIDI_VALUE_COMBINED Wheel);

void SetMidiWheel2(MIDI_EVENT* MidiEvent, MIDI_CHANNEL Channel, MIDI_VALUE Wheel_MSB,MIDI_VALUE Wheel_LSB);
void SetMidiNoteOff2(MIDI_EVENT* MidiEvent, MIDI_CHANNEL Channel, MIDI_VALUE Note,MIDI_VALUE Velocity);

void SetMidiRPN(MIDI_TRACK* MidiTrack, MIDI_CHANNEL Channel, 
				MIDI_VALUE_COMBINED RPN,MIDI_VALUE_COMBINED Value);

void SetMidiRPN4(MIDI_TRACK* MidiTrack, MIDI_CHANNEL Channel, 
				 MIDI_VALUE RPN_MSB,MIDI_VALUE RPN_LSB,
				 MIDI_VALUE Value_MSB,MIDI_VALUE Value_LSB);

void SetMidiNRPN(MIDI_TRACK* MidiTrack, MIDI_CHANNEL Channel, 
				 MIDI_VALUE_COMBINED NRPN,MIDI_VALUE_COMBINED Value);

void SetMidiNRPN4(MIDI_TRACK* MidiTrack, MIDI_CHANNEL Channel, 
				 MIDI_VALUE NRPN_MSB,MIDI_VALUE NRPN_LSB,
				 MIDI_VALUE Value_MSB,MIDI_VALUE Value_LSB);

void SetMidiChannel(MIDI_EVENT* MidiEvent, MIDI_CHANNEL Channel);
MIDI_CHANNEL GetMidiEventChannel(const MIDI_EVENT* Event);

void SetMidiNonMetaEvent(MIDI_EVENT* MidiEvent, MIDI_CHANNEL Channel, int Type, MIDI_VALUE Second, MIDI_VALUE Third);

bool IsMidiNote(const MIDI_EVENT* Event);
bool IsMidiNoteOn(const MIDI_EVENT* Event);
bool IsMidiNoteOff(const MIDI_EVENT* Event);
bool IsMidiProgram(const MIDI_EVENT* Event);
bool IsMidiKeyAfter(const MIDI_EVENT* Event);
bool IsMidiChannelPressure(const MIDI_EVENT* Event);
bool IsMidiController(const MIDI_EVENT* Event);
bool IsMidiWheel(const MIDI_EVENT* Event);

// MIDI_DUAL_VALUE
double MidiDualValue2Double(const MIDI_DUAL_VALUE* dv);

// Special Events
bool IsMidiEotEvent(const MIDI_EVENT* Event);


//Meta Event
void SetMidiMetaEvent(MIDI_EVENT* MidiEvent,BYTE SubKind,DWORD Length,const void* Data);
bool IsMidiMetaEvent(const MIDI_EVENT* Event);

//Tempo
void SetMidiTempo(MIDI_EVENT* MidiEvent,double BPM);
double GetMidiTempo(const MIDI_EVENT* MidiEvent);
bool IsMidiTempoEvent(const MIDI_EVENT* Event);


//MBT, TimeSignature
MBT_CHUNK* GetMidiMeasureSignature(const MIDI_STREAM* MidiStream, int Measure);
bool IsMidiTimeSignatureEvent(const MIDI_EVENT* Event);
bool GetMidiTimeSignature(const MIDI_EVENT* Event, int* Numerator, int* Denominator);
void SetMidiTimeSignature(MIDI_EVENT* MidiEvent, int Numerator, int Denominator);
bool GetMidiTimeSignatureWithExtension(const MIDI_EVENT* Event, int* Numerator, int* DirectDenominator, int* ClocksPerClick, int* Num32ndsPerQuarter);
void SetMidiTimeSignatureWithExtension(MIDI_EVENT* MidiEvent, int Numerator, int DirectDenominator, int ClocksPerClick, int Num32ndsPerQuarter);

//KeySignature
bool IsMidiKeySignatureEvent(const MIDI_EVENT* Event);
bool GetMidiKeySignature(const MIDI_EVENT* Event, int* SharpsOrFlats, bool* IsMinor);
void SetMidiKeySignature(MIDI_EVENT* MidiEvent, int SharpsOrFlats, bool IsMinor);

//Sysx
bool IsMidiSysx(const MIDI_EVENT* MidiEvent);
void SetMidiSysx(MIDI_EVENT* MidiEvent, const char* Sysx, int Length);
int GetSysxLength(const MIDI_EVENT* MidiEvent);
int GetSysxData(const MIDI_EVENT* MidiEvent, char* Sysx);
bool IsSysxMatching(const unsigned char* Sysx, const unsigned char* MatchStr);

uint8_t* BuildSysxFromShort7Bits(int *Length, const unsigned char *Binary7, int BinLen, const char *SyncWords);
uint8_t* ExtractShort7BitsFromMidiEvent(int *Length, MIDI_EVENT *MidiEvent, const char *SyncWords);

//Text, return length if Parameter 'Text' is NULL
int GetMidiTextLength(const MIDI_EVENT* MidiEvent);

int MidiEventToText(const MIDI_EVENT* MidiEvent, char* Text);
void TextToMidiEvent(MIDI_EVENT* MidiEvent, const char* Text);

int GetMidiTitle(MIDI_STREAM* MidiStream, char* Text);
int GetMidiSubTitle(MIDI_STREAM* MidiStream, char* Text);
int GetMidiCopyright(MIDI_STREAM* MidiStream, char* Text);
int GetMidiMemo(MIDI_STREAM* MidiStream, char* Text);

int GetMidiTrackName(const MIDI_TRACK* MidiTrack, char* Text);

void SetMidiTrackName(MIDI_TRACK* MidiTrack, char* Text);

bool IsMidiLyricEvent(const MIDI_EVENT* MidiEvent);
bool IsMidiTrackName(const MIDI_EVENT* MidiEvent);
bool IsMidiMarkerEvent(const MIDI_EVENT* MidiEvent);

void SetMidiTitle(const MIDI_STREAM* MidiStream, const char* Text);
void SetMidiSubTitle(const MIDI_STREAM* MidiStream, const char* Text);
void SetMidiCopyright(const MIDI_STREAM* MidiStream, const char* Text);
void SetMidiMemo(const MIDI_STREAM* MidiStream, const char* Text);


//Time Conversion
DWORD MidiBeatToTick(const MIDI_STREAM* MidiStream,double Beat);
MIDI_TIME MidiTickToSeconds(MIDI_STREAM* MidiStream, MIDI_TICK Tick); //May Refresh
bool IsMidiDirty(const MIDI_STREAM* MidiStream);
MIDI_TICK MBTToMidiTick(const MIDI_STREAM* MidiStream, const MIDI_MBT* MBT);
const MBT_CHUNK* MidiTickToMBT(MIDI_STREAM* MidiStream, MIDI_MBT* MBT, MIDI_TICK Tick);

//MIP

void ClearMidiMip(MIDI_STREAM* MidiStream);
void ConfigMidiMip(MIDI_STREAM* MidiStream, const MIDI_CHANNEL* Channels, const MIDI_VALUE* MIP, int Count);

//Misc
MIDI_TRACK_INFO* GetMidiTrackInfo(const MIDI_TRACK* MidiTrack);
void SetMidiTrackInfo(MIDI_TRACK* MidiTrack, const MIDI_TRACK_INFO* Info);

MIDI_TICK GetMidiNoteDuration(const MIDI_TRACK* MidiTrack, int Index);

void MidiNoteToText(char* Text, MIDI_VALUE Note);

void SecondsToHMSF(HMSF* HMSF, MIDI_TIME Time);
MIDI_TICK MSecondToMidiTick(const MIDI_STREAM* MidiStream, MIDI_TIME Time);

void FreeMidiTrackInfo(MIDI_TRACK_INFO* TrackInfo);

//Crypto

bool EncryptMidiStream(MIDI_STREAM* MidiStream, const char* Extra);
void DecryptMidiStream(MIDI_STREAM* MidiStream);


#ifdef __cplusplus
}
#endif
