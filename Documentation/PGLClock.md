
## PGLClock.pas

### -- Description --

The PGLClock.pas unit provides functionality for time-keeping and timed-events. It uses the platform's high-resolution timer functions (QueryPerformanceFrequency and QueryPerformanceCounter on Windows).

#### Types
- TPGLClock - Class
- TPGLEvent - Class
- TPGLClockEvent - Procedure
- TPGLTriggerType - Enum

### TPGLClock

#### Overview
TPGLClock provides the user with a way to keep track of the passage of time and control the interval at which execution of other code happens. Additionally, the TPGLClock can "store" instanes of TPGLEvent, to be executed at designated times and intervals.

#### Properties
- Running: Boolean  
  Returns a True/False values based on whether or not the user has "started" the clock with a successful call to TPGLClock.Start().
