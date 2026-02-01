//
//  i_avfmusic.mm
//  DarwinDOOM
//
//  AVFoundation-backed music module for iOS/watchOS.
//

extern "C" {
#include "config.h"
#include "doomtype.h"
#include "i_sound.h"
#include "m_misc.h"
#include "memio.h"
#include "mus2mid.h"
}

#if defined(__APPLE__)
#import <TargetConditionals.h>
#endif

#if TARGET_OS_IOS
#import <AVFoundation/AVFoundation.h>

static boolean music_initialized = false;
static boolean music_looping = false;
static int music_volume = 127;

@interface DGMusicHandle : NSObject
@property(nonatomic, strong) AVMIDIPlayer *player;
@property(nonatomic, copy) NSString *tempPath;
@end

@implementation DGMusicHandle
@end

static DGMusicHandle *current_handle = nil;

extern "C" const char *DG_CopyBundledSoundFontPath(void);

static NSURL *DG_SoundFontURL(void)
{
    const char *path = DG_CopyBundledSoundFontPath();
    if (path == NULL) {
        fprintf(stderr, "AVF music: no bundled soundfont found.\n");
        return nil;
    }
    NSString *nsPath = [NSString stringWithUTF8String:path];
    free((void *) path);
    fprintf(stderr, "AVF music: using soundfont at %s\n", nsPath.UTF8String);
    return [NSURL fileURLWithPath:nsPath];
}

static boolean I_AVF_InitMusic(void)
{
    @autoreleasepool {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSError *error = nil;
        [session setCategory:AVAudioSessionCategoryPlayback error:&error];
        [session setActive:YES error:&error];
    }
    music_initialized = true;
    return true;
}

static void I_AVF_ShutdownMusic(void)
{
    @autoreleasepool {
        NSError *error = nil;
        [[AVAudioSession sharedInstance] setActive:NO error:&error];
    }
    music_initialized = false;
}

static void I_AVF_SetMusicVolume(int volume)
{
    music_volume = volume;
}

static void I_AVF_PauseMusic(void)
{
    if (current_handle && current_handle.player) {
        [current_handle.player stop];
    }
}

static void I_AVF_ResumeMusic(void)
{
    DGMusicHandle *h = current_handle;
    if (h && h.player) {
        [h.player play:^{
            if (music_looping && current_handle == h) {
                I_AVF_ResumeMusic();
            }
        }];
    }
}

static void *I_AVF_RegisterSong(void *data, int len)
{
    if (!music_initialized || data == NULL || len <= 0) {
        return NULL;
    }

    NSData *midiData = nil;

    // MUS\x1a header check
    if (len >= 4 && ((const unsigned char *)data)[0] == 'M'
        && ((const unsigned char *)data)[1] == 'U'
        && ((const unsigned char *)data)[2] == 'S'
        && ((const unsigned char *)data)[3] == 0x1a)
    {
        MEMFILE *in = mem_fopen_read(data, (size_t)len);
        MEMFILE *out = mem_fopen_write();
        if (mus2mid(in, out)) {
            mem_fclose(in);
            mem_fclose(out);
            fprintf(stderr, "AVF music: mus2mid conversion failed.\n");
            return NULL;
        }
        void *buf = NULL;
        size_t buflen = 0;
        mem_get_buf(out, &buf, &buflen);
        midiData = [NSData dataWithBytes:buf length:buflen];
        mem_fclose(in);
        mem_fclose(out);
    }
    else
    {
        midiData = [NSData dataWithBytes:data length:(NSUInteger)len];
    }

    if (midiData == nil) {
        fprintf(stderr, "AVF music: MIDI data is nil.\n");
        return NULL;
    }

    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"doom_%@.mid", [[NSUUID UUID] UUIDString]]];
    if (![midiData writeToFile:tempPath atomically:YES]) {
        fprintf(stderr, "AVF music: failed to write temp MIDI file.\n");
        return NULL;
    }

    NSURL *midiURL = [NSURL fileURLWithPath:tempPath];
    NSURL *soundFontURL = DG_SoundFontURL();

    NSError *error = nil;
    AVMIDIPlayer *player = [[AVMIDIPlayer alloc] initWithContentsOfURL:midiURL soundBankURL:soundFontURL error:&error];
    if (player == nil || error != nil) {
        if (error != nil) {
            fprintf(stderr, "AVF music: AVMIDIPlayer init failed: %s\n", error.localizedDescription.UTF8String);
        } else {
            fprintf(stderr, "AVF music: AVMIDIPlayer init failed with unknown error.\n");
        }
        // Try a fallback with no sound bank in case the system provides one.
        error = nil;
        player = [[AVMIDIPlayer alloc] initWithContentsOfURL:midiURL soundBankURL:nil error:&error];
        if (player == nil || error != nil) {
            if (error != nil) {
                fprintf(stderr, "AVF music: fallback init failed: %s\n", error.localizedDescription.UTF8String);
            }
            return NULL;
        }
    }

    DGMusicHandle *handle = [DGMusicHandle new];
    handle.player = player;
    handle.tempPath = tempPath;
    return (__bridge_retained void *)handle;
}

static void I_AVF_UnRegisterSong(void *handle)
{
    if (handle == NULL) { return; }
    DGMusicHandle *h = (__bridge_transfer DGMusicHandle *)handle;
    if (h.tempPath.length > 0) {
        [[NSFileManager defaultManager] removeItemAtPath:h.tempPath error:nil];
    }
}

static void I_AVF_PlaySong(void *handle, boolean looping)
{
    if (handle == NULL) { return; }
    DGMusicHandle *h = (__bridge DGMusicHandle *)handle;
    current_handle = h;
    music_looping = looping;
    h.player.currentPosition = 0;
    [h.player play:^{
        if (music_looping && current_handle == h) {
            I_AVF_PlaySong(handle, looping);
        }
    }];
}

static void I_AVF_StopSong(void)
{
    music_looping = false;
    if (current_handle && current_handle.player) {
        [current_handle.player stop];
        current_handle.player.currentPosition = 0;
    }
}

static boolean I_AVF_MusicIsPlaying(void)
{
    if (!current_handle || !current_handle.player) { return false; }
    return current_handle.player.isPlaying;
}

static void I_AVF_MusicPoll(void)
{
    // no-op
}

static snddevice_t music_avf_devices[] = {
    SNDDEVICE_GENMIDI,
    SNDDEVICE_GUS,
    SNDDEVICE_AWE32,
    SNDDEVICE_SOUNDCANVAS,
    SNDDEVICE_SB,
};

music_module_t DG_music_module =
{
    music_avf_devices,
    (int)(sizeof(music_avf_devices) / sizeof(music_avf_devices[0])),
    I_AVF_InitMusic,
    I_AVF_ShutdownMusic,
    I_AVF_SetMusicVolume,
    I_AVF_PauseMusic,
    I_AVF_ResumeMusic,
    I_AVF_RegisterSong,
    I_AVF_UnRegisterSong,
    I_AVF_PlaySong,
    I_AVF_StopSong,
    I_AVF_MusicIsPlaying,
    I_AVF_MusicPoll,
};

#elif TARGET_OS_WATCH
// watchOS: no MIDI support yet; provide a no-op music module.

static boolean I_AVF_InitMusic(void)
{
    return false;
}

static void I_AVF_ShutdownMusic(void)
{
}

static void I_AVF_SetMusicVolume(int volume)
{
    (void)volume;
}

static void I_AVF_PauseMusic(void)
{
}

static void I_AVF_ResumeMusic(void)
{
}

static void *I_AVF_RegisterSong(void *data, int len)
{
    (void)data;
    (void)len;
    return NULL;
}

static void I_AVF_UnRegisterSong(void *handle)
{
    (void)handle;
}

static void I_AVF_PlaySong(void *handle, boolean looping)
{
    (void)handle;
    (void)looping;
}

static void I_AVF_StopSong(void)
{
}

static boolean I_AVF_MusicIsPlaying(void)
{
    return false;
}

static void I_AVF_MusicPoll(void)
{
}

static snddevice_t music_avf_devices[] = {
    SNDDEVICE_GENMIDI,
    SNDDEVICE_GUS,
    SNDDEVICE_AWE32,
    SNDDEVICE_SOUNDCANVAS,
    SNDDEVICE_SB,
};

music_module_t DG_music_module =
{
    music_avf_devices,
    (int)(sizeof(music_avf_devices) / sizeof(music_avf_devices[0])),
    I_AVF_InitMusic,
    I_AVF_ShutdownMusic,
    I_AVF_SetMusicVolume,
    I_AVF_PauseMusic,
    I_AVF_ResumeMusic,
    I_AVF_RegisterSong,
    I_AVF_UnRegisterSong,
    I_AVF_PlaySong,
    I_AVF_StopSong,
    I_AVF_MusicIsPlaying,
    I_AVF_MusicPoll,
};

#endif // TARGET_OS_IOS / TARGET_OS_WATCH
