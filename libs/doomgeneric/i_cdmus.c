//
//  i_cdmus.c
//  DarwinDOOM
//
//  CD audio is not supported on Apple platforms.
//

#include "doomtype.h"
#include "i_cdmus.h"

int cd_Error;

int I_CDMusInit(void)
{
    cd_Error = 0;
    return 0;
}

void I_CDMusPrintStartup(void)
{
}

int I_CDMusPlay(int track)
{
    (void)track;
    return 0;
}

int I_CDMusStop(void)
{
    return 0;
}

int I_CDMusResume(void)
{
    return 0;
}

int I_CDMusSetVolume(int volume)
{
    (void)volume;
    return 0;
}

int I_CDMusFirstTrack(void)
{
    return 0;
}

int I_CDMusLastTrack(void)
{
    return 0;
}

int I_CDMusTrackLength(int track)
{
    (void)track;
    return 0;
}
