unit GameCtrl;

interface

const
   {}
   { Keyboard characters }
   {}
   UpK     = #200;
   LeftK   = #203;
   DownK   = #208;
   RightK  = #205;
   Return  = #13;
   Enter   = #13;
   Tab     = #9;
   Insert  = #210;
   DeleteK = #211;
   Space   = ' ';
   Escape  = #27;
   AltP    = #153;
   PgUp    = #201;
   PgDown  = #209;
   f1      = #187;
   f2      = #188;
   f3      = #189;
   f4      = #190;
   f5      = #191;
   f6      = #192;
   f7      = #193;
   f8      = #194;
   f9      = #195;
   f10     = #196;

var
   Dx1,Dy1:  integer;
   Fire1:    boolean;
   Fire1Off: boolean;
   JoyFlag:  boolean;
   MouseFlag:boolean;
   Key:      char;
   MouseX,
   MouseY:   integer;
   MouseXscale,
   MouseYscale: integer;
   Dx1Hold,
   Dy1Hold:  integer;
   Flow1:    boolean; {true if joystick movement}
   JoyXSense,
   JoyYSense:integer;

procedure CheckCtrl;
procedure SenseCtrlMode;
function  GetCtrlMode:boolean;
procedure GetKey;

implementation

uses
   Crt, Dos, Keyboard, SoundU;

var
   JoyXL,JoyXC,JoyXR,JoyYU,JoyYC,JoyYD: integer;
   Keybuf: string;

function ButtonA1:boolean;
begin
   ButtonA1 := ((port[$201] and $10) = 0);
   end;

function ButtonA2:boolean;
begin
   ButtonA2 := ((port[$201] and $20) = 0);
   end;

function ButtonA:boolean;
begin
   ButtonA := ((port[$201] and $30) <> $30);
   end;

procedure ReadJoy (var X,Y:integer);
var
   N:integer;
begin
   X := 0; Y := 0; N := MyClock;
   Port [$201] := 00;
   repeat
      X := X + Port [$201] and $01;
      Y := Y + Port [$201] and $02;
      until ((Port [$201] and $03) = 0) or ((MyClock-N)>3);
   Y := Y div 2;
   if (MyClock-N)>3 then begin
       X := -1; Y := -1;
       end;
   end;

function CalDir (S:string; var JX,JY:integer):boolean;
var
   Key:char;
begin
   Key := #0;
   write (S);
   repeat
      ReadJoy (Jx,Jy);
      if Keypressed then
         Key := ReadKey;
      until (Key = Escape) or ButtonA;
   delay (25);
   if Key<>Escape then begin
      CalDir := true;
      repeat
         if Keypressed then
            Key := ReadKey;
         until (not ButtonA) or (Key=Escape);
      end;
   delay (25);
   if Key=Escape then
      CalDir := false;
   writeln;
   writeln;
   end;

function JoyPresent:boolean;
var
   X,Y:integer;
begin
   ReadJoy (X,Y);
   if (X>0) and (Y>0) then begin
      JoyXSense  := X;
      JoyYSense  := Y;
      JoyPresent := true
      end
   else
      JoyPresent := false;
   end;

procedure CalibrateJoy;
var
   Key:char;
label
   Redo;
begin
   {} Redo:
   Joyflag := false;
   writeln;
   writeln ('  Joystick calibration:  Press ESCAPE to abort.');
   writeln;
   if CalDir ('  Center joystick and press button: ',
      JoyXC,JoyYC) and
      CalDir ('  Move joystick to UPPER LEFT corner and press button: ',
      JoyXL,JoyYU) and
      CalDir ('  Move joystick to LOWER RIGHT corner and press button: ',
      JoyXR,JoyYD) then begin
      JoyXL := JoyXL-JoyXC;
      JoyXR := JoyXR-JoyXC;
      JoyYU := JoyYU-JoyYC;
      JoyYD := JoyYD-JoyYC;
      if (JoyXL<1) and (JoyXR>1) and (JoyYU<1) and (JoyYD>1) then
         JoyFlag := true
      else begin
         write ('  Calibration failed - try again (y/N)? ');
         repeat until Keypressed;
         Key := readkey;
         writeln;
         if Upcase (Key) = 'Y' then goto Redo;
         end;
      end;
   end;

procedure CheckCtrl;
var
   X1,Y1,Xs,Ys: integer;
   R:           registers;
begin
   Dx1 := 0; Dy1 := 0; Fire1 := false; Flow1 := false;
   while Keypressed do begin
      Key := readkey;
      if (Key=#0) or (Key=#1) or (Key=#2) then
         Keybuf := Keybuf + chr(ord(Readkey) or 128)
      else
         Keybuf := Keybuf + Key;
      end;
   if Keybuf <> '' then begin
      Key := Keybuf[1];
      if length (Keybuf)=1 then
         Keybuf := ''
      else
         Keybuf := copy (Keybuf,length (Keybuf)-1,1);
      case Key of
         UpK,'8': begin
            Dx1 := 0; Dy1 := -1;
            end;
         LeftK,'4': begin
            Dx1 := -1; Dy1 := 0;
            end;
         RightK,'6': begin
            Dx1 := 1; Dy1 := 0;
            end;
         DownK,'2': begin
            Dx1 := 0; Dy1 := 1;
            end;
         end;
      end
   else begin
      Key := #0;
      end;
   if (Dx1<>0) or (Dy1<>0) then begin
      KbdStatus;
      Fire1 := KShift;
      end
   else if JoyFlag then begin
      ReadJoy (X1,Y1);
      Xs := (X1-JoyXc);
      Ys := (Y1-JoyYc);
      if abs (Xs) > abs (Ys) then begin
         if Xs<(JoyXL div 2) then begin
            Dx1 := -1; Flow1 := true;
            end
         else if Xs>(JoyXR div 2) then begin
            Dx1 := 1; Flow1 := true;
            end;
         end
      else begin
         if Ys<(JoyYU div 2) then begin
            Dy1 := -1; Flow1 := true;
            end
         else if Ys>(JoyYD div 2) then begin
            Dy1 := 1; Flow1 := true;
            end;
         end;
      if ButtonA then begin {Handle press/release}
         if not Fire1Off then begin
            Fire1 := true;
            end;
         end
      else
         Fire1Off := false;
      end
   else if MouseFlag then begin
      R.ax := 11;
      intr ($33,R);
      MouseX := MouseX + integer (R.cx);
      MouseY := MouseY + integer (R.dx);
      if abs (MouseX)>abs(MouseY) then begin
         if abs(MouseX)>MouseXscale then begin
            if MouseX>0 then
               Dx1 := 1
            else
               Dx1 := -1;
            MouseX := 0;
            end;
         end
      else if abs (MouseY)>abs(MouseX) then begin
         if abs(MouseY)>MouseYscale then begin
            if MouseY>0 then
               Dy1 := 1
            else
               Dy1 := -1;
            MouseY := 0;
            end;
         end;
      R.ax := 3;
      intr ($33,R);
      if (R.bx and $01)<>0 then begin
         if not Fire1Off then begin
            Fire1 := true;
             end;
        end
      else
         Fire1Off := false;
      if (R.bx and $06)<>0 then begin
         if (Dx1<>0) or (Dy1<>0) then begin
            Dx1Hold := Dx1;
            Dy1Hold := Dy1;
            end
         else begin
            Dx1 := Dx1Hold;
            Dy1 := Dy1Hold;
            end;
         end
      else begin
         Dx1Hold := 0;
         Dy1Hold := 0;
         end
      end;
   end;

function MousePresent:boolean;
var
   R:registers;
begin
   R.ax := 0;
   intr ($33,R);
   MousePresent := (R.Ax = 0);
   MousePresent := true;
   end;

procedure SenseCtrlMode;
begin
   JoyFlag   := JoyPresent;
   MouseFlag := MousePresent;
   end;

function GetCtrlMode:boolean;
var
   Key:char;
begin
   Key := ' ';
   if (JoyFlag or MouseFlag) then begin
      writeln;
      write ('  Game controller:  K)eyboard');
      if JoyFlag then
         write (',  J)oystick');
      if MouseFlag then
         write (',  M)ouse');
      write ('?  ');
      repeat
         repeat until Keypressed;
         Key := upcase (readkey);
         until (Key='K') or (JoyFlag and (Key='J')) or
            (MouseFlag and (Key='M')) or (Key=#$1b);
      writeln;
      JoyFlag   := false;
      MouseFlag := false;
      case Key of
         'J': begin
            JoyFlag   := true;
            CalibrateJoy;
            end;
         'M': MouseFlag := true;
         {'K' implied}
         end;
      writeln;
      end;
   GetCtrlMode := (Key<>#$1b);
   end;

procedure GetKey;
begin
   repeat
      CheckCtrl;
      until Key <> #0;
   end;


begin
   Dx1 := 0; Dy1 := 0; Fire1 := false; Fire1Off := false;
   MouseX := 0; MouseY := 0;
   MouseXscale := 60;
   MouseYscale := 60;
   Dx1Hold := 0; Dy1Hold := 0;
   Keybuf := '';
   end.