{$I-}
unit Lang;

{}
{ ZZT-OOP - language interpretter }
{}

interface

uses
   FastWr, Crt, Dos, Keyboard, SoundU,
   GameCtrl,
   Scrolls;

function LSendMsg (N:integer; Msg:String; IgnoreLock:boolean):boolean;
procedure ExecObj (N:integer; var Ofs:integer; M:OurString);
procedure SetFlag (Word:OurString);
procedure ClearFlag (Word:OurString);
function FlagNum (Word:OurString):integer;

implementation

uses
   Glob, Obj, Main;


procedure LError (N:integer; S:string);
begin with U,Objs [N] do begin
   PutBotMsg (200,'ERR: '+S);
   SoundAdd (5,#$50+#10);
   Offset := -1;
   end; end;

procedure LGetChar (N:integer; var Ofsc:integer);
begin with U,Objs [N] do begin
   if (Ofsc>=0) and (Ofsc < InsideLen) then begin
      move (Ptr (Seg (Inside^),Ofs (Inside^)+Ofsc)^,LChar,1);
      inc (Ofsc);
      end
   else
      LChar := #0;
   end; end;

procedure LGetWord (N:integer; var Ofs:integer);
begin
   LWord := '';
   repeat
      LGetChar (N,Ofs);
      until LChar <> ' ';
   LChar := Upcase (LChar);
   if (LChar<'0') or (LChar>'9') then
      while ((LChar >= 'A') and (LChar <= 'Z')) or (LChar=':') or
            ((LChar >= '0') and (LChar <= '9')) or (LChar='_') do begin
         LWord := LWord + LChar;
         LGetChar (N,Ofs);
         LChar := Upcase (LChar);
         end;
   if (Ofs > 0) then
      Dec (Ofs);
   end;

procedure LGetNum (N:integer; var Ofs:integer);
var
   Word:    string [20];
   TempInt: integer;
begin
   Word := '';
   repeat
      LGetChar (N,Ofs);
      until LChar <> ' ';
   LChar := Upcase (LChar);
   while (LChar >= '0') and (LChar <= '9') do begin
      Word := Word + LChar;
      LGetChar (N,Ofs);
      LChar := Upcase (LChar);
      end;
   if Ofs > 0 then
      Ofs := Ofs - 1;
   if Word <> '' then
      Val (Word,LNum,TempInt)
   else
      LNum := -1;
   end;

procedure LNewLine (N:integer; var Ofs:integer);
begin
   repeat
      LGetChar (N,Ofs)
      until (LChar = #$00) or (LChar=#$0d);
   end;

function LNoteDir (N:integer; var Ofs:integer; var Dx,Dy:integer):boolean;
begin with U,Objs [N] do begin
   LNoteDir := true;
   if (LWord = 'N') or (LWord = 'NORTH') then begin
      Dx := 0; Dy := -1;
      end
   else if (LWord = 'S') or (LWord = 'SOUTH') then begin
      Dx := 0; Dy := 1;
      end
   else if (LWord = 'E') or (LWord = 'EAST') then begin
      Dx := 1; Dy := 0;
      end
   else if (LWord = 'W') or (LWord = 'WEST') then begin
      Dx := -1; Dy := 0;
      end
   else if (LWord = 'I') or (LWord = 'IDLE') then begin
      Dx := 0; Dy := 0;
      end
   else if (LWord = 'SEEK') then begin
      SeekPlayer (X,Y,Dx,Dy);
      end
   else if (LWord = 'FLOW') then begin
      Dx := Xd;
      Dy := Yd;
      end
   else if (LWord = 'RND') then begin
      PickRandomDir (Dx,Dy);
      end
   else if (LWord = 'RNDNS') then begin
      Dx := 0;
      Dy := random (2)*2-1;
      end
   else if (LWord = 'RNDNE') then begin
      Dx := random (2);
      if Dx=0 then
         Dy := -1
      else
         Dy := 0;
      end
   else if (LWord='CW') then begin
      LGetWord (N,Ofs);
      LNoteDir := LNoteDir (N,Ofs,Dy,Dx);
      Dx   := -Dx;
      end
   else if (LWord='CCW') then begin
      LGetWord (N,Ofs);
      LNoteDir := LNoteDir (N,Ofs,Dy,Dx);
      Dy   := -Dy;
      end
   else if (LWord='RNDP') then begin
      LGetWord (N,Ofs);
      LNoteDir := LNoteDir (N,Ofs,Dy,Dx);
      if Random (2)=0 then
         Dx := -Dx
      else
         Dy := -Dy;
      end
   else if (LWord='OPP') then begin
      LGetWord (N,Ofs);
      LNoteDir := LNoteDir (N,Ofs,Dx,Dy);
      Dx   := -Dx;
      Dy   := -Dy;
      end
   else begin
      Dx := 0; Dy := 0;
      LNoteDir := false;
      end;
   end; end;

procedure LGetDir (N:integer; var Ofs:integer; var Dx,Dy:integer);
begin
   LGetWord (N,Ofs);
   if not LNoteDir (N,Ofs,Dx,Dy) then
      LError (N,'Bad direction');
   end;


{}
{ Will match ABC to ABCDEF, so add CR to Str before calling...}
{}
{ Finds position of Str in object N, or returns -1. }
{}

function LSeek (N:integer; Str:string):integer;
var
   C,D: integer;
   Ofs: integer;
label
   Out,Next;
begin with U,Objs [N] do begin
   C   := 0;
   while C <= InsideLen do begin
      D   := 1;
      Ofs := C;
      repeat
         LGetChar (N,Ofs);
         if Upcase (Str [D]) <> Upcase (LChar) then
            goto Next;
         D := D + 1;
         until (D>length (Str));
      LGetChar (N,Ofs);
      LChar := Upcase (LChar);
      if ((LChar>='A') and (LChar<='Z')) or (LChar='_') then
         goto Next;
      LSeek := C;
      goto Out;
      {} Next:
      C := C + 1;
      end;
   LSeek := -1;
   {} Out:
   end; end;

function LFindObj (N:integer; var DestObj:integer; DestName:string):boolean;
var
   TitleOfs: integer;
   Found:    boolean;
begin with U do begin
   DestObj := DestObj + 1;
   Found   := false;
   if (DestName = 'ALL') then begin
      if (DestObj<=NumObjs) then
         Found := true;
      end
   else if (DestName='OTHERS') then begin
      if (DestObj<=NumObjs) then begin
         if (DestObj<>N) then
            Found := true
         else begin
            DestObj := DestObj+1;
            Found := (DestObj <= NumObjs);
            end;
         end;
      end
   else if (DestName='SELF') then begin
      if (N>0) and (DestObj<=N) then begin
         DestObj := N;
         Found   := true;
         end;
      end
   else begin
      while (DestObj<=NumObjs) and (not Found) do begin
         if Objs [DestObj].Inside <> nil then begin
            TitleOfs := 0;
            LGetChar (DestObj,TitleOfs);
            if LChar = '@' then begin
               LGetWord (DestObj,TitleOfs);
               if LWord = DestName then begin
                  Found   := true;
                  end;
               end;
            end;
         if not Found then
            DestObj := DestObj + 1;
         end;
      end;
   LFindObj := Found;
   end; end;

{}
{ Could be simplified by pre-splitting MSG!}
{}
function LFindLabel (N:integer; Msg:string;
   var DestObj,DestOfs:integer; Before:string):boolean;
{}
{  Input:   DestObj = Object # to start searching AFTER. }
{ Output:   returns true: DestObj = Matching object }
{                  false: no match }
{}
var
   Posn:      integer;
   C:         integer;
   DestName:  string [20];
   DestLabel: string [20];
   Found:     boolean;
label
   LFindObjLoop;
begin with U do begin
   Found := false; {We're using Found as temp at first}
   Posn := Pos (':',Msg);
   if Posn <= 0 then begin
      if (DestObj<N) then begin {implies N>0}
         DestLabel := Msg;
         DestObj   := N;
         Posn      := 0;
         Found     := true;
         end;
      end
   else begin
      DestName := copy (Msg,1,Posn-1);
      DestLabel:= copy (Msg,Posn+1,length (Msg)-Posn);
      LFindObjLoop:
      Found := LFindObj (N,DestObj,DestName);
      end;
   if Found then begin
      if DestLabel = 'RESTART' then begin
         DestOfs := 0;
         end
      else begin
         DestOfs := LSeek (DestObj,Before+DestLabel);
         if (DestOfs<0) and (Posn>0) then
            goto LFindObjLoop;
         end;
      Found := (DestOfs >= 0);
      end;
   LFindLabel := Found;
   end; end;

function FlagNum (Word:OurString):integer;
{}
{ Returns number of flag (Word) in G.I.Flags, or -1 if none. }
{}
var
   C:integer;
begin
   FlagNum := -1;
   for C := 1 to NumFlags do begin
      if G.I.Flags [C] = Word then
         FlagNum := C;
      end;
   end;

procedure SetFlag (Word:OurString);
var
   C:integer;
begin
   if (FlagNum(Word)<0) then begin
      C := 1;
      while (C < NumFlags) and (G.I.Flags [C]<>'') do
         C := C + 1;
      G.I.Flags [C] := Word;
      end;
   end;

procedure ClearFlag (Word:OurString);
var
   C:integer;
begin
   if (FlagNum(Word)>=0) then begin
      G.I.Flags [FlagNum(Word)] := '';
      end;
   end;

function XUpcase (S:OurString):OurString;
{}
{ Translate S to uppercase, deleting spaces & non-word characters. }
{ i.e. Slider (NS) -> SLIDERNS }
{}
var
   R:OurString;
   C:integer;
begin
   R := '';
   for C := 1 to length (S) do begin
      if ((S[C]>='A') and (S[C]<='Z')) or
         ((S[C]>='0') and (S[C]<='9')) then
         R := R + S[C]
      else if (S[C]>='a') and (S[C]<='z') then
         R := R + chr (ord (S[C])-32);
      end;
   XUpCase := R;
   end;

function LGetKind (var N,Ofs:integer; var TempCell:BoardCell):boolean;
{}
var
   C:integer;
label
   L1,L2;
begin
   LGetKind := false;
   TempCell.Color := 0;
   LGetWord (N,Ofs);
   for C := 1 to 7 do
      if LWord = XUpcase (Colors [C]) then begin
         TempCell.Color := C+8;
         LGetWord (N,Ofs);
         goto L1;
         end;
   {} L1:
   for C := 0 to NumClasses do begin
      if LWord = XUpcase (Info [C].Descr) then begin
         LGetKind := true;
         TempCell.Kind := C;
         goto L2;
         end;
      end;
   {} L2:
   end;

function RealColor (var Cell:BoardCell):byte;
begin
   if Info [Cell.Kind].Col < $f0 then
      RealColor := Info [Cell.Kind].Col and $07
   else if Info [Cell.Kind].Col = $fe then
      RealColor := (((Cell.Color) shr 4) and $0f)+8
   else
      RealColor := Cell.Color and $0f;
   end;

function LocateKind (var TempX,TempY:integer; TempCell:BoardCell):boolean;
{}
{ On first call, let TempX=0, TempY=1. Checks all visible board. }
{}
label
   Out;
begin with U do begin
   LocateKind := false;
   repeat
      TempX := TempX + 1;
      if TempX > Xs then begin
         TempX := 1;
         TempY := TempY + 1;
         if TempY > Ys then
            goto Out;
         end;
      if (Board [TempX,TempY].Kind=TempCell.Kind) and
         ((TempCell.Color=0) or
         ((RealColor (Board [TempX,TempY]))=TempCell.Color)) then begin
         LocateKind := true;
         goto Out;
         end;
      until false;
   Out:
   end; end;

procedure ChangeCell (TempX,TempY:integer; var TempCell:BoardCell);
var
   TempColor:byte;
begin with U do begin
   if Board [TempX,TempY].Kind <> Player then begin
      TempColor := TempCell.Color;
      if Info [TempCell.Kind].Col < $f0 then
         TempColor := Info [TempCell.Kind].Col
      else begin
         if TempColor = 0 then
            TempColor := Board [TempX,TempY].Color;
         if TempColor = 0 then
            TempColor := $0f;
         {}
         if Info [TempCell.Kind].Col=$fe then
            TempColor := (TempColor-8)*$10+$0f
         end;
      if Board [TempX,TempY].Kind=TempCell.Kind then begin
         Board [TempX,TempY].Color := TempColor;
         end
      else begin
         Zap (TempX, TempY);
         if Info [TempCell.Kind].Cycle >= 0 then
            AddObj (TempX,TempY,TempCell.Kind,TempColor,
               Info [TempCell.Kind].Cycle, NormObj)
         else begin
            Board [TempX,TempY].Kind  := TempCell.Kind;
            Board [TempX,TempY].Color := TempColor;
            end;
         end;
      DrawCell (TempX,TempY);
      end;
   end; end;

function FlagEval (N:integer; var Ofs:integer):boolean;
{}
{ Evaluates LWORD and returns boolean }
{}
var
   Dx,Dy:       integer;
   TempCell:    BoardCell;
   TempX,TempY: integer;
begin with U,Objs [N] do begin
   if LWord = 'NOT' then begin
      LGetWord (N,Ofs);
      FlagEval := not FlagEval (N,Ofs);
      end
   else if LWord = 'ALIGNED' then
      FlagEval := (X=Objs[0].x) or (Y=Objs[0].y)
   else if LWord = 'CONTACT' then
      FlagEval := (sqr (X-Objs[0].x)+sqr (Y-Objs[0].y))=1
   else if LWord = 'BLOCKED' then begin
      LGetDir (N,Ofs,Dx,Dy);
      FlagEval := not Info [Board [X+Dx,Y+Dy].Kind].GoThru;
      end
   else if LWord = 'ENERGIZED' then
      FlagEval := G.I.Enertime > 0
   else if LWord = 'ANY' then begin
      if not LGetKind (N,Ofs,TempCell) then
         LError (N,'Bad object kind');
      TempX := 0; TempY := 1;
      FlagEval := LocateKind (TempX,TempY,TempCell);
      end
   else begin
      FlagEval := (FlagNum (LWord)>=0)
      end;
   end; end;

function LGetString (N:integer; var Ofs:integer):String;
var
   S:String;
begin
   S := '';
   LGetChar (N,Ofs);
   while (LChar <> #$00) and (LChar <> #$0d) do begin
      S := S + LChar;
      LGetChar (N,Ofs);
      end;
   LGetString := S;
   end;

function LSendMsg (N:integer; Msg:string; IgnoreLock:boolean):boolean;
{}
{ Returns true ONLY IF offset of current object, N, was changed }
{}
var
   DestOfs:   integer;
   DestObj:   integer;
   ExternMsg: boolean;
begin with U do begin
   if (N<0) then begin
      N := -N;
      ExternMsg := true;
      end
   else
      ExternMsg := false;
   LSendMsg := false;
   DestObj  := 0;
   while LFindLabel (N,Msg,DestObj,DestOfs,#$0d+':') do begin
      if (Objs [DestObj].Rate=0) or
         (IgnoreLock) or
         ((N=DestObj) and (not ExternMsg)) then begin
         {}
         if (DestObj = N) then
            LSendMsg := true; {Cumulative}
         Objs [DestObj].Offset := DestOfs;
         end;
      end;
   end; end;

procedure ExecObj (N:integer; var Ofs:integer; M:OurString);
var
   S:        ScrollType;
   TempStr:  string;
   Dx,Dy,
   TempX,TempY: integer;
   PollFlag,
   DieFlag,
   GotEnd:   boolean;
   DieCell:  BoardCell;
   NewOfs:   integer;
   StartOfs: integer;
   Redo:     boolean;
   NewLineF: boolean;
   TempPtr:  pointer;
   DestOfs,
   DestObj:  integer;
   IntPtr:   ^integer;
   TempFlag: boolean;
   TempInt:  integer;
   CmdsExec: integer;
   TempCell1,
   TempCell2:BoardCell;
   {}
label
   GetSymbol, GetCmd, Restart;
begin with U,Objs [N] do begin
   {}
   Restart:
   {}
   InitScroll (S);
   S.PickFlag := false;
   PollFlag   := false;
   Redo       := false;
   DieFlag    := false;
   GotEnd     := false;
   CmdsExec   := 0;
   {}
   repeat
      {}
      {} GetSymbol:
      {}
      NewLineF := true;
      StartOfs := Ofs;
      LGetChar (N,Ofs);
      while LChar=':' do begin
         repeat
            LGetChar (N,Ofs);
            until (LChar=#$00) or (LChar=#$0d);
         LGetChar (N,Ofs);
         end;
      if (LChar = '''') then begin {comment}
         LNewLine (N,Ofs);
         end
      else if (LChar = '@') then begin {name}
         LNewLine (N,Ofs);
         end
      else if (LChar='/') or (LChar='?') then begin {movement string/pause}
         if LChar = '/' then
            Redo := true;
         LGetWord (N,Ofs);
         if LNoteDir (N,Ofs,Dx,Dy) then begin
            if ((Dx<>0) or (Dy<>0)) then begin
               if not (Info [Board [X+Dx,Y+Dy].Kind].GoThru) then
                  Push (X+Dx,Y+Dy,Dx,Dy);
               if Info [Board [X+Dx,Y+Dy].Kind].GoThru then begin
                  MoveObj (N,X+Dx,Y+Dy);
                  Redo := false;
                  end;
               end
            else
               Redo := false;
            LGetChar (N,Ofs);
            if LChar <> #$0d then {Eat up CR}
               Dec (Ofs);
            PollFlag := true;
            end
         else
            LError (N,'Bad direction');
         end
      else if LChar = '#' then begin {command}
         {}
         {} GetCmd:
         {}
         LGetWord (N,Ofs);
         {}
         if (LWord = 'THEN') then
            LGetWord (N,Ofs); {!!}
         if (LWord = '') then
            goto GetSymbol;
         {}
         inc (CmdsExec);
         {}
         if LWord = '' then begin
            end
         else if LWord = 'GO' then begin
            LGetDir (N,Ofs,Dx,Dy);
            if not Info [Board [X+Dx,Y+Dy].Kind].GoThru then
               Push (X+Dx,Y+Dy,Dx,Dy);
            if Info [Board [X+Dx,Y+Dy].Kind].GoThru then
               MoveObj (N,X+Dx,Y+Dy)
            else
               Redo := true;
            PollFlag := true;
            end
         else if LWord='TRY' then begin
            LGetDir (N,Ofs,Dx,Dy);
            if not Info [Board [X+Dx,Y+Dy].Kind].GoThru then
               Push (X+Dx,Y+Dy,Dx,Dy);
            if Info [Board [X+Dx,Y+Dy].Kind].GoThru then begin
               MoveObj (N,X+Dx,Y+Dy);
               PollFlag := true;
               end
            else
               goto GetCmd; {Fail message}
            end
         else if LWord = 'WALK' then begin
            LGetDir (N,Ofs,Dx,Dy);
            Xd := Dx;
            Yd := Dy; {Or else variables interfere}
            end
         else if LWord = 'SET' then begin
            LGetWord (N,Ofs);
            SetFlag (LWord);
            end
         else if LWord = 'CLEAR' then begin
            LGetWord (N,Ofs);
            ClearFlag (LWord);
            end
         else if LWord = 'IF' then begin
            LGetWord (N,Ofs);
            if FlagEval (N,Ofs) then
               goto GetCmd; {Message if it's true}
            end
         else if LWord = 'SHOOT' then begin
            LGetDir (N,Ofs,Dx,Dy);
            if TryFire (Bullet,X,Y,Dx,Dy,1) then
               SoundAdd (2,#$30+#1+#$26+#1);
            PollFlag := true;
            end
         else if LWord = 'THROWSTAR' then begin
            LGetDir (N,Ofs,Dx,Dy);
            if TryFire (SBomb,X,Y,Dx,Dy,1) then begin end;
            PollFlag := true;
            end
         else if (LWord='GIVE') or (LWord='TAKE') then begin
            if LWord='TAKE' then
               TempFlag := true
            else
               TempFlag := false;
            LGetWord (N,Ofs);
            if LWord='HEALTH' then
               IntPtr := @G.I.Strength
            else if LWord='AMMO' then
               IntPtr := @G.I.Ammo
            else if LWord='GEMS' then
               IntPtr := @G.I.Gems
            else if LWord='TORCHES' then
               IntPtr := @G.I.Torches
            else if LWord='SCORE' then
               IntPtr := @G.I.Score
            else if LWord='TIME' then
               IntPtr := @G.I.RoomTime
            else
               IntPtr := nil;
            {}
            if IntPtr <> nil then begin
               LGetNum (N,Ofs);
               if LNum>0 then begin
                  if TempFlag then
                     LNum := -LNum;
                  if (IntPtr^ + LNum) >= 0 then begin
                     IntPtr^ := IntPtr^ + LNum;
                     end
                  else
                     goto GetCmd; {Fail message}
                  end;
               end;
            PrintStats;
            end
         else if LWord = 'END' then begin
            Ofs    := -1;
            LChar  := #$00;
            end
         else if LWord = 'ENDGAME' then begin
            G.I.Strength := 0;
            end
         else if LWord = 'IDLE' then begin
            PollFlag := true;
            end
         else if LWord = 'RESTART' then begin
            Ofs      := 0;
            NewLineF := false;
            end
         else if LWord = 'ZAP' then begin
            LGetWord (N,Ofs);
            DestObj := 0;
            while LFindLabel (N,LWord,DestObj,DestOfs,#$0d+':') do begin
               {}
               { Zap from multiple objects, but only 1st occurance in each! }
               {}
               TempPtr := Objs [DestObj].Inside;
               IncP (TempPtr,DestOfs+1);
               char (TempPtr^) := '''';
               end
            end
         else if LWord = 'RESTORE' then begin
            LGetWord (N,Ofs);
            DestObj := 0;
            while LFindLabel (N,LWord,DestObj,DestOfs,#$0d+'''') do begin
               repeat
                  TempPtr := Objs [DestObj].Inside;
                  IncP (TempPtr,DestOfs+1);
                  char (TempPtr^) := ':';
                  DestOfs := LSeek (DestObj,#$0d+''''+LWord+#$0d);
                  until (DestOfs <= 0)
               end;
            end
         else if LWord = 'LOCK' then
            Rate := 1
         else if LWord = 'UNLOCK' then
            Rate := 0
         else if LWord = 'SEND' then begin
            LGetWord (N,Ofs);
            if LSendMsg (N,LWord,false) then begin
               NewLineF := false;
               end
            end
         else if LWord = 'BECOME' then begin
            if LGetKind (N,Ofs,TempCell1) then begin
               DieFlag := true;
               DieCell.Kind  := TempCell1.Kind;
               DieCell.Color := TempCell1.Color;
               end
            else
               LError (N,'Bad #BECOME');
            end
         else if LWord = 'PUT' then begin
            LGetDir (N,Ofs,Dx,Dy);
            if (Dx=0) and (Dy=0) then
               LError (N,'Bad #PUT')
            else begin
               if not LGetKind (N,Ofs,TempCell1) then
                  LError (N,'Bad #PUT')
               else begin
                  if (X+Dx>0) and (X+Dx<=XS) and
                     (Y+Dy>0) and (Y+Dy<Ys) then begin
                     if not Info [Board [X+Dx,Y+Dy].Kind].GoThru then
                        Push (X+Dx,Y+Dy,Dx,Dy);
                     ChangeCell (X+Dx,Y+Dy,TempCell1);
                     end;
                  end;
               end;
            end
         else if LWord = 'CHANGE' then begin
            if not LGetKind (N,Ofs,TempCell1) then
               LError (N, 'Bad #CHANGE');
            if not LGetKind (N,Ofs,TempCell2) then
               LError (N, 'Bad #CHANGE');
            TempX := 0; TempY := 1;
            if (TempCell2.Color=0) and (Info [TempCell2.Kind].Col<$f0) then
               TempCell2.Color := Info [TempCell2.Kind].Col;
            while LocateKind (TempX,TempY,TempCell1) do
               ChangeCell (TempX,TempY,TempCell2);
            end
         else if LWord = 'PLAY' then begin
            TempStr := Music (LGetString (N,Ofs));
            if TempStr <> '' then
               SoundAdd (-1,TempStr);
            NewLineF := false;
            end
         else if LWord = 'CYCLE' then begin
            LGetNum (N,Ofs);
            if LNum>0 then Cycle := LNum;
            end
         else if LWord = 'CHAR' then begin
            LGetNum (N,Ofs);
            if (LNum>0) and (LNum<=255) then begin
               Intel := LNum;
               DrawCell (X,Y);
               end;
            end
         else if LWord = 'DIE' then begin
            DieFlag := true;
            DieCell.Kind  := Empty;
            DieCell.Color := White;
            end
         else if LWord = 'BIND' then begin {**}
            LGetWord (N,Ofs);
            TempInt := 0;
            if LFindObj (N,TempInt,LWord) then begin
               freemem (Inside,InsideLen);
               Inside    := Objs [TempInt].Inside;
               InsideLen := Objs [TempInt].InsideLen;
               Ofs       := 0; {Same as U.Objs [N].Offset}
               end;
            end
         else begin
            TempStr := LWord;
            if LSendMsg (N,LWord,false) then
               NewLineF := false
            else if pos (':',TempStr) <= 0 then
               LError (N,'Bad command '+TempStr);
            end;
         {}
         if NewLineF then
            LNewLine (N,Ofs);
         end
      else if (LChar = #$0d) then begin
         if S.NumLines>0 then
            AddScrollLine (S,'');
         end
      else if LChar = #$00 then
         GotEnd := true
      else begin
         TempStr := LChar + LGetString (N,Ofs);
         AddScrollLine (S,TempStr);
         end;
      until GotEnd or PollFlag or Redo or DieFlag or (CmdsExec>32);
   {}
   if Redo then
      Ofs := StartOfs;
   {}
   if LChar = #$00 then
      Ofs := -1;
   {}
   if S.NumLines > 1 then begin
      NewOfs := 0;
      LGetChar (N,NewOfs);
      if LChar = '@' then
         M := LGetString (N,NewOfs);
      if M='' then
         M := 'Interaction';
      S.Title := M;
      OpenScroll (S);
      ViewScroll (S,true,false);
      CloseScroll;
      EmptyScroll (S);
      if S.Cmd <> '' then begin
         if LSendMsg (N,S.Cmd,false) then
            goto Restart;
         end;
      end
   else if S.Numlines = 1 then begin
      PutBotMsg (200,S.Line [1]^);
      EmptyScroll (S);
      end;
   if DieFlag then begin
      TempX := X; TempY := Y;
      ZapObj (N);
      ChangeCell (TempX, TempY, DieCell);
      end;
   end; end;

begin
   end.
