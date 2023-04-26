
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
- **Running: Boolean** *Read Only*  
  *Returns True if the the user has made a successful call to TPGLClock.Start(). Otherwise, Running returns False.*  
  
- **Interval: Double** *Read Only*  
  *A time value in seconds that represents the interval at which the TPGLClock instance is to update.  
  A returned value of '1' would indicate and update interval of 1 second. A returned value of '0.5' would indicate an update interval of half a second.*  
  
- **CurrentTime: Double** *Read Only*  
  *A time value in seconds that represents that last polled time of the TPGLClock instance. The last polled time is obtained when TPGLClock.Wait() returns.*  

- **LastTime: Double** *Read Only*  
  *A time value in seconds that represents the time at the start of the TPGLClock instance's last cycle.*  
  
- **TargetTime: Double** *Read Only*  
  *A time value in seconds that represents the next earliest time that an instance of TPGLClock will return from TPGLClock.Wait(). TPGLClock can return from Wait() later than* **TargetTime** *if Wait() is called after the time that* **TargetTime** *represents.*  
  
- **CycleTime: Double** *Read Only*  
  *The amount of time in seconds of the last completed cycle of a TPGLClock instance. This is computed as* `TPGLClock.CurrentTime - TPGLClock.LastTime` *when TPGLClock returns from Wait() and values are updated.*  
  
- **ElapsedTime: Double** *Read Only*  
  *A time value in seconds that represents how long an instance of TPGLClock has been running since the last call to TPGLClock.Start().*  
  
- **FPS: Double** *Read Only*  
  *The average number of cycles that the instance of TPGLClock completed over the last second. TPGLClock keeps a private count of the number of cycles and the amount of time since the previous update to* **FPS** *, and updates it when that time is >= 1 second.* **FPS** *is calculated as* `TPGLClock.fFrames / TPGLClock.fFrameTime` *, where fFrames is the number of cycles and fFrameTime is the amount of time elapsed since the last update to* **FPS** *.*      
