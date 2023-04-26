
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
  *Returns True if the the user has made a successful call to TPGLClock.Start(). Otherwise, Running returns False.*  
  
- Interval: Double  
  *A time value in seconds that represents the interval at which the TPGLClock instance is to update.  
  A returned value of '1' would indicate and update interval of 1 second. A returned value of '0.5' would indicate an update interval of half a second.*  
  
- CurrentTime: Double  
  *A time value in seconds that represents that last polled time of the TPGLClock instance. The last polled time is obtained when TPGLClock.Wait() returns.*  

- LastTime: Double  
  *A time value in seconds that represents the time at the start of the TPGLClock instance's last cycle.*  
  
- TargetTime: Double  
  *A time value in seconds that represents the next earliest time that an instance of TPGLClock will return from TPGLClock.Wait(). TPGLClock can return from Wait() later than* TargetTime *if Wait() is called after the time that* TargetTime *represents.*  
