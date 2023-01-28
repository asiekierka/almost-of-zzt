unit Keyboard;


interface

var
   KRShift, KLShift, KShift, KCtrl, KAlt, KNumLock: boolean;

procedure KbdStatus;


implementation

uses
   Dos;

procedure KbdStatus;
var
   R:Registers;
begin
   R.AH := $02;
   Intr ($16,R);
   KRShift := (R.AL mod 2) = 1;
   KLShift := ((R.AL div 2) mod 2) = 1;
   KCtrl   := ((R.AL div 4) mod 2) = 1;
   KAlt    := ((R.AL div 8) mod 2) = 1;
   KNumLock:= ((R.AL div 32)mod 2) = 1;
   KShift  := KRShift or KLShift;
   end;

begin
   end.