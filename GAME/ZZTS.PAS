{$I-}
{$M 16384,163840,655360}
{ REMOVED - Suspected third-party copyright. ^ The config above was copied over from Reconstruction of ZZT. }
program ZZT;

{}
{ New version implementation: }
{ Remove all BOUND OBJECT things, noted by **. }
{ Objs [0] must have no INSIDE. }
{}

uses
   FastWr, Crt, Dos, Keyboard, SoundU,
   GameCtrl,
   Scrolls,
	Glob, Obj, Lang, Edit, Main;


procedure HandleCmdLine;
var
   N:integer;
   S:String;
begin
   for N := 1 to ParamCount do begin
      S := ParamStr(N);
      if S[1]='/' then case UpCase (S[2]) of
         'T': begin
            TimerTested:= 0;
            TimerWorks := false;
            end;
         'R': begin
            Reconfig := true;
            end;
         end
      else begin
         IntroName := S;
         if (length (IntroName)>4) and
            (IntroName[length(IntroName)-3]='.') then
            IntroName := copy (IntroName,1,length(IntroName)-4);
         end;
      end;
   end;

{}
{ Config file: }
{}
{ First-Run-Flag 1}
{ JoyPresent     2}
{ MousePresent   4}
{ JoyFlag        8}
{ MouseFlag     16}
{ MonoFlag      32}
{ JoyXSense       }
{ JoyYSense       }
{ LastMode        }
{ RegWorld        }
{ RegCopy         }
{ SerNum or EOF   }
{}

{$I-}
procedure CheckCfg;
const
   Divi = '==============================================================================';
var
   F:            text;
   TempI:        integer;
   xJoyPresent:  boolean;
   xMousePresent,
   xJoyFlag,
   xMouseFlag,
   xMonoFlag,
   JoyPresent,
   MousePresent: boolean;
   xLastMode,
   xJoyXSense,
   xJoyYSense:   integer;
begin
   FirstRun := true;
   RegEdit  := true;
   RegCopy  := '';
   RegWorld := '';
   SerNum   := 'NONE';
   {}
   assign (F,'ZZT.CFG');
   reset (F);
   if IOResult = 0 then begin
      readln (F,TempI);
      FirstRun      := (TempI and 1 )<>0;
      xJoyPresent   := (TempI and 2 )<>0;
      xMousePresent := (TempI and 4 )<>0;
      xJoyFlag      := (TempI and 8 )<>0;
      xMouseFlag    := (TempI and 16)<>0;
      xMonoFlag     := (TempI and 32)<>0;
      readln (F,xJoyXSense);
      readln (F,xJoyYSense);
      readln (F,xLastMode);
      readln (F,RegWorld);
      readln (F,RegCopy);
      if EOF(F) then
         SerNum := 'NONE'
      else
         readln (F,SerNum);
      close (F);
      end;
   {}
   if RegWorld [1]='*' then begin
      RegEdit := false;
      RegWorld := copy (RegWorld,2,length (RegWorld)-1);
      end;
   {}
   if RegWorld <> '' then
      IntroName := RegWorld;
   {}
   { Now see if we need to reconfigure: }
   {}
   SenseCtrlMode;
   {}
   JoyPresent   := JoyFlag;
   MousePresent := MouseFlag;
   {}
   if (JoyXSense=0) then inc (JoyXSense);
   if (JoyYSense=0) then inc (JoyYSense);
   {}
   TempI := abs ((100*(JoyXSense-xJoyXSense)) div JoyXSense) +
            abs ((100*(JoyYSense-xJoyYSense)) div JoyYSense);
   {}
   if (FirstRun)                      or
      (Reconfig)                      or
      (JoyPresent and (TempI>50))     or
      (JoyPresent   <> xJoyPresent)   or
      (MousePresent <> xMousePresent) or
      (xMouseFlag)                    or
      (LastMode     <> xLastMode)     then begin
      {}
      { Reconfigure! }
      {}
      FirstRun   := false;
      xJoyFlag   := JoyFlag;
      xMouseFlag := MouseFlag;
      {}
      window (1,1,80,25);
      clrscr;
      textcolor ($0f);
{ REMOVED - Suspected third-party copyright }
      clrscr;
      gotoxy (1,1);
      textcolor ($e);
      {}
      if not GetCtrlMode then
         ExitProgram := true
      else begin
         textcolor ($0a);
         if not GetVideoMode then
            ExitProgram := true;
         end;
      {}
      { Now save the configuration }
      {}
      if not (ExitProgram) then begin
         rewrite (F);
         TempI := 1 *integer(FirstRun)    +
                  2 *integer(JoyPresent)  +
                  4 *integer(MousePresent)+
                  8 *integer(JoyFlag)     +
                  16*integer(MouseFlag)   +
                  32*integer(MonoFlag);
         writeln (F,TempI);
         writeln (F,JoyXSense);
         writeln (F,JoyYSense);
         writeln (F,LastMode);
         writeln (F,RegWorld);
         writeln (F,RegCopy);
         writeln (F,SerNum);
         close (F);
         end;
      window (1,1,80,25);
      end
   else begin
      {}
      { Restore old configuration }
      {}
      JoyFlag    := xJoyFlag;
      MouseFlag  := xMouseFlag;
      MonoFlag   := xMonoFlag;
      end;
  end;

{}
{ Just do it! }
{ Main block }
{}


begin
   {}
   Wnum := 0;
{ REMOVED - Suspected third-party copyright. ^ The line above was added to prevent a crash. }
   {}
   randomize;
   SetCBreak (false);
   {}
   OldTextAttr := TextAttr;
   IntroName   := 'TOWN';
   HelpFile    := 'ZZT.DAT';
   Reconfig    := false;
   ExitProgram := false;
   {}
   HandleCmdLine;
   CheckCfg;
   if (not ExitProgram) then begin
      {}
      SetVideoMode;
      {}
      { Scrolls: }
      {}
      DrawXY   := DrawCell;
      ScSerNum := @SerNum;
      {}
      port [$3d9] := 01;
      GetMem (TempHeap, TempHeapSize);
      CursorOff;
      clrscr;
      Speed := 4;
      Debug := false;
      SaveName := 'SAVED';
      IEName   := 'TEMP';
      InitSplotch; {Don't CLS first!}
      {}
      InitGame;
      Menu;
      FreeMem (TempHeap, TempHeapSize);
      end;
   {}
   ExitSoundU;
   SoundStop;
   port [$3d9] := 0;
   TextAttr := OldTextAttr;
   clrscr;
   if RegCopy='' then begin
      AnnoyView;
      end
   else begin
      writeln;
      writeln ('  Thank you for playing ZZT.');
      writeln;
      end;
   CursorOn;
	end
	.
