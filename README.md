# MultiTask
FreePascal Multitask library

Very simple to use MultiTask library for FreePascal.

<b>Some properties :</b>
- Simple
- FPC Windows/Linux compatible
- Add task on run - you can enqueue task anytime
- Priorities of task - you can add task priority - that's not thread priority, but place in the TaskQueue - tpFirst,tpHigh,tpNormal,tpLow,tpLast (default)
- Priorities can be globaly disabled
- Tasks is normal Threads


<b>Some properties (planed, in near future) :</b>
- Pin Threads to cores
- Before build method compilation - aplication which will build On_New_Work, and some methods directly 
 


<b>Initialization of library :</b>

  MultiTask := tMultiTask.Create;
  MultiTask.On_Task_Run_Method:=@On_New_Work;    // main method of set parameters to NORMAL methods/procedures
  MultiTask.On_Before_Task_Method:=@__On_Before_Task_Method;
  MultiTask.On_After_Task_Method:=@__On_After_Task_Method;


<b>Finalization :</b>

  MultiTask.Free;


<b>Main Work :</b>

  <add tasks to queue possible here>
  MultiTask.Start;
  <add another tasks to queue possible here>
  MultiTask.WaitFor;

<b>Example of On_New_Work method :</b>
procedure tmyObject.On_New_Work(const method_name: string; const task: tMultiTaskItem);
begin
   case method_name of
     'load_image' : Load_Image(task.I[1],task.S[2]);
     'save_image' : Save_Image(task.I[1],task.S[2],tBGRABitmap(task.O[3]));
   end; 
end;


<b>Enqueue task to queue :</b>

for enqueue method :

procedure tMyObject.Load_Image(const id : integer; const fn: string);
var img : tBGRABitmap;
begin
   img := tBGRABitmap.Create(fn);
   MultiTask.Enqueue(tTaskMethod(@Save_Image),[id,fn,img],[tpHigh]); // enqueue Load_Image method with param ID and filename with HighPriority
end;

use this :

MultiTask.Enqueue(tTaskMethod(@Load_Image),[id,fn],[tpHigh]); // enqueue Load_Image method with param ID and filename with HighPriority


 <b>What is :</b>
 
 MultiTask - main class for automated running any task
 Task - simple method or procedure, simply doing some work - as normal method or procedure
 
 <b>What to see :</b>
 
 Memory managment - When you enqeueue task with some objects as parameters, do not free this objects BEFORE task end - simple free this object near task end
 
 
<b>Tested on :</b>
Ubuntu 16.10 - crosscompile from Windows, FPC 3.0.0, Lazarus 1.6.3
Ubuntu 17.04 - crosscompile from Windows, FPC 3.0.0, Lazarus 1.6.3
Windows 8.1 - partial test, compiled on Windows, FPC 3.0.0, Lazarus 1.6.3
 
