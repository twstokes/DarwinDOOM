//
//  doomgeneric_objc.m
//  DarwinDOOM
//
//  Created by Tanner W. Stokes on 7/9/23.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_WATCH
#import <DarwinDOOMWatch_Watch_App-Swift.h>
#elif TARGET_OS_OSX
#import <DarwinDOOM-Swift.h>
#endif

DoomGenericSwift *dgs;
CFAbsoluteTime timeInSeconds;

#if TARGET_OS_OSX
#include <pthread.h>
#define KEY_QUEUE_SIZE 256
static int key_queue[KEY_QUEUE_SIZE];
static int key_read = 0;
static int key_write = 0;
static pthread_mutex_t key_mutex = PTHREAD_MUTEX_INITIALIZER;
#endif

void DG_Init()
{
    dgs = [DoomGenericSwift shared];
    timeInSeconds = CFAbsoluteTimeGetCurrent();
}

void DG_DrawFrame()
{
    [dgs DG_DrawFrame];
}

void DG_SleepMs(uint32_t ms)
{
    [NSThread sleepForTimeInterval:ms/1000];
}

uint32_t DG_GetTicksMs()
{
    return (CFAbsoluteTimeGetCurrent() - timeInSeconds) * 1000;
}

int DG_GetKey(int* pressed, unsigned char* doomKey)
{
    #if TARGET_OS_WATCH
    if ([TouchToKeyManager getCurrentReadIndex] == [TouchToKeyManager getCurrentWriteIndex]) {
        return 0;
    } else {
        int key = [TouchToKeyManager getNextKey];

        *pressed = key >> 8;
        *doomKey = key & 0xFF;

        return 1;
    }
    #endif

    #if TARGET_OS_OSX
    pthread_mutex_lock(&key_mutex);
    if (key_read == key_write) {
        pthread_mutex_unlock(&key_mutex);
        return 0;
    }

    int key = key_queue[key_read];
    key_read = (key_read + 1) % KEY_QUEUE_SIZE;
    pthread_mutex_unlock(&key_mutex);

    *pressed = key >> 8;
    *doomKey = key & 0xFF;
    return 1;
    #endif

    return 0;
}

void DG_SetWindowTitle(const char * title)
{
    printf("DG_SetWindowTitle called\n");
}

void DG_PushKey(int pressed, unsigned char doomKey)
{
    #if TARGET_OS_OSX
    int key = (pressed << 8) | (doomKey & 0xFF);
    pthread_mutex_lock(&key_mutex);
    int next = (key_write + 1) % KEY_QUEUE_SIZE;
    if (next != key_read) {
        key_queue[key_write] = key;
        key_write = next;
    }
    pthread_mutex_unlock(&key_mutex);
    #else
    (void)pressed;
    (void)doomKey;
    #endif
}

int DG_IsTextInputActive(void)
{
    #if TARGET_OS_OSX
    extern int saveStringEnter;
    extern int chat_on;
    return (saveStringEnter != 0) || (chat_on != 0);
    #else
    return 0;
    #endif
}

const char *DG_CopyBundledSoundFontPath(void)
{
#if TARGET_OS_OSX
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path = [bundle pathForResource:@"SoundFont" ofType:@"sf2"];
    if (path == nil)
    {
        path = [bundle pathForResource:@"FluidR3_GM" ofType:@"sf2"];
    }
    if (path == nil)
    {
        path = [bundle pathForResource:@"SoundFont" ofType:@"sf2" inDirectory:@"SoundFont"];
    }
    if (path == nil)
    {
        path = [bundle pathForResource:@"FluidR3_GM" ofType:@"sf2" inDirectory:@"SoundFont"];
    }
    if (path == nil)
    {
        NSString *dir = [[bundle resourcePath] stringByAppendingPathComponent:@"SoundFont"];
        NSArray<NSString *> *entries = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:nil];
        for (NSString *entry in entries)
        {
            if ([[entry.pathExtension lowercaseString] isEqualToString:@"sf2"])
            {
                path = [dir stringByAppendingPathComponent:entry];
                break;
            }
        }
    }
    if (path == nil)
    {
        return NULL;
    }
    return strdup([path fileSystemRepresentation]);
#else
    return NULL;
#endif
}
