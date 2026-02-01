//
//  i_joystick_stub.c
//  DarwinDOOM
//
//  Apple platforms do not use joystick input; provide stubs.
//

#include "i_joystick.h"

void I_InitJoystick(void) {}
void I_ShutdownJoystick(void) {}
void I_UpdateJoystick(void) {}
void I_BindJoystickVariables(void) {}
