{$I-}
unit Fastwr;

interface

type
   String80 = string [80];

var
   FastWrite: procedure (Col, Row, Attrib:byte; Str:String80);
   MonoFlag:  boolean;

function  GetVideoMode:boolean;
procedure SetVideoMode;
procedure CursorOn;
procedure CursorOff;


implementation

uses Crt, Dos;

{$f+} procedure FastWriteColor (Col, Row, Attrib:byte; Str:String80); {$f-}
begin
  inline
    ($1E/$1E/$8A/$86/row/$B3/$50/$F6/$E3/$2B/$DB/$8A/$9E/col/
     $03/$C3/$03/$C0/$8B/$F8/$be/$00/$00/$8A/$BE/attrib/
     $8a/$8e/str/$22/$c9/$74/$3e/$2b/$c0/$8E/$D8/$A0/$49/$04/
     $1F/$2C/$07/$74/$22/$BA/$00/$B8/$8E/$DA/$BA/$DA/$03/$46/
     $8a/$9A/str/$EC/$A8/$01/$75/$FB/$FA/$EC/$A8/$01/$74/$FB/
     $89/$1D/$47/$47/$E2/$Ea/$2A/$C0/$74/$10/$BA/$00/$B0/
     $8E/$DA/$46/$8a/$9A/str/$89/$1D/$47/$47/$E2/$F5/$1F);
   inline ($fb);
   end;

{$f+} procedure FastWriteMono (Col, Row, Attrib:byte; Str:string80); {$f-}
begin
   if (Attrib and $09) = $09 then        {is highlighted and odd}
      Attrib := (Attrib and $f0) or $0f
   else if (Attrib and $07) <> $00 then  {is not black}
      Attrib := (Attrib and $f0) or $07;
   if (Attrib and $0f) = $00 then        {black foreground}
      Attrib := (Attrib and $8f) or $70
   else if (Attrib and $70) <> $70 then  {not white background}
      Attrib := (Attrib and $8f);
   inline
    ($1E/$1E/$8A/$86/row/$B3/$50/$F6/$E3/$2B/$DB/$8A/$9E/col/
     $03/$C3/$03/$C0/$8B/$F8/$be/$00/$00/$8A/$BE/attrib/
     $8a/$8e/str/$22/$c9/$74/$3e/$2b/$c0/$8E/$D8/$A0/$49/$04/
     $1F/$2C/$07/$74/$22/$BA/$00/$B8/$8E/$DA/$BA/$DA/$03/$46/
     $8a/$9A/str/$EC/$A8/$01/$75/$FB/$FA/$EC/$A8/$01/$74/$FB/
     $89/$1D/$47/$47/$E2/$Ea/$2A/$C0/$74/$10/$BA/$00/$B0/
     $8E/$DA/$46/$8a/$9A/str/$89/$1D/$47/$47/$E2/$F5/$1F);
   inline ($fb);
   end;

function GetVideoMode:boolean;
var
   Key:char;
begin
   Key := ' ';
   if LastMode = Mono then
      FastWrite := FastWriteMono
   else begin
      writeln;
      write ('  Video mode:  C)olor,  M)onochrome?  ');
      repeat
         repeat until Keypressed;
         Key := upcase (readkey)
         until Key in ['C','M',#$1b];
      case Key of
         'C':  MonoFlag := false;
         'M':  MonoFlag := true;
         #$1b: MonoFlag := (LastMode=Mono);
         end;
      end;
   GetVideoMode := (Key<>#$1b);
   end;

procedure SetVideoMode;
begin
   if MonoFlag then begin
      if LastMode in [co40,co80,bw40,bw80] then begin
         FastWrite := FastWriteMono;
         TextMode (bw80);
         end
      else begin
         FastWrite := FastWriteMono;
         TextMode (Mono);
         end;
      end
   else begin
      FastWrite := FastWriteColor;
      TextMode (c80);
      end;
   clrscr;
   end;

procedure Cursor (N:integer);
var
   Regs:registers;
begin
   Regs.ah := 01;
   Regs.cx := N;
   intr ($10,Regs);
   end;

procedure CursorOn;
begin
   Cursor (6*256+7);
   end;

procedure CursorOff;
begin
   Cursor (8192);
   end;

begin
   FastWrite := FastWriteMono;
   MonoFlag  := true;
   end.