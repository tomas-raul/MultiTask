program MultiTask_PreCompiler;
uses
   sysutils,
   classes,
   strutils,
   typinfo,
   fileutil,
   ucmdline,
   uMultiTask,
   uMultiTaskQueue,
   StringUtils,
   uIOFile_v4,
   regexpr,
   SuperObject;

type
  tParam =
  record
    Name : string;
    Typ  : string;
  end;

  tMethod =
    record
      Name : string;
      Params : array of tParam;
    end;

  tMethods = array of tMethod;

var
  InputFileName : string; // defaults to ''
  OnNewWorkMethodFileName : string; // name of OnNewWork filename (could be .inc or '', when '' then ) - defaults to On_New_Work
  MethodDefinitionFile : string; // where to place md. when '' then in source file on place MT_def
  MethodImplementationFile : string; // where to place mi. when '' then in source file on place MT_impl
  Type_Definition_File : string;
  Type_Definition : tStringList;

  Class_Name : string; // name of class for which we generate, or class can be selected as class_MT flag

  MethodFlagName : string; // defaults to MT - so then method should be flaged as gen_MT (when more than one object, could be other for second objects)

  MultiTaskerObjectname : string; // defaults to MultiTask


  Default_Priority : tMultitaskEnQueueFlag;

  OnNewWorkMethodName : string; // name of OnNewWork method - defaults to On_New_Work

  Default_Method_Suffix : string;
//  Switches
  GenerateUniqueMethods : boolean;

  Generate_Main_Methods : boolean;
  Generate_Last_Priority_Methods : boolean;
  Generate_Low_Priority_Methods : boolean;
  Generate_Normal_Priority_Methods : boolean;
  Generate_High_Priority_Methods : boolean;
  Generate_ASAP_Priority_Methods : boolean;

  Methods : tMethods;

procedure InitParameters;
begin
  MethodFlagName := getOptionS('mfn','Method-Flag-Name','compile methods tag with {gen_<Method-Flag-Name>}','MT');
  Class_Name := getOptionS('cn','Class-Name','to which class generated methods belongs, or class can be selected as class_<Method-Flag-Name> flag','');
  if Class_Name <> '' then Class_Name := Class_Name + '.';
  MultiTaskerObjectname := getOptionS('mto','Multi-Task-Object','name of MultiTask object variable','MultiTask');
  MethodDefinitionFile := getOptionS('mdf','Method-Definition-File','when use .inc file for generated interface, this is filename for it, default <InputFileName>+_<Method-Flag-Name>_def.inc','');
  MethodImplementationFile := getOptionS('mif','Method-Implementation-File','when use .inc file for implementation, this is filename for it, default <InputFileName>+_<Method-Flag-Name>_impl.inc','');
  OnNewWorkMethodFileName  := getOptionS('onwf','On-New-Work-Method-FileName','Name of main worker method file - default <InputFileName>+_onNewWork.inc','');
  OnNewWorkMethodName := getOptionS('onw','On-New-Work-Method-Name','Name of main worker method - this method is generated and runs adequate method','On_New_Work');
  Default_Method_Suffix := getOptionS('dms','Default-Method-Suffix','default suffix for generated multi task methods f.e.: Write->Write_<Default-Method-Suffix>','_MT');

  Type_Definition_File := getOptionS('tdf','Type-Definition-File','file with info about object and interfaces','MultiTask_Type_Definition.cfg');
  Type_Definition := tStringList.Create;
  if FileExists(Type_Definition_File) then
   Type_Definition.LoadFromFile(Type_Definition_File);

  Generate_Main_Methods := getOptionB('dgmm','Disable-Main-Methods','generate main multitask invoke methods', true);
  GenerateUniqueMethods := getOptionB('gum','Unique-Methods','generate unique multitask invoke methods', false);
  case lowercase(getOptionS('dp','Default-Priority','default priority for enqueuing','NORMAL')) of
    'asap' : Default_Priority := teFirst;
    'high' : Default_Priority := teHighPriority;
    'last' : Default_Priority := teLast;
    'low' : Default_Priority := teLowPriority;
    else Default_Priority := teNormalPriority;
  end;

  Generate_Last_Priority_Methods := getOptionB('lapm','Last-Priority-Methods','generation of f.e.: Write->Write_<Default-Method-Suffix>_Last_Priority', false);
  Generate_Low_Priority_Methods := getOptionB('lopm','Low-Priority-Methods','generation of f.e.: Write->Write_<Default-Method-Suffix>_Low_Priority', false);
  Generate_Normal_Priority_Methods := getOptionB('npm','Normal-Priority-Methods','generation of f.e.: Write->Write_<Default-Method-Suffix>_Normal_Priority', false);
  Generate_High_Priority_Methods := getOptionB('hpm','High-Priority-Methods','generation of f.e.: Write->Write_<Default-Method-Suffix>_HIGH_Priority', false);
  Generate_ASAP_Priority_Methods := getOptionB('apm','ASAP-Priority-Methods','generation of f.e.: Write->Write_<Default-Method-Suffix>_ASAP_Priority', false);

  InputFileName := getFinalS('filename','input file for compilation','');

  if getOptionB('h','help','print help string - this list',false) then
  begin
     Writeln();
     Writeln(getHelpString);
     Halt();
  end;
  OnNewWorkMethodFileName  := getOptionS('onwf','On-New-Work-Method-FileName','Name of main worker method file - default <InputFileName>+_onNewWork.inc',ChangeFileExt(InputFileName,'_onNewWork.inc'));
  MethodDefinitionFile := getOptionS('mdf','Method-Definition-File','when use .inc file for generated interface, this is filename for it, default <InputFileName>+_<Method-Flag-Name>_def',ChangeFileExt(InputFileName,'_'+MethodFlagName+'_def.inc'));
  MethodImplementationFile := getOptionS('mif','Method-Implementation-File','when use .inc file for implementation, this is filename for it, default <InputFileName>+_<Method-Flag-Name>_impl',ChangeFileExt(InputFileName,'_'+MethodFlagName+'_impl.inc'));
end;

procedure WriteParameters;
var tp : string;
begin
  Writeln('Input file                       : ' + InputFileName);
  Writeln('Type definition file             : ' + ifthen(FileExists(Type_Definition_File),Type_Definition_File,''));

  Writeln('Method definition .inc file      : ' + MethodDefinitionFile);
  Writeln('Method implementation .inc file  : ' + MethodImplementationFile);
  Writeln;
  Writeln('Method selection flag            : ' + MethodFlagName);
  Writeln('Name of class                    : ' + Class_Name);
  Writeln('Name of on_new_work_method       : ' + OnNewWorkMethodName);
  Writeln('Default method suffix            : ' + Default_Method_Suffix);
  Writeln;
  Writeln(' Main Method generation          : ' + ifThen(Generate_Main_Methods,' YES ','no'));
  Writeln(' Unique Method generation        : ' + ifThen(GenerateUniqueMethods,' YES ','no'));


  tp := 'LAST';
  case Default_Priority of
      teFirst : tp := 'ASAP';
      teHighPriority : tp := 'HIGH';
      teNormalPriority : tp := 'NORMAL';
      teLowPriority : tp := 'LOW';
      teLast : tp := 'LAST';
  end;
  Writeln(' Default task priority           : ' + tp);

  Writeln(' generate ASAP   priority        : ' + ifThen(Generate_ASAP_Priority_Methods,' YES ','no'));
  Writeln(' Generate High   priority        : ' + ifThen(Generate_High_Priority_Methods,' YES ','no'));
  Writeln(' Generate Normal priority        : ' + ifThen(Generate_Normal_Priority_Methods,' YES ','no'));
  Writeln(' Generate Low    priority        : ' + ifThen(Generate_Low_Priority_Methods,' YES ','no'));
  Writeln(' Generate Last   priority        : ' + ifThen(Generate_Last_Priority_Methods,' YES ','no'));
end;

var input : string;
    output : string;
    inter : string;
    impl : string;


procedure LoadDataFromSource(const filename : string);
var input : string;

  procedure FindIncludes(const str : string);
  var
     RE: TRegExpr;
     fn : string;
     newfn : string;
  begin
    RE := TRegExpr.Create;
    try
    	RE.Expression := '{\$(I|INCLUDE)[ ]+([\w\.\\]+)}';
        RE.ModifierG := false;
        RE.ModifierI := true;
//        Writeln('Running RE on string('+IntToStr(length(str))+')');
    	if RE.Exec(str) then
        begin
    		repeat
                  fn := RE.Match[2];

                  newfn := ExpandFileName(IncludeTrailingPathDelimiter(ExtractFilePath(filename)) + fn);
//                  Writeln('Found $I : ' + fn + ' which should be ' + newfn);
                  LoadDataFromSource(newfn);
    		until not RE.ExecNext;
    	end;
    finally
    	RE.Free;
    end;
  end;

  procedure FindClassName(const str : string);
  var
     RE: TRegExpr;
     cn : string;
  begin
    if Class_Name <> '' then Exit;
    RE := TRegExpr.Create;
    try
    	RE.Expression := '([a-z_1-90]+)[ ]*=[ ]*class\([a-z_1-90]+\)[ ]+\{class_'+MethodFlagName+'\}';
        RE.ModifierG := false;
        RE.ModifierI := true;
//        Writeln('Running RE on string('+IntToStr(length(str))+')');
    	if RE.Exec(str) then
        begin
    		repeat
                  cn := RE.Match[1];
                  Writeln('Found class name : ' + cn);
                  Class_Name := cn + '.';
    		until not RE.ExecNext;
    	end;
    finally
    	RE.Free;
    end;
  end;

  procedure FindMethods(const str : string);
  var
     RE, REp: TRegExpr;
     fn, params, param : string;
     mn : string;
     method : string;
     par : tParam;
     meth : tMethod;

     procedure AddParam(par : tParam);
     begin
        setLength(meth.Params,length(meth.Params)+1);
        meth.Params[high(meth.Params)] := par;
     end;

     procedure AddMethod(meth : tMethod);
     begin
       setLength(methods,length(methods)+1);
       methods[high(methods)] := meth;
     end;

  begin
    RE := TRegExpr.Create;
    RE.Expression := 'procedure ([a-z_1-90]*)[ ]*(\((.*)\)){0,1}[ ]*;[ ]*\{gen_MT\}';
    REp := TRegExpr.Create;
    REp.Expression:='((const|var)[ ]){0,1}[ ]*([a-z_]+)[ ]*:[ ]*([a-z_]+);';
    try
        RE.ModifierG := false;
        RE.ModifierI := true;
        REp.ModifierG := false;
        REp.ModifierI := true;
    	if RE.Exec(str) then
        begin
    		repeat
                  method := '';
                  SetLength(meth.Params,0);
                  mn := RE.Match[1];
                  params := RE.Match[3];
                  params := ReplaceStr(params,#13,'');
                  params := ReplaceStr(params,#10,'');
                  params := ReplaceStr(params,'  ',' ');
                  if params <> '' then params += ';';

                  meth.Name:=mn;

                  method += mn + '(';
                  if REp.Exec(params) then
                  begin
                     repeat
                       method += REp.Match[4] + ',';
                       par.Name:=REp.Match[3];
                       par.Typ:= REp.Match[4];
                       AddParam(par);
                     until not REp.ExecNext;
                     method := copy(method,1,length(method)-1);
                  end;
                  method += ');';
                  writeln('Found method : '+method);
                  AddMethod(Meth);

    		until not RE.ExecNext;
    	end;
    finally
        REp.Free;
    	RE.Free;
    end;
  end;

begin
  Writeln('Loading ' + filename);
  input := getFile(filename);
  if input = '' then
  begin
     Writeln('Input file ' + filename + ' not found or empty, halt..');
     Halt;
  end;

  FindClassName(input);
  FindMethods(input);
  FindIncludes(input);

end;

procedure Generate_On_New_Work();
var i : integer;
    meth : tMethod;
    p : integer;
    par : tParam;
    par_str : string;
    res : string;
    fn : string;
    typ : string;
begin
   res := 'procedure ' + Class_Name + OnNewWorkMethodName + '(const method_name: string; const task: tMultiTaskItem);' + LineEnding;
   res += 'begin' + LineEnding;
   res += '   case method_name of' + LineEnding + LineEnding;
   for i := low(methods) to high(methods) do
   begin
      meth := methods[i];
      par_str := '';
      if length(meth.Params) > 0 then
      begin
         for p := low(meth.Params) to high(meth.Params) do
         begin
            par := meth.Params[p];
            typ := Type_Definition.Values[par.typ];
            if typ <> '' then
            begin
               par_str += ' '+par.typ+'(task.'+typ+'['+IntToStr(p+1)+']), ';
            end else
            begin
            case lowercase(par.typ) of
{
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
}
                'string' : par_str += ' task.S['+IntToStr(p+1)+'], ';

                'integer',
                'byte',
                'word' : par_str += ' task.I['+IntToStr(p+1)+'], ';


                else
                  if lowercase(copy(par.typ,1,1)) = 'i' then
                  par_str += ' '+par.typ+'(task.int['+IntToStr(p+1)+']), ' else
                  par_str += ' '+par.typ+'(task.O['+IntToStr(p+1)+']), ';
            end;
            end;
         end;
         par_str := copy(par_str,1,length(par_str)-2);
      end;

      res += '    ''' + lowercase(meth.Name) + ''' : ' + meth.Name + '(' + par_str + ');' + LineEnding;


      res += LineEnding;
   end;

   res += '      else' + LineEnding;
   res += '         Log(''!!!ERROR!!! Method "'' + method_name + ''" is not defined in On_New_Work method. !!!ERROR!!!'' );' + LineEnding;
   res += '   end;' + LineEnding;
   res += 'end;' + LineEnding;

  fn := ExpandFileName(IncludeTrailingPathDelimiter(ExtractFilePath(InputFileName)) + OnNewWorkMethodFileName);
  Writeln('Saving ' + fn);
  SetFile(fn,res);
end;

procedure Generate_Method_Definition();
var i : integer;
    meth : tMethod;
    p : integer;
    par : tParam;
    par_str : string;
    res : string;
    fn : string;

begin
   res := '';
   for i := low(methods) to high(methods) do
   begin
      meth := methods[i];
      par_str := '';
      if length(meth.Params) > 0 then
      begin
         for p := low(meth.Params) to high(meth.Params) do
         begin
            par := meth.Params[p];
            par_str += ' const ' + par.Name + ' : ' + par.Typ + '; ';
         end;
         par_str := copy(par_str,1,length(par_str)-2);
      end;

      res += ' procedure ' + meth.Name + Default_Method_Suffix +  '(' + par_str + ');' + LineEnding;
      if Generate_Last_Priority_Methods then
      res += ' procedure ' + meth.Name + Default_Method_Suffix +  '_Last(' + par_str + ');' + LineEnding;
      if Generate_Low_Priority_Methods then
      res += ' procedure ' + meth.Name + Default_Method_Suffix +  '_Low(' + par_str + ');' + LineEnding;
      if Generate_Normal_Priority_Methods then
      res += ' procedure ' + meth.Name + Default_Method_Suffix +  '_Normal(' + par_str + ');' + LineEnding;
      if Generate_High_Priority_Methods then
      res += ' procedure ' + meth.Name + Default_Method_Suffix +  '_High(' + par_str + ');' + LineEnding;
      if Generate_ASAP_Priority_Methods then
      res += ' procedure ' + meth.Name + Default_Method_Suffix +  '_ASAP(' + par_str + ');' + LineEnding;

      if GenerateUniqueMethods then
      begin
         res += ' procedure ' + meth.Name + Default_Method_Suffix +  '_Unique(' + par_str + ');' + LineEnding;
         if Generate_Last_Priority_Methods then
         res += ' procedure ' + meth.Name + Default_Method_Suffix +  '_Unique_Last(' + par_str + ');' + LineEnding;
         if Generate_Low_Priority_Methods then
         res += ' procedure ' + meth.Name + Default_Method_Suffix +  '_Unique_Low(' + par_str + ');' + LineEnding;
         if Generate_Normal_Priority_Methods then
         res += ' procedure ' + meth.Name + Default_Method_Suffix +  '_Unique_Normal(' + par_str + ');' + LineEnding;
         if Generate_High_Priority_Methods then
         res += ' procedure ' + meth.Name + Default_Method_Suffix +  '_Unique_High(' + par_str + ');' + LineEnding;
         if Generate_ASAP_Priority_Methods then
         res += ' procedure ' + meth.Name + Default_Method_Suffix +  '_Unique_ASAP(' + par_str + ');' + LineEnding;
      end;


      res += LineEnding;
   end;
   res += LineEnding;

   fn := ExpandFileName(IncludeTrailingPathDelimiter(ExtractFilePath(InputFileName)) + MethodDefinitionFile);
   Writeln('Saving ' + fn);
   SetFile(fn,res);
end;

procedure Generate_Method_Implementation();
var i : integer;
    meth : tMethod;
    p : integer;
    par : tParam;
    par_str, par_str2 : string;
    res : string;
    fn : string;

    procedure AddMethods(const unique : boolean);
    begin
      res += ' procedure ' + Class_Name + meth.Name + Default_Method_Suffix + ifThen(unique,'_Unique','') + '(' + par_str2 + ');' + LineEnding;
      res += ' begin' + LineEnding;
      res += '    ' + MultiTaskerObjectname+'.Enqueue(tTaskMethod(@' + meth.Name + '), [' + par_str + '], ['+GetEnumName(TypeInfo(tMultitaskEnQueueFlag),Ord(Default_Priority))+''+ifThen(unique,',teUnique','')+']);' + LineEnding;
      res += ' end;' + LineEnding;

      if Generate_Last_Priority_Methods then
      begin
         res += ' procedure ' + Class_Name + meth.Name + Default_Method_Suffix + ifThen(unique,'_Unique','') +  '_Last(' + par_str2 + ');' + LineEnding;
         res += ' begin' + LineEnding;
         res += '    ' + MultiTaskerObjectname+'.Enqueue(tTaskMethod(@' + meth.Name + '), [' + par_str + '], [teLast'+ifThen(unique,',teUnique','')+']);' + LineEnding;
         res += ' end;' + LineEnding;
      end;
      if Generate_Low_Priority_Methods then
      begin
         res += ' procedure ' + Class_Name + meth.Name + Default_Method_Suffix + ifThen(unique,'_Unique','') +  '_Low(' + par_str2 + ');' + LineEnding;
         res += ' begin' + LineEnding;
         res += '    ' + MultiTaskerObjectname+'.Enqueue(tTaskMethod(@' + meth.Name + '), [' + par_str + '], [teLowPriority'+ifThen(unique,',teUnique','')+']);' + LineEnding;
         res += ' end;' + LineEnding;
      end;
      if Generate_Normal_Priority_Methods then
      begin
         res += ' procedure ' + Class_Name + meth.Name + Default_Method_Suffix + ifThen(unique,'_Unique','') +  '_Normal(' + par_str2 + ');' + LineEnding;
         res += ' begin' + LineEnding;
         res += '    ' + MultiTaskerObjectname+'.Enqueue(tTaskMethod(@' + meth.Name + '), [' + par_str + '], [teNormalPriority'+ifThen(unique,',teUnique','')+']);' + LineEnding;
         res += ' end;' + LineEnding;
      end;
      if Generate_High_Priority_Methods then
      begin
         res += ' procedure ' + Class_Name + meth.Name + Default_Method_Suffix + ifThen(unique,'_Unique','') +  '_High(' + par_str2 + ');' + LineEnding;
         res += ' begin' + LineEnding;
         res += '    ' + MultiTaskerObjectname+'.Enqueue(tTaskMethod(@' + meth.Name + '), [' + par_str + '], [teHighPriority'+ifThen(unique,',teUnique','')+']);' + LineEnding;
         res += ' end;' + LineEnding;
      end;
      if Generate_ASAP_Priority_Methods then
      begin
         res += ' procedure ' + Class_Name + meth.Name + Default_Method_Suffix + ifThen(unique,'_Unique','') +  '_ASAP(' + par_str2 + ');' + LineEnding;
         res += ' begin' + LineEnding;
         res += '    ' + MultiTaskerObjectname+'.Enqueue(tTaskMethod(@' + meth.Name + '), [' + par_str + '], [teFirst'+ifThen(unique,',teUnique','')+']);' + LineEnding;
         res += ' end;' + LineEnding;
      end;
    end;

begin
   res := '';
   for i := low(methods) to high(methods) do
   begin
      meth := methods[i];
      par_str := '';
      par_str2 := '';
      if length(meth.Params) > 0 then
      begin
         for p := low(meth.Params) to high(meth.Params) do
         begin
            par := meth.Params[p];
            par_str += ' ' + par.Name + ',';
            par_str2 += ' const ' + par.Name + ' : ' + par.Typ + ';';
         end;
         par_str := copy(par_str,1,length(par_str)-1);
         par_str2 := copy(par_str2,1,length(par_str2)-1);
      end;

      AddMethods(false);
      if GenerateUniqueMethods then
       Addmethods(true);

      res += LineEnding;
      res += LineEnding;
   end;
   res += LineEnding;

  fn := ExpandFileName(IncludeTrailingPathDelimiter(ExtractFilePath(InputFileName)) + MethodImplementationFile);
  Writeln('Saving ' + fn);
  SetFile(fn,res);
end;

begin
   Writeln('MultiTask_PreCompiler - v0.1 - build on ' + {$I %DATE%} + ' ' + {$I %TIME%});
   InitParameters();
   WriteParameters();
   output := ''; inter := ''; impl := '';
   LoadDataFromSource(InputFileName);
   Writeln('Data loaded..');
   Writeln('Found ' + IntToStr(length(methods)) + ' methods');
   if length(methods) = 0 then
   begin
      Writeln('Halt');
      Halt;
   end;
   Generate_On_New_Work();
   Generate_Method_Definition();
   Generate_Method_Implementation();
   Writeln('All work done ok');

//   Readln();
end.

