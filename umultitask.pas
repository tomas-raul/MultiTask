unit uMultiTask;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,

  {$IF defined(windows)}
  Windows,
  {$ELSEIF defined(freebsd) or defined(darwin)}
  ctypes, sysctl,
  {$ELSEIF defined(linux)}
  {$linklib c}
  ctypes,
  {$ENDIF}
  uMultiTaskQueue;

type
  tMultiTask = class;
  tMultiTaskThread = class;
  tOn_Task_Start_Proc = procedure(const task: tMultiTaskItem);
  tOn_Task_Start_Method = procedure(const method_name: string;
    const task: tMultiTaskItem) of object;
  tOn_BeforeAfter_Task_Method = procedure(const task: tMultiTaskItem;
    const thrd: tMultiTaskThread) of object;

  { tMultiTaskThread }

  tMultiTaskThread = class(tThread)
  private
    fID: integer;
    fMultiTask: tMultiTask;
    fHaveNewWork: PRTLEvent;
    fWorking: boolean;

    procedure _Working;
    procedure _Sleeping;
  public
    constructor Create(MultiTask: tMultiTask);
    destructor Destroy(); override;
    procedure Execute; override;

    function Working: boolean;

    procedure Wake_Up_For_New_Work();
    procedure Sleep_To_New_Work();

    property ID: integer read fID;

  end;

  { tMultiTask }

  tMultiTask = class
  private
    fOn_Before_Task_Method: tOn_BeforeAfter_Task_Method;
    fOn_After_Task_Method: tOn_BeforeAfter_Task_Method;
    fOn_Task_Run_Method: tOn_Task_Start_Method;
    fOn_Task_Run_Proc: tOn_Task_Start_Proc;
    fPriorities_Enabled: boolean;
    fTask_Queue: tMultiTaskQueue;
    fTThreadPriority: TThreadPriority;
    gefOn_Task_Run_Method: tOn_Task_Start_Method;
    fPin_Thread_To_Core: boolean;
    fThread_Count: byte;
    fAsync_Run: boolean;
    fAnyThreadDoneWork: PRTLEvent;
    function Any_Thread_Working: boolean;
    function getCores_Count: byte;
    procedure setAsync_Run(AValue: boolean);
    procedure setOn_Task_Run_Method(AValue: tOn_Task_Start_Method);
    procedure setOn_Task_Run_Proc(AValue: tOn_Task_Start_Proc);
    procedure setPin_Thread_To_Core(AValue: boolean);
    procedure setThread_Count(AValue: byte);
    procedure setTThreadPriority(AValue: TThreadPriority);
    procedure Update_Thread_Configs;
    procedure On_New_Task_Enqeued;
  protected
    fThreadList: TList;

    procedure Thread_Work(thrd: tMultiTaskThread);
  public
    constructor Create;
    destructor Destroy; override;

    procedure Start;
    procedure Stop;
    procedure WaitFor;

    procedure Enqueue(const proc: tTaskProc; const params: array of const; const flags : tMultitaskEnQueueFlags = [teLast]);
    procedure Enqueue(const method: tTaskMethod; const params: array of const; const flags : tMultitaskEnQueueFlags = [teLast]);

    property Cores_Count: byte read getCores_Count;
    property Thread_Count: byte read fThread_Count write setThread_Count;
    property Pin_Thread_To_Core: boolean read fPin_Thread_To_Core
      write setPin_Thread_To_Core;
    property Thread_Priorities: TThreadPriority
      read fTThreadPriority write setTThreadPriority;
    property Async_Run: boolean read fAsync_Run write setAsync_Run;
    property Priorities_Enabled : boolean read fPriorities_Enabled write fPriorities_Enabled;

    property On_Before_Task_Method: tOn_BeforeAfter_Task_Method
      read fOn_Before_Task_Method write fOn_Before_Task_Method;
    property On_After_Task_Method: tOn_BeforeAfter_Task_Method
      read fOn_After_Task_Method write fOn_After_Task_Method;

    property Task_Queue: tMultiTaskQueue read fTask_Queue;

    // slouzi k nastaveni parametru dane metody, bez teto definice se vsechny tasky spousti bez parametru !
    property On_Task_Run_Proc: tOn_Task_Start_Proc
      read fOn_Task_Run_Proc write setOn_Task_Run_Proc;
    property On_Task_Run_Method: tOn_Task_Start_Method
      read fOn_Task_Run_Method write setOn_Task_Run_Method;
  end;

implementation

{$IFDEF LOG}
uses
  uLog_v4;
{$ENDIF}

{ tMultiTaskThread }

constructor tMultiTaskThread.Create(MultiTask: tMultiTask);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  fHaveNewWork := RTLEventCreate;
  fMultiTask := MultiTask;
end;

destructor tMultiTaskThread.Destroy;
begin
  RTLeventdestroy(fHaveNewWork);
  inherited Destroy;
end;

procedure tMultiTaskThread.Execute;
begin
  while not Terminated do
    fMultiTask.Thread_Work(self);
end;

procedure tMultiTaskThread._Sleeping;
begin
  fWorking := False;
end;

procedure tMultiTaskThread.Sleep_To_New_Work;
begin
  RtlEventWaitFor(fHaveNewWork, 1000);
  RTLeventResetEvent(fHaveNewWork);
end;

procedure tMultiTaskThread.Wake_Up_For_New_Work;
begin
  RtlEventSetEvent(fHaveNewWork);
end;

function tMultiTaskThread.Working: boolean;
begin
  Result := fWorking;
end;

procedure tMultiTaskThread._Working;
begin
  fWorking := True;
end;

{ tMultiTask }

constructor tMultiTask.Create;
begin
  inherited;
  fAnyThreadDoneWork := RTLEventCreate;
  fThreadList := TList.Create;
  fTask_Queue := tMultiTaskQueue.Create;
  fTask_Queue.On_New_Task := @On_New_Task_Enqeued;
  fPriorities_Enabled:=true;
  Thread_Count := Cores_Count;
  Pin_Thread_To_Core := False;
  Update_Thread_Configs;
end;

destructor tMultiTask.Destroy;
begin
  RTLeventdestroy(fAnyThreadDoneWork);
  fThreadList.Free;
  inherited Destroy;
end;

procedure tMultiTask.Enqueue(const method: tTaskMethod; const params: array of const; const flags: tMultitaskEnQueueFlags);
var fl : tMultitaskEnQueueFlags;
begin
  fl := flags;
  if not fPriorities_Enabled then
   fl -= [teFirst,teHighPriority,teNormalPriority,teLowPriority,teLast];

  fTask_Queue.Enqueue(method, params, fl);
end;

procedure tMultiTask.Enqueue(const proc: tTaskProc; const params: array of const; const flags: tMultitaskEnQueueFlags);
var fl : tMultitaskEnQueueFlags;
begin
  fl := flags;
  if not fPriorities_Enabled then
   fl -= [teFirst,teHighPriority,teNormalPriority,teLowPriority,teLast];

  fTask_Queue.Enqueue(proc, params, fl);
end;

{$IFDEF Linux}
const
  _SC_NPROCESSORS_ONLN = 83;

function sysconf(i: cint): clong; cdecl; external Name 'sysconf';
{$ENDIF}

function tMultiTask.getCores_Count: byte;
{$IF defined(windows)}
var
  i: integer;
  ProcessAffinityMask, SystemAffinityMask: DWORD_PTR;
  Mask: DWORD;
  SystemInfo: SYSTEM_INFO;
{$ENDIF}
begin
{$IF defined(windows)}
  //returns total number of processors available to system including logical hyperthreaded processors
  begin
    if GetProcessAffinityMask(GetCurrentProcess, ProcessAffinityMask,
      SystemAffinityMask) then
    begin
      Result := 0;
      for i := 0 to 31 do
      begin
        Mask := DWord(1) shl i;
        if (ProcessAffinityMask and Mask) <> 0 then
          Inc(Result);
      end;
    end
    else
    begin
      //can't get the affinity mask so we just report the total number of processors
      GetSystemInfo(SystemInfo);
      Result := SystemInfo.dwNumberOfProcessors;
    end;
  end;
{$ELSEIF defined(linux)}
  begin
    Result := sysconf(_SC_NPROCESSORS_ONLN);
  end;

{$ELSE}
  begin
    Result := 1;
  end;
{$ENDIF}
end;

procedure tMultiTask.On_New_Task_Enqeued;
var
  i: byte;
  thrd: tMultiTaskThread;
begin
  for i := 0 to fThreadList.Count - 1 do
  begin
    thrd := tMultiTaskThread(fThreadList[i]);
    thrd.Wake_Up_For_New_Work();
  end;
end;

procedure tMultiTask.setAsync_Run(AValue: boolean);
begin
  if fAsync_Run = AVAlue then
    Exit;
  fAsync_Run := AVAlue;
end;

procedure tMultiTask.setOn_Task_Run_Method(AValue: tOn_Task_Start_Method);
begin
  if fOn_Task_Run_Method = AValue then
    Exit;
  fOn_Task_Run_Method := AValue;
  fOn_Task_Run_Proc := nil;
end;

procedure tMultiTask.setOn_Task_Run_Proc(AValue: tOn_Task_Start_Proc);
begin
  if fOn_Task_Run_Proc = AValue then
    Exit;
  fOn_Task_Run_Proc := AValue;
  fOn_Task_Run_Method := nil;
end;

procedure tMultiTask.setPin_Thread_To_Core(AValue: boolean);
begin
  fPin_Thread_To_Core := True;
  Update_Thread_Configs;
end;

procedure tMultiTask.setThread_Count(AValue: byte);
begin
  if fThread_Count = AValue then
    Exit;
  fThread_Count := AValue;
  Update_Thread_Configs;
end;

procedure tMultiTask.setTThreadPriority(AValue: TThreadPriority);
var
  i: byte;
  thrd: tMultiTaskThread;
begin
  if fTThreadPriority = AValue then
    Exit;
  fTThreadPriority := AValue;
  for i := 0 to fThreadList.Count - 1 do
  begin
    thrd := tMultiTaskThread(fThreadList[i]);
    thrd.Priority := AValue;
  end;
end;

procedure tMultiTask.Start;
var
  i: byte;
  thrd: tMultiTaskThread;
begin
  for i := 0 to fThreadList.Count - 1 do
  begin
    thrd := tMultiTaskThread(fThreadList[i]);
    thrd.Start();
  end;
end;

procedure tMultiTask.Stop;
var
  i: byte;
  thrd: tMultiTaskThread;
begin
  for i := 0 to fThreadList.Count - 1 do
  begin
    thrd := tMultiTaskThread(fThreadList[i]);
    thrd.Wake_Up_For_New_Work();
    thrd.Terminate();
  end;
end;

procedure tMultiTask.Thread_Work(thrd: tMultiTaskThread);
var
  task: tMultiTaskItem;
begin
  task := fTask_Queue.DeQueue;
  while task <> nil do
  begin
    try
      thrd._Working();
      try
        if assigned(fOn_Before_Task_Method) then
          fOn_Before_Task_Method(task, thrd);
      finally
      end;

      try
        if assigned(fOn_Task_Run_Method) then
        begin
          if task.Name <> '' then
            fOn_Task_Run_Method(task.Name, task)
          else
            Stop;
        end
        else
        if assigned(fOn_Task_Run_Proc) then
          fOn_Task_Run_Proc(task)
        else
          Stop;

        try
          if assigned(fOn_After_Task_Method) then
            fOn_After_Task_Method(task, thrd);
        finally
        end;
      except
        on E: Exception do
        begin
          {$IFDEF LOG}
          Log('Exception in task  ' + task.AsPascalSourceString +
            ' !!! ' + E.Message + ' !!!');
          {$ENDIF}
        end;
      end;
    finally
      thrd._Sleeping();
      RtlEventSetEvent(fAnyThreadDoneWork);
    end;
    task := fTask_Queue.DeQueue;
  end;
  thrd.Sleep_To_New_Work();
end;

procedure tMultiTask.Update_Thread_Configs;
var
  i: integer;
  thrd: tMultiTaskThread;
begin
  if fThreadList.Count <> fThread_Count then
  begin
    for i := 0 to fThreadList.Count - 1 do
    begin
      thrd := tMultiTaskThread(fThreadList[i]);
      // mozna chyba, zkusit opravit
      thrd.Terminate;
      thrd.WaitFor;
      thrd.Free;
    end;

    for i := 1 to fThread_Count do
    begin
      thrd := tMultiTaskThread.Create(self);
      thrd.fID := i;
      fThreadList.Add(thrd);
    end;
  end;
end;

function tMultiTask.Any_Thread_Working: boolean;
var
  i: integer;
  thrd: tMultiTaskThread;
begin
  Result := False;
  for i := 0 to fThreadList.Count - 1 do
  begin
    thrd := tMultiTaskThread(fThreadList[i]);
    if thrd.Working then
      Exit(True);
  end;
end;

procedure tMultiTask.WaitFor;
begin
  while (fTask_Queue.Count > 0) or Any_Thread_Working do
  begin
    RtlEventWaitFor(fAnyThreadDoneWork, 1000);
    On_New_Task_Enqeued();
  end;
end;

end.
