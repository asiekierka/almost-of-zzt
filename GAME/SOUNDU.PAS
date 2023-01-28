unit SoundU;

{}
{ When using this unit, you MUST call SoundUExit before program quits! }
{}

interface

type
   Digits    =  array [0..255] of integer;

var
   SoundF,
   SoundOff:     boolean;
   NotePriority: integer;
   NoteTable:    array [1..255] of integer;
   SoundSpeed:   byte;		{multiplier used to slow down sounds}
   SoundCount:   byte;		{counts how long current sound has been on}
   Notes:        string;
   New1CInt,
   Int1CSave:    pointer;       {interrupt handlers}
   SoundPtr:     integer;
   MakeSound:    boolean;       {True if a sound is currently playing}
   {}
   TimerTested:  integer;
   TimerWorks:   boolean;
   MyClock:      word;
   LastSec100:   word;   {For timer test}
   {}
   OurDigits:    array [0..9] of Digits;

const
   TestStart=36; {Test timer minimum of 1 second}

procedure SoundAdd (Priority:integer; S:string);
procedure SoundStop;
procedure ExitSoundU;
function  Music (S:String):String;
function  TimePassed (var Last100:word; N:integer):boolean;

implementation

uses
   Crt, Dos;

procedure SoundAdd (Priority:integer; S:string);
begin
   if SoundOff then exit;
   if (not MakeSound) or
      ((Priority >= NotePriority) and (NotePriority<>-1)) or
      (Priority=-1) then begin
      {}
      if (Priority>=0) or (not MakeSound) then begin
         NotePriority := Priority;
         Notes := S;
         SoundPtr := 1;
         SoundCount := 1;
         end
      else begin
         Notes := copy (Notes,SoundPtr,length (Notes)-SoundPtr+1);
         SoundPtr := 1;
         if (length (Notes)+length (S)) < 255 then
            Notes := Notes + S;
         end;
      MakeSound := TRUE;
      end;
   end;

procedure SoundStop;
begin
   Notes     := '';
   MakeSound := false;
   NoSound;
   end;

procedure InitNoteTable;
var
   Octave,Note:integer;
   Root:       real;    {Note # $10}
   Step:       real;    {12th root of two}
   Current:    real;
   ln2:        real;
begin
   Root    := 32;
   ln2     := ln(2);
   Step    := exp (ln2/12);
   for Octave := $1 to $f do begin
      Current := Root * exp (ln2*Octave);
      for Note := 0 to 11 do begin
         NoteTable [Octave*$10+Note] := trunc (Current);
         Current := Current * Step;
         end;
      end;
   end;

procedure InitDigits; {No '3'}
var
   C:integer;
begin
   OurDigits [0][0] := 1;
   OurDigits [0][1] := 3200; {Click}
   for C := 1 to 9 do
      OurDigits [C][0] := 14;
   for C := 1 to 14 do
      OurDigits [1][C] := C*100+1000; {Bwoop}
   for C := 1 to 16 do
      OurDigits[2,c] := 1600+1600*(c mod 2)+1600*(c mod 4);
   for C := 1 to 14 do
      OurDigits[4][c] := random(5000)+500; {Snare}
   for C := 1 to 8 do begin
      OurDigits[5,c*2-1] := 1600;
      OurDigits[5,c*2]   := random(1600)+800;
      end;
   for C := 1 to 14 do
      OurDigits[6][c] := 880+880*(c mod 2)+440*(c mod 3);
   for C := 1 to 14 do
      OurDigits[7][c] := 700-12*c;
   for C := 1 to 14 do begin
      OurDigits[8,c] := 1200+c*20-random (c*40);
      end;
   for C := 1 to 14 do
      OurDigits[9][c] := random(440)+220; {Low Kick}
   end;

procedure PlayDigits (var Data:Digits);
var
   C:integer;
begin
   for C := 1 to Data[0] do begin
      sound (Data[c]);
      delay (1);
      end;
   NoSound;
   end;

procedure TestTimer;
var
   Hr, Min, Sec, Sec100: word;
begin
   GetTime (Hr,Min,Sec,Sec100);
   if (LastSec100<>0) and (Sec100<>LastSec100) then begin
      TimerTested := 0;
      TimerWorks  := true;
      end;
   LastSec100 := Sec100;
   end;

function TimePassed (var Last100:word; N:integer):boolean;
{}
{ Returns true if N time has passed, else false }
{ N = 1/100 sec, times up to 1 minute }
{}
var
   Hr, Min, Sec, Sec100: word;
   Time:   word;
   New100: word;
begin
   if (TimerTested>0) and ((TimerTested mod 2)=1) then begin
      TimerTested := TimerTested-1;
      TestTimer;
      end;
   if TimerWorks then begin
      GetTime (Hr,Min,Sec,Sec100);
      {}
      New100 := Sec*100 + Sec100; {Maximum = 5900+100 = 6000}
      {}
      Time := (New100 - Last100 + 6000) mod 6000;
      end
   else begin
      New100 := MyClock*6; {18*6=108, nearly 100}
      Time := New100-Last100;
      end;
   {}
   if (Time >= N) then begin
      TimePassed  := true;
      Last100     := New100;
      end
   else
      TimePassed := false;
   end;


procedure TimerInt; interrupt;
begin
   Inc (MyClock);
   if (TimerTested>0) and ((TimerTested mod 2)=0) then
      TimerTested := TimerTested-1;
   if not SoundF then begin
      MakeSound := FALSE;
      NoSound;
      Exit;
      end;
   if MakeSound then begin
      Dec(SoundCount);
      if SoundCount <= 0 then begin
         NoSound;
         if SoundPtr >= length (Notes) then begin
            NoSound;
            MakeSound := false;
            end
         else begin
            if Notes [SoundPtr]=#0 then
               NoSound {rest}
            else begin
               if (Notes [SoundPtr] < #$f0) then
                  Sound (NoteTable [ord (Notes [SoundPtr])])
               else begin
                  PlayDigits (OurDigits [Ord (Notes [SoundPtr])-$f0]);
                  end;
               end;
            inc (SoundPtr);
            SoundCount := SoundSpeed * ord (Notes[SoundPtr]);
            inc (SoundPtr);
            end
         end;
      end;
   end;

procedure ExitSoundU;
begin
   SetIntVec($1C,Int1CSave);
   end;

function Music (S:String):String;
var
   Octave:  integer;
   Duration:integer;
   Result:  string;
   Note:    integer;
   {}
   procedure Bump;
   begin
      S := Copy (S,2,length (S)-1);
      end;
   {}
begin
   Result   := '';
   Octave   := 3;
   Duration := 1;
   while (S<>'') do begin
      Note := -1;
      case Upcase (S[1]) of
         'T': begin Duration := 1; Bump; end;
         'S': begin Duration := 2; Bump; end;
         'I': begin Duration := 4; Bump; end;
         'Q': begin Duration := 8; Bump; end;
         'H': begin Duration := 16;Bump; end;
         'W': begin Duration := 32;Bump; end;
         '.': begin
            Duration := (Duration*3) div 2;
            Bump;
            end;
         '3': begin
            Duration := Duration div 3;
            Bump;
            end;
         '+': begin if Octave < 6 then Octave := Octave + 1; Bump; end;
         '-': begin if Octave > 1 then Octave := Octave - 1; Bump; end;
         'A'..'G': begin
            case Upcase (S[1]) of
               'C': begin Note := 0; Bump; end;
               'D': begin Note := 2; Bump; end;
               'E': begin Note := 4; Bump; end;
               'F': begin Note := 5; Bump; end;
               'G': begin Note := 7; Bump; end;
               'A': begin Note := 9; Bump; end;
               'B': begin Note := 11;Bump; end;
               end;
            case upcase (S[1]) of
               '!': begin Note := Note - 1; Bump; end;
               '#': begin Note := Note + 1; Bump; end;
               end;
            Result := Result + chr (Octave*$10+Note)+chr(Duration);
            end;
         'X': begin
            Result := Result + #0 + chr (Duration);
            Bump;
            end;
         '0'..'9': begin
            Result := Result + chr ($f0+Ord(S[1])-Ord('0')) + chr (Duration);
            Bump;
            end;
         else begin
            Bump;
            end;
         end;
      end;
   Music := Result;
   end;

begin
   InitNoteTable;
   InitDigits;
   {}
   TimerTested:= TestStart;
   TimerWorks := false;
   MyClock    := 0;
   LastSec100 := 0;
   {}
   SoundF     := true;
   SoundOff   := false;
   SoundStop;
   SoundSPeed := 1;
   MakeSound  := false;
   MyClock    := 0;
   New1CInt   := @TimerInt;
   GetIntVec($1C,Int1CSave);
   SetIntVec($1C,New1CInt);
   end.
