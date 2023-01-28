{$I-}
unit Scrolls;

interface

const
   ScrollXs = 5;
   ScrollXl = 50;
   ScrollYs = 3;
   ScrollYl = 18;
   MaxScrollLines = 1024;
   ScrollBlank = '                                             ';
   ScrollMid   = ' '+#179+ScrollBlank+#179+' ';
   ScrollLine  = #$cd+#$cd+#$cd+#$cd+#$cd+#$cd+#$cd+#$cd+#$cd+
                 #$cd+#$cd+#$cd+#$cd+#$cd+#$cd+#$cd+#$cd+#$cd+
                 #$cd+#$cd+#$cd+#$cd+#$cd+#$cd+#$cd+#$cd+#$cd+
                 #$cd+#$cd+#$cd+#$cd+#$cd+#$cd+#$cd+#$cd+#$cd+
                 #$cd+#$cd+#$cd+#$cd+#$cd+#$cd+#$cd+#$cd+#$cd;
   ScrollTop   = #198+#209+ScrollLine+#209+#181;
   ScrollBot   = #198+#207+ScrollLine+#207+#181;
   ScrollDiv   = ' '+#$c6+ScrollLine+#$b5+' ';
   ScrollTB    = '                                    ';
   ScrollPick  = #$af+'                                           '+#$ae;


type
   OurString  = string [ScrollXl];
   ScrollType = record
      PickFlag: boolean;
      NumLines: integer;
      Cur:      integer;
      Line:     array [1..MaxScrollLines] of ^OurString;
      Cmd:      string [20];
      Title:    OurString;
      Fname:    OurString;
      end;
   DrawXYProcedure = procedure (X,Y:integer);

const
   MaxHelpFiles = 24;

var
   DrawXY:     DrawXYProcedure;
   Abort:      boolean; {For ViewScroll only}
   HelpFile:   OurString;
   HelpData:   record
      Num:     integer;
      Names:   array [1..MaxHelpFiles] of OurString;
      Offsets: array [1..MaxHelpFiles] of longint;
      end;
   ScSerNum:   ^OurString;


procedure OpenScroll (S:ScrollType);
procedure CloseScroll;
procedure DrawScroll (var S:ScrollType; Edflag, DocFlag:boolean);
procedure AddScrollLine (var S:ScrollType; M:OurString);
procedure EmptyScroll (var S:ScrollType);
procedure ViewScroll (var S:ScrollType; ObjFlag, DocFlag:boolean);
procedure EditScroll (var S:ScrollType);
procedure LoadScroll (Filename:OurString; var S:ScrollType);
procedure SaveScroll (Filename:OurString; var S:ScrollType);
procedure ViewDoc (Filename:string; M:string);
procedure InitScroll (var S:ScrollType);

implementation

uses
   Crt, Keyboard, Fastwr, GameCtrl, Printer;

{}
{}
{ Scroll (window) management }
{}

function caps (s:string):string;
var
   c:integer;
begin
   for c:=1 to length (s) do
      s[c] := upcase (s[c]);
   caps := s;
   end;

procedure InitScroll (var S:ScrollType);
begin with S do begin
   NumLines := 0;
   Cur      := 1;
   Fname    := '';
   end; end;

{}
{ DrawTitle - print scroll's title at top }
{}
procedure DrawTitle (Color:integer; Title:OurString);
begin
   fastwrite (ScrollXs+2,ScrollYs+1,Color,ScrollBlank);
   fastwrite (ScrollXs+(ScrollXl-length(Title)) div 2,
      ScrollYs+1, Color,Title);
   end;

{}
{ OpenScroll - draw scroll on screen, overlapping board }
{}
procedure OpenScroll (S:ScrollType);
var
   Xc,Yc:integer;
begin
   for Yc := (ScrollYl div 2) downto 0 do begin
      fastwrite (ScrollXs,ScrollYs+Yc+1,$0f,ScrollMid);
      fastwrite (ScrollXs,ScrollYs+ScrollYl-Yc-1,$0f,ScrollMid);
      fastwrite (ScrollXs,ScrollYs+Yc,$0f,ScrollTop);
      fastwrite (ScrollXs,ScrollYs+ScrollYl-Yc,$0f,ScrollBot);
      delay (25);
      end;
   fastwrite (ScrollXs, ScrollYs+2,$0f,ScrollDiv);
   DrawTitle ($1e,S.Title);
   end;

{}
{ CloseScroll - remove scroll from screen }
{}
procedure CloseScroll;
var
   Xc,Yc:integer;
begin
   for Yc := 0 to (ScrollYl div 2) do begin
      fastwrite (ScrollXs,ScrollYs+Yc,$0f,ScrollTop);
      fastwrite (ScrollXs,ScrollYs+ScrollYl-Yc,$0f,ScrollBot);
      delay (18);
      for Xc := ScrollXs to ScrollXs+ScrollXl do begin
         DrawXY (Xc-1,ScrollYs+Yc+1);
         DrawXY (Xc-1,ScrollYs+ScrollYl-Yc+1);
         end;
      end;
   end;

procedure DrawScrollLine (var S:ScrollType; Num:integer;
   Edflag, DocFlag:boolean);
var
   Y:  integer;
   P,C:integer;
   H:  integer;
begin with S do begin
   Y := ScrollYs + Num - Cur + (ScrollYl div 2) + 1;
   if (Num=Cur) then
      fastwrite (ScrollXs+2,Y,$1c, ScrollPick)
   else
      fastwrite (ScrollXs+2, Y, $1e, ScrollBlank);
   if (Num > 0) and (Num <= NumLines) then begin
      if Edflag then
         fastwrite (ScrollXs+4, Y, $1e, Line [Num]^)
      else begin
         P := 1;
         C := $1e;
         H := ScrollXS + 4;
         if length (S.Line [Num]^)>0 then case S.Line [Num]^[1] of
            '!': begin {Hyperflag}
               P := Pos (';',Line [Num]^)+1;
               fastwrite (H+2,Y,$1d,#$10);
               H := H + 5;
               C := $1f;
               end;
            ':': begin {label}
               P := Pos (';',Line [Num]^)+1;
               C := $1f;
               end;
            '$': begin
               P := 2;
               C := $1f;
               H := H - 4 + (ScrollXl - length (Line[Num]^)) div 2
               end
            end;
         if P>0 then
            fastwrite (H, Y, C, copy (Line [Num]^,P,
               length (Line [Num]^)-P+1));
         end;
      end
   else if (Num=0) or (Num=S.NumLines+1) then
      fastwrite (ScrollXs+2, Y, $1e, ScrollTB)
   else if (Num=-4) and DocFlag then begin
      fastwrite (ScrollXs+6, Y, $1a, '   Use            to view text,');
      fastwrite (ScrollXs+13,Y, $1f, #$18+' '+#$19+', Enter');
      end
   else if (Num=-3) and DocFlag then begin
      fastwrite (ScrollXs+7, Y, $1a, '                 to print.');
      fastwrite (ScrollXs+18,Y, $1f, 'Alt-P');
      end;
   end; end;

procedure DrawScroll (var S:ScrollType; Edflag, DocFlag:boolean);
var
   C:  integer;
   Num:integer;
begin
   for C := 0 to ScrollYl-4 do begin
      DrawScrollLine (S, S.Cur - (ScrollYl) div 2 + C + 2,Edflag,DocFlag);
      end;
   DrawTitle ($1e,S.Title);
   end;

procedure AddScrollLine (var S:ScrollType; M:OurString);
begin with S do begin
   NumLines := NumLines + 1;
   new (Line [NumLines]);
   Line [NumLines]^ := M;
   end; end;

procedure EmptyScroll (var S:ScrollType);
begin with S do begin
   while NumLines>0 do begin
      dispose (Line [NumLines]);
      NumLines := NumLines - 1;
      end;
   Fname := '';
   end; end;

procedure PrintScroll (var S:ScrollType);
var
   C,D: integer;
   Str: string;
begin with S do begin
   rewrite (Lst);
   for C := 1 to NumLines do begin
      Str := Line [C]^;
      if length (Str)>0 then case Str[1] of
         '$': begin
            Delete (Str,1,1);
            for D := (80-length(Str)) div 2 downto 1 do
               Str := ' '+Str;
            end;
         '!',':': begin
            D := pos (';',Str);
            if D>0 then
               delete (Str,1,d)
            else
               Str := '';
            end
         else begin
            Str := '          '+Str;
            end;
         end;
      writeln (Lst,Str);
      if IOResult<>0 then begin
         close (Lst);
         exit;
         end;
      end;
   if Fname='ORDER.HLP' then
      writeln (Lst,ScSerNum^);
   write (Lst,#$0c); {Form feed}
   close (Lst);
   end; end;

procedure ViewScroll (var S:ScrollType; ObjFlag, DocFlag:boolean);
var
   NewCur:integer;
   Ofs:   integer;
   C,D:   integer;
   Str:   string [20];
label
   Reloop, Out;
begin with S do begin
   Abort := false;
   Cmd   := '';
   DrawScroll (S,false, DocFlag);
   repeat
      CheckCtrl;
      NewCur := Cur;
      if Dy1<>0 then begin
         NewCur := NewCur + Dy1;
         end
      else if Fire1 or (Key=Return) then begin
         Fire1Off := true;
         if (Line [Cur]^[1]='!') then begin
            Str := copy (Line [Cur]^,2,length (Line [Cur]^)-1);
            if Pos (';',Str) > 0 then
               Str := copy (Str,1,pos (';',Str)-1);
            if Str [1]='-' then begin
               Delete (Str,1,1);
               EmptyScroll (S);
               LoadScroll (Str,S);
               if S.NumLines = 0 then
                  exit
               else begin
                  DocFlag := true;
                  NewCur := Cur;
                  DrawScroll (S,false,DocFlag);
                  Key   := #0;
                  Fire1 := false;
                  end;
               end
            else if ObjFlag then begin
               Cmd := Str;
               end
            else begin
               Str := ':'+Str;
               for C := 1 to NumLines do begin
                  if length (Line [C]^)<length (Str) then
                     goto Reloop;
                  for D := 1 to length (Str) do begin
                     if Upcase (Str[D]) <> Upcase (Line [C]^[D]) then
                        goto Reloop;
                     end;
                  NewCur := C;
                  Key    := #0;
                  Fire1  := false;
                  goto Out;
                  Reloop:
                  end;
               end;
            end;
         end
      else if Key=PgUp   then NewCur := Cur - ScrollYl + 4
      else if Key=PgDown then NewCur := Cur + ScrollYl - 4
      else if (Key=AltP) then begin
         PrintScroll (S)
         end;
      {} Out:
      if NewCur < 1 then
         NewCur := 1
      else if NewCur > S.NumLines then
         NewCur := NumLines;
      if NewCur <> Cur then begin
         Cur := NewCur;
         DrawScroll (S,false,DocFlag);
         if Line [Cur]^[1]='!' then begin
            if ObjFlag then begin
               DrawTitle ($1e,#$ae+'Press ENTER to select this'+#$af);
               end
            else begin
               DrawTitle ($1e,#$ae+'Press ENTER for more info'+#$af);
               end;
            end;
         end;
      if Flow1 then
         delay (35);
      until (Key = Escape) or (Key=Return) or (Fire1);
   if Key=Escape then begin
      Key   := #$00;
      Abort := true;
      end;
   end; end;

procedure EditScroll (var S:ScrollType);
var
   NewCur:integer;
   Ins:   boolean;
   X,C:   integer;
   {}
   procedure DelLine;
   var
      C:integer;
   begin with S do begin
      if NumLines > 1 then begin
         dispose (Line [Cur]);
         for C := Cur+1 to NumLines do
            Line [C-1] := Line [C];
         NumLines := NumLines - 1;
         if Cur > NumLines then
            NewCur := NumLines
         else
            DrawScroll (S,true,false);
         end
      else
         Line [1]^ := '';
      end; end;
   {}
begin with S do begin
   if NumLines = 0 then
      AddScrollLine (S,'');
   Ins := true;
   Cur := 1;
   X   := 1;
   {}
   DrawScroll (S,true,false);
   {}
   repeat
      if Ins then
         fastwrite (77,14,$1e,'on ')
      else
         fastwrite (77,14,$1e,'off');
      if X >= (length (Line [Cur]^)+1) then begin
         X := length (Line [Cur]^)+1;
         fastwrite (X+ScrollXs+3,ScrollYs+ScrollYl div 2+1,$70,' ');
         end
      else
         fastwrite (X+ScrollXs+3,ScrollYs+ScrollYl div 2+1,$70,Line [Cur]^[X]);
      GetKey;
      NewCur := Cur;
      case Key of
         UpK:    NewCur := Cur - 1;
         DownK:  NewCur := Cur + 1;
         PgUp:   NewCur := Cur - ScrollYl + 4;
         PgDown: NewCur := Cur + ScrollYl - 4;
         RightK: begin
            X := X + 1;
            if X > (length (Line [Cur]^)+1) then begin
               X := 1;
               NewCur := Cur+1;
               end;
            end;
         LeftK:  begin
            X := X - 1;
            if X < 1 then begin
               X := ScrollXl;
               NewCur := Cur-1;
               end;
            end;
         Return: begin
            if NumLines < MaxScrollLines then begin
               for C := NumLines downto Cur+1 do
                  Line [C+1] := Line [C];
               new (Line [Cur+1]);
               Line [Cur+1]^ := copy (Line [Cur]^, X,
                  length (Line [Cur]^)-X+1);
               Line [Cur]^   := copy (Line [Cur]^, 1, X-1);
               NewCur   := Cur + 1;
               X        := 1;
               NumLines := NumLines + 1;
               end;
            end;
         #$08: begin
            if (X>1) then begin
               Line [Cur]^ := copy (Line [Cur]^,1,X-2)+ copy (Line [Cur]^,
                  X,length (Line [Cur]^)-X+1);
               X := X - 1;
               end
            else if Line [Cur]^='' then begin
               DelLine;
               NewCur := Cur-1;
               X      := ScrollXl;
               end;
            end;
         Insert: begin
            Ins := not Ins;
            end;
         DeleteK: begin
            Line [Cur]^ := copy (Line [Cur]^,1,X-1)+copy (Line [Cur]^,
               X+1,length (Line [Cur]^)-X);
            end;
         #$019: begin {Ctrl-Y}
            DelLine;
            end
         else begin
            if (Key >= ' ') and (X<(ScrollXl-7)) then begin
               if not Ins then begin
                  Line [Cur]^ := copy (Line [Cur]^,1,x-1)+Key+copy (
                     Line [Cur]^,X+1,length (Line [Cur]^)-X);
                  X := X + 1;
                  end
               else if (length (Line[Cur]^) < (ScrollXl-8)) then begin
                  Line [Cur]^ := copy (Line [Cur]^,1,x-1)+Key+copy (
                     Line [Cur]^,X,length (Line [Cur]^)-X+1);
                  X := X + 1;
                  end;
               end;
            end;
         end;
      if NewCur < 1 then
         NewCur := 1
      else if NewCur > NumLines then
         NewCur := NumLines;
      if NewCur <> Cur then begin
         Cur := NewCur;
         DrawScroll (S,true,false);
         end
      else
         DrawScrollLine (S,Cur,true,false);
      until (Key=Escape);
   if Line [NumLines]^ = '' then begin
      dispose (Line [NumLines]);
      NumLines := NumLines - 1;
      end;
   end; end;

procedure LoadScroll (Filename:OurString; var S:ScrollType);
var
   F:     File;
   T:     Text;
   C,N:   integer;
   Flag:  boolean;
   TempP: pointer;
   TempB: byte;
begin with S do begin
   Flag  := true;
   for C := 1 to length (Filename) do
      Flag := Flag and (Filename [c]<>'.');
   if Flag then
      Filename := Filename + '.HLP';
   {}
   if Filename[1]='*' then begin
      Filename := copy (Filename,2,length(Filename)-1);
      N := -1; {Don't load from help data file}
      end
   else
      N := 0; {Try to load from help data file}
   {}
   InitScroll (S);
   Fname := caps (Filename);
   {}
   if (HelpData.Num=0) then begin
      assign (F,HelpFile);
      reset (F,1);
      if IOResult = 0 then
         blockread (F, HelpData, sizeof (HelpData));
      if IOResult <> 0 then
         HelpData.Num := -1;
      close (F);
      end;
   {}
   if N=0 then
      for C := 1 to HelpData.Num do

         if caps(HelpData.Names[c]) = caps(FileName) then
            N := C;
   {}
   if N <= 0 then begin
      assign (T,Filename);
      reset (T);
      while (IOResult=0) and (not EOF(T)) do begin
         inc (NumLines);
         new (Line[NumLines]);
         readln (T,Line[NumLines]^);
         end;
      close (T);
      end
   else begin
      assign (F,HelpFile);
      reset  (F,1);
      seek   (F,HelpData.Offsets[N]);
      if IOResult<>0 then Exit;
      Flag := true;
      while (IoResult=0) and (Flag) do begin
         inc (NumLines);
         new (Line [NumLines]);
         {}
         blockread (F,Line [NumLines]^,1);
         TempP := ptr (seg (Line [NumLines]^),ofs(Line [NumLines]^)+1);
         TempB := length (Line [NumLines]^);
         if TempB = 0 then begin
            Line [NumLines]^ := '';
          end
         else
           begin
            blockread (F,TempP^,length (Line [NumLines]^));
           end;
         {}
         if Line[NumLines]^='@' then begin
            Flag := false;
            Line[NumLines]^ := '';
            end;
         end;
      close (F);
      end;
   end; end;

procedure SaveScroll (Filename:OurString; var S:ScrollType);
var
   T: Text;
   C: integer;
begin with S do begin
   assign (T,Filename);
   rewrite (T);
   if IOResult<>0 then exit;
   for C := 1 to NumLines do begin
      writeln (T,Line [C]^);
      if IOResult<>0 then exit;
      end;
   close (T);
   end; end;

procedure ViewDoc (Filename:string; M:string);
var
   S:ScrollType;
begin with S do begin
   S.Title := M;
   LoadScroll (Filename,S);
   PickFlag := false;
   if NumLines > 0 then begin
      OpenScroll (S);
      ViewScroll (S,false,true);
      CloseScroll;
      end;
   EmptyScroll (S);
   end; end;

{$F+}

procedure DrawBlank (X,Y:integer);
begin
   fastwrite (X,Y,$0f,' ');
   end;

{$F-}

begin
   DrawXY       := DrawBlank;
   HelpFile     := '';
   HelpData.Num := 0;
   end.
