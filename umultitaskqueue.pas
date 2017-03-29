unit uMultiTaskQueue;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  uCS;

type
  tMultiTaskQueue = class;
  tTaskProc = procedure;
  tTaskMethod = procedure of object;
  tOn_New_Task = procedure of object;

  tTaskPriority = (tpFirst, tpHigh, tpNormal, tpLow, tpLast);

  tMultitaskEnQueueFlag = (teUnique, teFirst, teHighPriority, teNormalPriority,
    teLowPriority, teLast);
  tMultitaskEnQueueFlags = set of tMultitaskEnQueueFlag;

  { tMultiTaskItem }

  tMultiTaskItem = class
  private
    fName: string;
    fParamsAsPascalString: string;
    fTaskMethod: tTaskMethod;
    fDestObj : tObject;
    fTaskProc: tTaskProc;
    function getAnsiString(const i: integer): ansistring;
    function getboolean(const i: integer): boolean;
    function getchar(const i: integer): char;
    function getCurrency(const i: integer): currency;
    function getExtended(const i: integer): extended;
    function getInt64(const i: integer): int64;
    function getInteger(const i: integer): integer;
    function getinterface(const id: integer): pointer;
    function getnextAnsiString: ansistring;
    function getnextB: boolean;
    function getnextchar: char;
    function getnextClass: tClass;
    function getnextCurrency: currency;
    function getnextExtended: extended;
    function getnextI: integer;
    function getnextInt64: int64;
    function getnextO: TObject;
    function getnextPChar: PChar;
    function getnextS: string;
    function getnextVariant: variant;
    function getPChar(const i: integer): PChar;
    function getString(const i: integer): string;
    function gettClass(const i: integer): tClass;
    function gettObject(const i: integer): TObject;
    function getVariant(const i: integer): variant;
  protected
    fPriority: tTaskPriority;
    fInteger: array of integer;
    fBoolean: array of boolean;
    fChar: array of char;
    fExtended: array of extended;
    fString: array of string;
    fPChar: array of PChar;
    ftObject: array of TObject;
    ftClass: array of tClass;
    fAnsiString: array of ansistring;
    fCurrency: array of currency;
    fVariant: array of variant;
    fInt64: array of int64;
    fInterface: array of IUnknown;

    fBeforeRun, fAfterRun: tMultiTaskItem;

    fparamid: integer;

  public
    constructor Create; overload;
    constructor Create(const proc: tTaskProc; const method: tTaskMethod;
      const params: array of const; const proc_before: tTaskProc = nil;
      const method_before: tTaskMethod = nil; const params_before: array of const;
      const proc_after: tTaskProc = nil; const method_after: tTaskMethod = nil;
      const params_after: array of const; const obj : tObject = nil); overload;
    constructor Create(const proc: tTaskProc; const method: tTaskMethod;
      const params: array of const; const obj : tObject = nil); overload;
    destructor Destroy; override;

    procedure SetParams(const Data: array of const);

    function AsPascalSourceString: string;

    property Method: tTaskMethod read fTaskMethod;
    property DestinationObject : tObject read fDestObj;
    property Proc: tTaskProc read fTaskProc;

    property nextI: integer read getnextI;
    property nextB: boolean read getnextB;
    property nextChar: char read getnextchar;
    property nextExtended: extended read getnextExtended;
    property nextS: string read getnextS;
    property nextPChar: PChar read getnextPChar;
    property nextO: TObject read getnextO;
    property nextClass: tClass read getnextClass;
    property nextAnsiString: ansistring read getnextAnsiString;
    property nextCurrency: currency read getnextCurrency;
    property nextVariant: variant read getnextVariant;
    property nextI64: int64 read getnextInt64;

    property I[const id: integer]: integer read getInteger;
    property int[const id: integer]: pointer read getinterface;
    property ParBoolean[const id: integer]: boolean read getboolean;
    property ParChar[const id: integer]: char read getchar;
    property ParExtended[const id: integer]: extended read getExtended;
    property S[const id: integer]: string read getString;
    property ParPChar[const id: integer]: PChar read getPChar;
    property O[const id: integer]: TObject read gettObject;
    property ParClass[const id: integer]: tClass read gettClass;
    property ParAnsiString[const id: integer]: ansistring read getAnsiString;
    property ParCurrency[const id: integer]: currency read getCurrency;
    property ParVariant[const id: integer]: variant read getVariant;
    property I64[const id: integer]: int64 read getInt64;

  published
    property Name: string read fName write fName;
    property Priority: tTaskPriority read fPriority;
  end;

  { tMultiTaskQueue }

  tMultiTaskQueue = class
    type
    pQueueItem = ^tQueueItem;

    tQueueItem = record
      Item: tMultiTaskItem;
      Next: pQueueItem;
    end;
  private
    fFirst, fLast: pQueueItem;
    fCount: integer;
    CS: tCS;
    fOn_New_Task: tOn_New_Task;

    procedure Enqueue(const Data: tMultiTaskItem; const flags: tMultitaskEnQueueFlags);
    procedure EnqueueFirst(const Data: tMultiTaskItem; const OnlyUnique: boolean);
    procedure EnqueuePriority(const Data: tMultiTaskItem; const tp: tTaskPriority; const OnlyUnique: boolean);
    procedure EnqueueLast(const Data: tMultiTaskItem; const OnlyUnique: boolean);

    procedure setOn_New_Task(AValue: tOn_New_Task);
    function _Exists(const Data: tMultiTaskItem): boolean;
    function _Exists_Or_Running(const Data: tMultiTaskItem): boolean;

    function _FindFirstTaskWithPriority(const tp: tTaskPriority): pQueueItem;
  protected
    fMultiTask: TObject;
  public
    constructor Create(MultiTask: TObject);
    destructor Destroy; override;


    procedure Enqueue(const proc: tTaskProc; const method: tTaskMethod; const params: array of const; const proc_before: tTaskProc;
      const method_before: tTaskMethod; const params_before: array of const; const proc_after: tTaskProc; const method_after: tTaskMethod;
  const params_after: array of const; const flags: tMultitaskEnQueueFlags; const obj : tObject = nil);
    procedure Enqueue(const proc: tTaskProc; const params: array of const;
      const flags: tMultitaskEnQueueFlags = [teLast]);
    procedure Enqueue(const method: tTaskMethod; const params: array of const;
      const flags: tMultitaskEnQueueFlags = [teLast]; const obj : tObject = nil);

    procedure Clear;
    function DeQueue(const thrd : tObject): tMultiTaskItem;
    function Length: integer;
    function Exists(const Data: tMultiTaskItem): boolean;

    function HaveWork: boolean;

    property MultiTask: TObject read fMultiTask;
    property On_New_Task: tOn_New_Task read fOn_New_Task write setOn_New_Task;

  end;

implementation

uses TypInfo,
  uMultiTask
{$IFDEF MemoryLimitPossibility}
  ,uMemory
{$ENDIF}
  ;

{ tMultiTaskItem }

constructor tMultiTaskItem.Create(const proc: tTaskProc; const method: tTaskMethod; const params: array of const; const obj: tObject);
begin
  Create(proc, method, params, nil, nil, [], nil, nil, [],obj);
end;

constructor tMultiTaskItem.Create(const proc: tTaskProc; const method: tTaskMethod; const params: array of const; const proc_before: tTaskProc;
  const method_before: tTaskMethod; const params_before: array of const; const proc_after: tTaskProc; const method_after: tTaskMethod;
  const params_after: array of const; const obj: tObject);
var
  before, after: tMultiTaskItem;
  _class: tClass;

begin
  Create;
  fTaskProc := Proc;
  fTaskMethod := Method;
  fDestObj := obj;

  if method <> nil then
  begin
    _class := TObject(tMethod(fTaskMethod).Data).ClassType;
    fName := lowercase(_class.MethodName(tMethod(fTaskMethod).Code));
  end
  else
    fName := '';

  SetParams(params);

  if (proc_before <> nil) or (method_before <> nil) then
    before := tMultiTaskItem.Create(proc_before, method_before,
      params_before, nil, nil, [], nil, nil, [])
  else
    before := nil;

  if (proc_after <> nil) or (method_after <> nil) then
    after := tMultiTaskItem.Create(proc_after, method_after, params_after,
      nil, nil, [], nil, nil, [])
  else
    after := nil;

  fBeforeRun := before;
  fAfterRun := after;
end;

constructor tMultiTaskItem.Create;
begin
  inherited;
  fTaskProc := nil;
  fTaskMethod := nil;
  fPriority := tpLast;
end;

function tMultiTaskItem.AsPascalSourceString: string;
begin
  Result := fName + '(' + fParamsAsPascalString + ');';
end;

destructor tMultiTaskItem.Destroy;
begin
  SetLength(fInteger, 0);
  SetLength(fBoolean, 0);
  SetLength(fChar, 0);
  SetLength(fExtended, 0);
  SetLength(fString, 0);
  SetLength(fPChar, 0);
  SetLength(ftObject, 0);
  SetLength(ftClass, 0);
  SetLength(fString, 0);
  SetLength(fCurrency, 0);
  SetLength(fVariant, 0);
  SetLength(fInt64, 0);
  SetLength(fInterface, 0);
  inherited Destroy;
end;

function tMultiTaskItem.getAnsiString(const i: integer): ansistring;
begin
  Result := default(ansistring);
  if i <= Length(fAnsiString) then
    Result := fAnsiString[i - 1];
end;

function tMultiTaskItem.getboolean(const i: integer): boolean;
begin
  Result := default(boolean);
  if i <= Length(fboolean) then
    Result := fboolean[i - 1];
end;

function tMultiTaskItem.getchar(const i: integer): char;
begin
  Result := default(char);
  if i <= Length(fChar) then
    Result := fChar[i - 1];
end;

function tMultiTaskItem.getCurrency(const i: integer): currency;
begin
  Result := default(currency);
  if i <= Length(fCurrency) then
    Result := fCurrency[i - 1];
end;

function tMultiTaskItem.getExtended(const i: integer): extended;
begin
  Result := default(extended);
  if i <= Length(fExtended) then
    Result := fExtended[i - 1];
end;

function tMultiTaskItem.getInt64(const i: integer): int64;
begin
  Result := default(int64);
  if i <= Length(fInt64) then
    Result := fInt64[i - 1];
end;

function tMultiTaskItem.getInteger(const i: integer): integer;
begin
  Result := default(integer);
  if i <= Length(finteger) then
    Result := finteger[i - 1];
end;

function tMultiTaskItem.getinterface(const id: integer): pointer;
begin
  Result := default(Pointer);
  if id <= Length(finterface) then
    Result := finterface[id - 1];
end;

function tMultiTaskItem.getnextAnsiString: ansistring;
begin
  Result := self.ParAnsiString[fparamid];
  Inc(fparamid);
end;

function tMultiTaskItem.getnextB: boolean;
begin
  Result := self.ParBoolean[fparamid];
  Inc(fparamid);
end;

function tMultiTaskItem.getnextchar: char;
begin
  Result := self.ParChar[fparamid];
  Inc(fparamid);
end;

function tMultiTaskItem.getnextClass: tClass;
begin
  Result := self.ParClass[fparamid];
  Inc(fparamid);
end;

function tMultiTaskItem.getnextCurrency: currency;
begin
  Result := self.ParCurrency[fparamid];
  Inc(fparamid);
end;

function tMultiTaskItem.getnextExtended: extended;
begin
  Result := self.ParExtended[fparamid];
  Inc(fparamid);
end;

function tMultiTaskItem.getnextI: integer;
begin
  Result := self.I[fparamid];
  Inc(fparamid);
end;

function tMultiTaskItem.getnextInt64: int64;
begin
  Result := self.I64[fparamid];
  Inc(fparamid);
end;

function tMultiTaskItem.getnextO: TObject;
begin
  Result := self.O[fparamid];
  Inc(fparamid);
end;

function tMultiTaskItem.getnextPChar: PChar;
begin
  Result := self.ParPChar[fparamid];
  Inc(fparamid);
end;

function tMultiTaskItem.getnextS: string;
begin
  Result := self.S[fparamid];
  Inc(fparamid);
end;

function tMultiTaskItem.getnextVariant: variant;
begin
  Result := self.ParVariant[fparamid];
  Inc(fparamid);
end;

function tMultiTaskItem.getPChar(const i: integer): PChar;
begin
  Result := default(PChar);
  if i <= Length(fPChar) then
    Result := fPChar[i - 1];
end;

function tMultiTaskItem.getString(const i: integer): string;
begin
  Result := default(string);
  if i <= Length(fString) then
    Result := fString[i - 1];
end;

function tMultiTaskItem.gettClass(const i: integer): tClass;
begin
  Result := default(tClass);
  if i <= Length(ftClass) then
    Result := ftClass[i - 1];
end;

function tMultiTaskItem.gettObject(const i: integer): TObject;
begin
  Result := default(TObject);
  if i <= Length(ftObject) then
    Result := ftObject[i - 1];
end;

function tMultiTaskItem.getVariant(const i: integer): variant;
begin
  Result := default(variant);
  if i <= Length(fVariant) then
    Result := fVariant[i - 1];
end;

procedure tMultiTaskItem.SetParams(const Data: array of const);
var
  p: integer;
begin
  p := length(Data);
  SetLength(fInteger, p);
  SetLength(fBoolean, p);
  SetLength(fChar, p);
  SetLength(fExtended, p);
  SetLength(fString, p);
  SetLength(fPChar, p);
  SetLength(ftObject, p);
  SetLength(ftClass, p);
  SetLength(fString, p);
  SetLength(fCurrency, p);
  SetLength(fVariant, p);
  SetLength(fInt64, p);
  SetLength(fInterface, p);

  fParamsAsPascalString := '';
  for p := low(Data) to high(Data) do
  begin
    case Data[p].VType of
      vtInteger:
      begin
        fInteger[p] := Data[p].VInteger;
        fParamsAsPascalString += IntToStr(fInteger[p]) + ',';
      end;
      vtBoolean:
      begin
        fBoolean[p] := Data[p].VBoolean;
        if fBoolean[p] then
          fParamsAsPascalString += 'true,'
        else
          fParamsAsPascalString += 'false,';
      end;
      vtChar:
      begin
        fChar[p] := Data[p].VChar;
        fParamsAsPascalString += '''' + fChar[p] + ''',';
      end;
      vtExtended:
      begin
        fExtended[p] := Data[p].VExtended^;
        fParamsAsPascalString += FloatToStr(fExtended[p]) + ',';
      end;
      vtString:
      begin
        fString[p] := Data[p].VString^;
        fParamsAsPascalString += '''' + fString[p] + ''',';
      end;
      vtPChar:
      begin
        fPChar[p] := Data[p].VPChar;
        fParamsAsPascalString += '''' + fPChar[p] + ''',';
      end;
      vtObject:
      begin
        ftObject[p] := Data[p].VObject;
        if ftObject[p] = nil then
          fParamsAsPascalString += 'object:nil,'
        else
          fParamsAsPascalString += 'object:' + ftObject[p].ClassName + ',';
      end;
      vtClass:
      begin
        ftClass[p] := Data[p].VClass;
        if ftClass[p] = nil then
          fParamsAsPascalString += 'class:nil,'
        else
          fParamsAsPascalString += 'class:' + ftClass[p].ClassName + ',';
      end;
      vtAnsiString:
      begin
        fString[p] := ansistring(Data[p].VAnsiString);
        fParamsAsPascalString += '''' + fString[p] + ''',';
      end;
      vtCurrency:
      begin
        fCurrency[p] := Data[p].VCurrency^;
        fParamsAsPascalString += FloatToStr(fCurrency[p]) + ',';
      end;
      vtVariant:
      begin
        fVariant[p] := Data[p].VVariant^;
        fParamsAsPascalString += fVariant[p] + ',';
      end;
      vtInt64:
      begin
        fInt64[p] := Data[p].VInt64^;
        fParamsAsPascalString += IntToStr(fInt64[p]) + ',';
      end;
      vtInterface:
      begin
        fInterface[p] := IUnknown(Data[p].VInterface);
        if fInterface[p] = nil then
          fParamsAsPascalString += 'interface:nil,'
        else
          fParamsAsPascalString += 'interface,';
      end;
    end;
  end;
  fParamsAsPascalString := copy(fParamsAsPascalString, 1,
    length(fParamsAsPascalString) - 1);
  fparamid := 1;
end;

constructor tMultiTaskQueue.Create(MultiTask: TObject);
begin
  inherited Create;
  fFirst := nil;
  fLast := nil;
  fCount := 0;
  CS := InitCS;
  fMultiTask := MultiTask;
end;

destructor tMultiTaskQueue.Destroy;
begin
  DoneCS(CS);
  inherited Destroy;
end;

function tMultiTaskQueue._FindFirstTaskWithPriority(
  const tp: tTaskPriority): pQueueItem;
var
  tmp: pQueueItem;
begin
  tmp := fFirst;
  while tmp^.Next <> nil do
  begin
    if (tmp^.Next <> nil) and (tmp^.Next^.Item.Priority > tp) then
      Exit;
    tmp := tmp^.Next;
  end;
  Result := tmp;
end;

procedure tMultiTaskQueue.EnqueuePriority(const Data: tMultiTaskItem; const tp: tTaskPriority; const OnlyUnique: boolean);
var
  QueueItem, tmpItem, after : pQueueItem;
begin
  New(QueueItem);
  QueueItem^.Item := Data;
  QueueItem^.Next := nil;

  EnterCS(CS, 'Enqueue task item');
  try
    if OnlyUnique and _Exists_Or_Running(Data) then
    begin
      Dispose(QueueItem);
      Exit;
    end;

    fCount += 1;
    if (fFirst = nil) then
    begin
      fFirst := QueueItem;
      fLast := QueueItem;
    end
    else
    if (fLast = nil) then
    begin
      raise Exception.Create(
        'EnqueuePriority - Queue.fLast is nil and fFirst not - this should not be !! ');
      Halt;
    end
    else
    begin
      if fFirst^.Item.Priority > tp then
      begin
        tmpItem := fFirst;
        QueueItem^.Next := tmpItem;
        fFirst := QueueItem;
      end
      else
      begin
        after := _FindFirstTaskWithPriority(tp);

        if after = nil then
        begin
          fLast^.Next := QueueItem;
          fLast := QueueItem;
        end
        else
        if after^.Next = nil then
        begin
          fLast^.Next := QueueItem;
          fLast := QueueItem;
        end
        else
        begin
          tmpItem := after^.Next;
          after^.Next := QueueItem;
          QueueItem^.Next := tmpItem;
        end;
      end;
    end;
  finally
    LeaveCS(CS);
    if Assigned(fOn_New_Task) then
      fOn_New_Task();
  end;
end;

procedure tMultiTaskQueue.EnqueueFirst(const Data: tMultiTaskItem; const OnlyUnique: boolean);
var
  QueueItem, before: pQueueItem;
begin
  New(QueueItem);
  QueueItem^.Item := Data;
  QueueItem^.Next := nil;

  EnterCS(CS, 'Enqueue task item');
  try
    if OnlyUnique and _Exists_Or_Running(Data) then
    begin
      Dispose(QueueItem);
      Exit;
    end;
    fCount += 1;
    if (fFirst = nil) then
    begin
      fFirst := QueueItem;
      fLast := QueueItem;
    end
    else
    if (fLast = nil) then
    begin
      raise Exception.Create(
        'EnqueueFirst - Queue.fLast is nil and fFirst not - this should not be !! ');
      Halt;
    end
    else
    begin
      before := fFirst;
      QueueItem^.Next := before;
      fFirst := QueueItem;
      if fFirst^.Next = nil then
        fLast := fFirst;
    end;
  finally
    LeaveCS(CS);
    if Assigned(fOn_New_Task) then
      fOn_New_Task();
  end;
end;

procedure tMultiTaskQueue.EnqueueLast(const Data: tMultiTaskItem; const OnlyUnique: boolean);
var
  QueueItem: pQueueItem;
begin

  New(QueueItem);
  QueueItem^.Item := Data;
  QueueItem^.Next := nil;

  EnterCS(CS, 'Enqueue task item');
  try
    if OnlyUnique and _Exists_Or_Running(Data) then
    begin
      Dispose(QueueItem);
      Exit;
    end;
    fCount += 1;
    if (fFirst = nil) then
    begin
      fFirst := QueueItem;
      fLast := QueueItem;
    end
    else
    if (fLast = nil) then
    begin
      raise Exception.Create(
        'EnqueueLast - Queue.fLast is nil and fFirst not - this should not be !! ');
      Halt;
    end
    else
    begin
      fLast^.Next := QueueItem;
      fLast := QueueItem;
    end;
  finally
    LeaveCS(CS);
    if Assigned(fOn_New_Task) then
      fOn_New_Task();
  end;
end;

procedure tMultiTaskQueue.Enqueue(const Data: tMultiTaskItem; const flags: tMultitaskEnQueueFlags);
begin
  if teFirst in flags then
  begin
    Data.fPriority := tpFirst;
    EnqueueFirst(Data, teUnique in flags);
  end
  else

  if teHighPriority in flags then
  begin
    Data.fPriority := tpHigh;
    EnqueuePriority(Data, tpHigh, teUnique in flags);
  end
  else

  if teNormalPriority in flags then
  begin
    Data.fPriority := tpNormal;
    EnqueuePriority(Data, tpNormal, teUnique in flags);
  end
  else

  if teLowPriority in flags then
  begin
    Data.fPriority := tpLow;
    EnqueuePriority(Data, tpLow, teUnique in flags);
  end
  else

    EnqueueLast(Data, teUnique in flags);
end;

procedure tMultiTaskQueue.Enqueue(const proc: tTaskProc; const method: tTaskMethod; const params: array of const; const proc_before: tTaskProc;
  const method_before: tTaskMethod; const params_before: array of const; const proc_after: tTaskProc; const method_after: tTaskMethod;
  const params_after: array of const; const flags: tMultitaskEnQueueFlags; const obj: tObject);
var
  i: integer;
  Data: tMultiTaskItem;
begin
  try
    Data := tMultiTaskItem.Create(proc, method, params, proc_before,
      method_before, params_before, proc_after, method_after, params_after, obj);

    Enqueue(Data, flags);
  except
    on E: Exception do
    begin
      raise Exception.Create(E.Message + ' on Enqueue ' + Data.AsPascalSourceString);
    end;
  end;
end;

procedure tMultiTaskQueue.Enqueue(const method: tTaskMethod; const params: array of const; const flags: tMultitaskEnQueueFlags;
  const obj: tObject);
begin
  Enqueue(nil, method, params, nil, nil, [], nil, nil, [], flags,obj);
end;

procedure tMultiTaskQueue.Enqueue(const proc: tTaskProc; const params: array of const; const flags: tMultitaskEnQueueFlags);
begin
  Enqueue(proc, nil, params, nil, nil, [], nil, nil, [], flags);
end;

function tMultiTaskQueue.DeQueue(const thrd: tObject): tMultiTaskItem;
var
  QueueItem: pQueueItem;
begin
  Result := Default(tMultiTaskItem);
  EnterCS(CS, 'Dequeue');
  try
    if fFirst <> nil then
    begin
      Result := tMultiTaskItem(fFirst^.Item);
      QueueItem := fFirst^.Next;
      Dispose(fFirst);
      fFirst := QueueItem;
      if fFirst = nil then
        fLast := nil;
      fCount -= 1;

//      if (result.fMinimumAvailableMemoryGb = -1) or (result.fMinimumAvailableMemoryGb > uMemory.GetAvailableMemoryGb)
//      then
//      begin
        tMultiTaskThread(thrd).Task := result;
//      end else
//      begin
//         self.Enqueue(result,result.fflags);
//         result := nil;
//      end;
    end;
  finally
    LeaveCS(CS);
  end;
end;

procedure tMultiTaskQueue.Clear;
var
  QueueItem, i: pQueueItem;
begin
  EnterCS(CS, 'Clear Queue');
  try
    QueueItem := fFirst;
    fFirst := nil;
    fLast := nil;
  finally
    LeaveCS(CS);
  end;
  while QueueItem <> nil do
  begin
    QueueItem^.Item := nil;
    //     QueueItem^.Data^.Originator := nil;
    //     QueueItem^.Data^.OriginatorName := '';
    i := QueueItem;
    QueueItem := QueueItem^.Next;
    Dispose(i);
  end;
end;

function tMultiTaskQueue.Length: integer;
begin
  EnterCS(CS, 'Queue Length');
  try
    Result := fCount;
  finally
    LeaveCS(CS);
  end;
end;

function tMultiTaskQueue.Exists(const Data: tMultiTaskItem): boolean;
begin
  EnterCS(CS, 'Exist in queue : ' + Data.Name);
  try
    Result := _Exists(Data);
  finally
    LeaveCS(CS);
  end;
end;

function tMultiTaskQueue._Exists(const Data: tMultiTaskItem): boolean;
var
  QI: pQueueItem;
begin
  if fFirst = nil then
    Exit(False);

  QI := fFirst;
  repeat
    if QI^.Item.AsPascalSourceString = Data.AsPascalSourceString then
    begin
      Exit(True);
    end;

    QI := QI^.Next;
  until QI = nil;
  Result := False;
end;

function tMultiTaskQueue._Exists_Or_Running(const Data: tMultiTaskItem): boolean;
begin
  Result := _Exists(Data) or tMultiTask(MultiTask).isTaskRunning(Data);
end;

function tMultiTaskQueue.HaveWork: boolean;
begin
  EnterCS(CS, 'Queue - Have Work');
  try
    Result := fFirst <> nil;
  finally
    LeaveCS(CS);
  end;
end;

procedure tMultiTaskQueue.setOn_New_Task(AValue: tOn_New_Task);
begin
  if fOn_New_Task = AValue then
    Exit;
  fOn_New_Task := AValue;
end;

end.
