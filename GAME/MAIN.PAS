{$I-}

unit Main;

interface

uses
   FastWr, Crt, Dos, Keyboard, SoundU,
   GameCtrl,
   Scrolls,
   Glob;

procedure ClearLine (C:integer);
procedure ClearText;
procedure InitSplotch;
procedure IncP (var P:pointer; N:integer);
procedure ArcRoomx;
procedure UnarcRoomx (N:integer);
procedure SwitchRooms (N:integer);
procedure InitU;
procedure InitGame;
procedure Cls (Ch:char; Color:integer);
procedure DrawCell (X,Y:integer);
procedure DrawBox;
procedure DrawBoard;
procedure InChar (InFlag:boolean; X,Y:integer; M:OurString; var N:Byte);
procedure InNum  (InFlag:boolean; X,Y:integer; M:string; var N:byte);
procedure InChoice (InFlag:boolean; Y:integer; M,Choices:string; var N:Byte);
procedure InDir (InFlag:boolean; Y:integer; M:string; var Xd,Yd:integer);
procedure InString (X,Y,Color,InColor,L:integer; InputKind:InputType;
                   var S:OurString);
function  InYN (M:string; Def:boolean):boolean;
procedure InName (M:string; Ext:OurString; var S:OurString;
                 IType: InputType);
procedure ErrDelay;
function  CheckErr:boolean;
procedure NewGame;
function  LoadGame (Name,Ext:OurString; FirstFlag:boolean):boolean;
procedure SaveGame (Name,Ext:OurString);
procedure DoSave (Msg:OurString; var Name:OurString; Ext:OurString);
function  WorldMenu (Ext:OurString):boolean;
procedure GetScrollText (N:integer; var S:ScrollType);
procedure AddObj (Xc,Yc:integer; KindC:byte; ColorC:integer;
                 CycleC:integer; Prototype:ObjType);
procedure KillObj (N:integer);
function  ObjAt (Xc,Yc:integer):integer;
function  FreeCell (Xc,Yc:integer):boolean;
procedure MoveObj (Nc,Xc,Yc:integer);
procedure InFancy (M:String; var S:OurString);
function  SignF (I:integer):integer;
function  DistF (A,B:integer):integer;
procedure PrintStats;
procedure PutBotMsg (T:integer; S:String);
procedure ZapObj (Obj:integer);
procedure Zap (X,Y:integer);
procedure ZapWith (Obj,X,Y:integer);
function  TryFire (KindC:byte; X,Y,Dx,Dy,Who:integer):boolean;
procedure PickRandomDir (var Xd, Yd:integer);
procedure SeekPlayer (X,Y:integer; var Xd,Yd:integer);
procedure PDrawBoard;
procedure NoteEnterNewRoom;
procedure EnterPassage (Xc,Yc:integer);
procedure SecretCmd;
procedure About;
procedure PlayGame (DoDraw:boolean);
procedure Menu;
procedure AnnoyView;


implementation

uses
   Obj, Lang, Edit;

{}
{}
{}
{  Now finally - some routines!  }
{}
{}
{}


procedure ClearLine (C:integer);
begin
   Fastwrite (60,c,$11,Spaces);
   end;

procedure ClearText; {Clear text area of screen}
var
   C:integer;
begin
   for C := 3 to 24 do ClearLine (C);
   end;

{}
{ Initialize the table of screen coordinates randomly }
{}
procedure InitSplotch;
var
   Xc,Yc:integer;
   TempC:Coord;
begin
   XYs := 0;
   for Yc := 1 to Ys do begin  {Put coordinates in order}
      for Xc := 1 to Xs do begin
         XYs := XYs + 1;
         Splotch [XYs].X := Xc;
         Splotch [XYs].Y := Yc;
         end;
      end;
   for Xc := 1 to XYs do begin  {Shuffle coordinates randomly}
      Yc := Random (XYs)+1;
      TempC        := Splotch [Yc];
      Splotch [Yc] := Splotch [Xc];
      Splotch [Xc] := TempC;
      end;
   end;

{}
{ Add N to the address of pointer P }
{}
procedure IncP (var P:pointer; N:integer);
begin
   P := Ptr (Seg (P^), Ofs (P^)+N);
   end;

{}
{ Move contents of current board (U) into storage in memory (to board N)}
{}
procedure ArcRoomx;
var
   Xc, Yc:       integer;
   Point:        pointer;
   RLE:          RLEcelltype;
label
   SkipBound;
begin with U do begin
   Point := TempHeap;
   {}
   Move (Title, Point^, SizeOf (Title));
   IncP (Point, SizeOf (Title));
   {}
   { Save board characters & color using run-length encoding. }
   {}
   Xc := 1; Yc := 1;
   RLE.len  := 1;
   RLE.cell := Board [Xc,Yc];
   repeat
      Xc := Xc + 1;
      if Xc > Xs then begin
         Xc := 1;
         Yc := Yc + 1;
         end;
      {}
      if (Board [Xc,Yc].Color = RLE.cell.Color) and
         (Board [Xc,Yc].Kind  = RLE.cell.Kind)  and
         (RLE.len < 255) and (Yc<=Ys) then
         RLE.len := RLE.len + 1
      else begin
         Move (RLE, Point^, SizeOf (RLE));
         IncP (Point, SizeOf (RLE));
         RLE.Cell := Board [Xc,Yc];
         RLE.Len  := 1;
         end;
      until (Yc > Ys);
   {}
   Move (RoomInfo, Point^, SizeOf (RoomInfo));
   IncP (Point, SizeOf (RoomInfo));
   {}
   Move (NumObjs, Point^, SizeOf (NumObjs));
   IncP (Point, SizeOf (NumObjs));
   {}
   {}
   for Xc := 0 to NumObjs do with Objs [Xc] do begin
      if InsideLen > 0 then begin {**} {For BOUND objects}
         for Yc := 1 to Xc-1 do begin
            if Inside=Objs [Yc].Inside then
               InsideLen := -Yc;
            end;
         end;
      Move (Objs [Xc], Point^, SizeOf (Objs [Xc]));
      IncP (Point, SizeOf (Objs[Xc]));
      if InsideLen > 0 then begin
         Move (Inside^, Point^, InsideLen);
         Freemem (Inside, InsideLen); {!!}
         IncP (Point, InsideLen);
         {} SkipBound:
         end;
      end;
   {}
   { Now move TempHeap into storage for this room. }
   {}
   FreeMem  (G.RoomPtr [G.I.Room],G.RoomSize [G.I.Room]);
   G.RoomSize [G.I.Room] := Ofs (Point^)-Ofs(TempHeap^);
   GetMem          (G.RoomPtr [G.I.Room], G.RoomSize [G.I.Room]);
   Move (TempHeap^, G.RoomPtr [G.I.Room]^,G.RoomSize [G.I.Room]);
   end; end;

{}
{ Retrieve board (U) from memory }
{}
procedure UnarcRoomx (N:integer);
var
   Point:        pointer;
   Xc, Yc:       integer;
   RLE:          RLEcelltype;
begin with U do begin
   if N>G.NumRooms then
      N := G.I.Room;
   {}
   Point := G.RoomPtr [N];
   {}
   Move (Point^,Title, SizeOf (Title));
   IncP (Point, SizeOf (Title));
   {}
   { Retrieve board characters & color with run-length encoding. }
   {}
   Xc := 1; Yc := 1;
   RLE.Len := 0;
   repeat
      if RLE.Len <= 0 then begin
         Move (Point^, RLE, Sizeof (RLE));
         IncP (Point, SizeOf (RLE));
         end;
      Board [Xc,Yc] := RLE.Cell;
      Xc := Xc + 1;
      if Xc > Xs then begin
         Xc := 1;
         Yc := Yc + 1;
         end;
      RLE.Len := RLE.Len - 1;
      {}
      until (Yc > Ys);
   {}
   Move (Point^,RoomInfo, SizeOf (RoomInfo));
   IncP (Point, SizeOf (RoomInfo));
   {}
   Move (Point^,NumObjs, SizeOf (NumObjs));
   IncP (Point, SizeOf (NumObjs));
   {}
   for Xc := 0 to NumObjs do with Objs [Xc] do begin
      Move (Point^, Objs [Xc], SizeOf (Objs [Xc]));
      IncP (Point, SizeOf (Objs [Xc]));
      if InsideLen > 0 then begin
         GetMem (Inside, InsideLen);
         Move (Point^, Inside^, InsideLen);
         IncP (Point, InsideLen);
         end
      else if InsideLen < 0 then begin {**} {For BOUND objects}
         Inside    := Objs [-InsideLen].Inside;
         InsideLen := Objs [-InsideLen].InsideLen;
         end;
      end;
   G.I.Room := N;
   {}
   end; end;

procedure SwitchRooms (N:integer);
begin with U,Objs[0] do begin
   Board [X,Y].Kind := Player;
   Board [X,Y].Color := Info [Player].Col;
   ArcRoomx;
   UnarcRoomx (N);
   end; end;

procedure InitU;
var
   Xc, Yc: integer;
   C:      integer;
begin with G do begin
   with U do begin
      Title  := '';
      with RoomInfo do begin
         BotMsg   := '';
         CanShoot := 255;
         IsDark   := false;
         ReEnter  := false;
         TimeLimit:= 0;
         for C := 0 to 3 do
            RoomUDLR [C] := 0;
         end;
      {}
      for Xc := 0 to Xs+1 do begin {Null out unseen screen border}
         Board [Xc,0   ] := Boundary;
         Board [Xc,Ys+1] := Boundary;
         end;
      for Yc := 0 to Ys+1 do begin
         Board [0   ,Yc] := Boundary;
         Board [Xs+1,Yc] := Boundary;
         end;
      {}
      for Xc := 1 to Xs do {Null out inside of board}
         for Yc := 1 to Ys do begin
            Board [Xc,Yc].Kind  := Empty;
            Board [Xc,Yc].Color := 0;
            end;
      {}
      for Xc := 1 to Xs do begin {fill in shown boundaries}
         Board [Xc,1 ] := Border;
         Board [Xc,Ys] := Border;
         end;
      for Yc := 1 to Ys do begin
         Board [1 ,Yc] := Border;
         Board [Xs,Yc] := Border;
         end;
      {}
      with Board [Xs div 2, Ys div 2] do begin
         Kind  := Player;
         Color := Info [Player].Col;
         end;
      NumObjs        := 0;
      Objs [0].X     := Xs div 2;
      Objs [0].Y     := Ys div 2;
      Objs [0].Cycle := 1;
      Objs [0].Under.Kind  := Empty;
      Objs [0].Under.Color := $00;
      Objs [0].Inside      := nil;
      Objs [0].InsideLen   := 0;
      end;
   end; end;

procedure InitGame;
var
   N:integer;
begin with G do begin
   InitInfoPlay;
   NumRooms     := 0;
   RoomSize [0] := 0;
   InitDef;
   InitFirst;
   InitU;
   {}
   { Initialize player's inventory }
   {}
   with I do begin
      PlayFlag  := false;
      Room      := 0;
      Ammo      := 0;
      Gems      := 0;
      Strength  := 100;
      EnerTime  := 0;
      Torches   := 0;
      TorchTime := 0;
      Score     := 0;
      RoomTime  := 0;
      LastSec   := 0;
      for N := 1 to 7 do
         Keys [N] := false;
      for N := 1 to NumFlags do begin
         Flags [N] := '';
         end;
      end;
   SwitchRooms (0);
   {}
   U.Title  := 'Title screen';
   GameName := '';
   G.I.OrigName := '';
   end; end;

{}
{ Clear the screen with specified attribute and color }
{}
procedure Cls (Ch:char; Color:integer);
var
   C:integer;
begin
   for C := 1 to XYs do begin
      Fastwrite (Splotch [C].X-1,Splotch [C].Y-1,Color,Ch);
      end;
   end;

{$F+}
{}
{ Draw one cell of the board }
{}
procedure DrawCell (X,Y:integer);
var
   C:Char;
begin with U.Board [X,Y] do begin
   if (not U.RoomInfo.IsDark) or
      (Info [U.Board [X,Y].Kind].ShowInDark) or
      ((G.I.TorchTime > 0) and
         ((sqr(U.Objs [0].x-x)+2*sqr(U.Objs[0].y-y))<TorchSize)) or
      (EdFlag) then begin
      {}
      if Kind = Empty then
         fastwrite (X-1,Y-1,$0f,' ')
      else if Info [Kind].PrintF then begin
         Info [Kind].Print (X,Y,C);
         fastwrite (X-1,Y-1,Color,C);
         end
      else if (Kind < TextCol) then
         fastwrite (X-1,Y-1,Color,Info [Kind].Ch)
      else begin
         if Kind=(TextCol+NumTextCols) then
            fastwrite (X-1,Y-1,$0f,chr (U.Board [X,Y].Color))
         else begin
            if MonoFlag then
               fastwrite (X-1,Y-1,(Kind-TextCol+1)*$10,
                  chr (U.Board [X,Y].Color))
            else
               fastwrite (X-1,Y-1,(Kind-TextCol+1)*$10+$0f,
                  chr (U.Board [X,Y].Color));
            end;
         end;
      end
   else begin {Is dark}
      fastwrite (X-1,Y-1,$07,#$b0);
      end;
   end; end;
{$F-}

procedure DrawBox; {Draws box outlining board}
var
   Xc, Yc:integer;
begin
   for Xc := 1 to Xs do begin
      DrawCell (Xc,1);
      DrawCell (Xc,Ys);
      end;
   for Yc := 1 to Ys do begin
      DrawCell (1,Yc);
      DrawCell (Xs,Yc);
      end;
   end;

procedure DrawBoard; {Draw the playing board, as defined in Board array }
var
   C: integer;
begin
   DrawBox;
   for C := 1 to XYs do begin
      with Splotch [C] do DrawCell (X,Y);
      end;
   end;

{}
{ Input an ascii character }
{}
procedure InChar (InFlag:boolean; X,Y:integer; M:OurString; var N:byte);
var
   C:    integer;
   NewN: integer;
begin
   clearline (Y);
   fastwrite (X,Y,$1e+integer(InFlag),M);
   clearline (Y+1);
   fastwrite (X+5,Y+1,$9f,#$1f);
   clearline (Y+2);
   repeat
      for C := N-4 to N+4 do
         fastwrite (X+C-N+5,Y+2,$1e,chr((C+$100)mod $100));
      if InFlag then begin
         Delay (25);
         CheckCtrl;
         if (Key=Tab) then Dx1 := 9;
         NewN := N+Dx1;
         if (NewN<>N) then begin
            N := (NewN+$100) mod $100;
            ClearLine (Y+2);
            end;
         end
      until (Key=Return) or (Key=Escape) or (not InFlag) or (Fire1);
   fastwrite (X+5,Y+1,$1f,#$1f);
   end;

{}
{ Input a value from 1 to 10 }
{}
procedure InNum (InFlag: boolean; X,Y:integer; M:string; var N:byte);
var
   NewN:    integer;
   Ch1,Ch2: char;
begin
   if M [length(M)-2]=';' then begin
      Ch1 := M [length(M)-1];
      Ch2 := M [length(M)];
      M := copy (M,1,length (M)-3);
      end
   else begin
      Ch1 := '1';
      Ch2 := '9';
      end;
   clearline (Y);
   fastwrite (X,Y,$1e+integer(InFlag),M);
   clearline (Y+1);
   clearline (Y+2);
   fastwrite (X,Y+2,$1e,Ch1+'....:....'+Ch2);
   repeat
      if InFlag then begin
         if Flow1 then
            delay (45);
         fastwrite (X+N+1,Y+1,$9f,#$1f);
         CheckCtrl;
         if (Key>='1') and (Key<='9') then begin
            N := ord (Key)-ord('1');
            ClearLine (Y+1);
            end
         else begin
            NewN := N+Dx1;
            if (NewN<>N) and (NewN>=0) and (NewN<=8) then begin
               N := NewN;
               ClearLine (Y+1);
               end;
            end;
         end;
      until (Key=Return) or (Key=Escape) or (not InFlag) or (Fire1);
   fastwrite (X+N+1,Y+1,$1f,#$1f);
   end;

{}
{ Input an ordinal choice }
{}
procedure InChoice (InFlag: boolean; Y:integer;
   M, Choices: string; var N:byte);
var
   Count, Spaces, NumChoices, NewN:integer;
begin
   clearline (Y);
   clearline (Y+1);
   clearline (Y+2);
   fastwrite (63,Y,$1e+integer(InFlag),M);
   fastwrite (63,Y+2,$1e,Choices);
   NumChoices := 1;
   for Count := 1 to length (Choices) do
      if Choices [Count] = ' ' then
         NumChoices := NumChoices + 1;
   repeat
      Spaces := 0;
      Count  := 1;
      while (Spaces < N) and (Count < length (Choices)) do begin
         if Choices [Count] = ' ' then
            Spaces := Spaces + 1;
         Count := Count + 1;
         end;
      if InFlag then begin
         fastwrite (62+Count,Y+1,$9f,#$1f);
         Delay (35);
         CheckCtrl;
         NewN := N+Dx1;
         if (NewN<>N) and (NewN>=0) and (NewN<=(NumChoices-1)) then begin
            N := NewN;
            ClearLine (Y+1);
            end;
         end
      until (Key=Return) or (Key=Escape) or (not InFlag) or (Fire1);
   fastwrite (62+Count,Y+1,$1f,#$1f);
   end;

{}
{ Input a direction - up, down, left, right - to XD,YD }
{}
procedure InDir (InFlag: boolean; Y:integer; M:string; var Xd,Yd:integer);
var
   N:byte;
begin
   if Yd=-1 then
      N := 0
   else if Yd=1 then
      N := 1
   else if Xd=-1 then
      N := 2
   else
      N := 3;
   InChoice (InFlag, Y, M, #$18+' '+#$19+' '+#$1b+' '+#$1a,N);
   Xd := UDLRx [N];
   Yd := UDLRy [N];
   end;

{}
{ Input a string of length L, at (X,Y) }
{}
procedure InString (X,Y,Color,InColor,L:integer; InputKind:InputType;
   var S:OurString);
var
   C:integer;
   OldS:string;
   StartF:boolean;
begin
   OldS := S;
   StartF := true;
   repeat
      for C := 0 to L-1 do begin
         fastwrite (X+C,Y,  InColor,' ');
         fastwrite (X+C,Y-1,  Color,' ');
         end;
      fastwrite (X+L,Y-1,Color,' ');
      fastwrite (X+length(S),Y-1,(Color div $10)*$10+$f,#$1f);
      fastwrite (X,Y,InColor,S);
      GetKey;
      if (length (S)<L) and (Key>=#$20) and (Key<#$80) then begin
         if StartF then
            S := '';
         case InputKind of
            INum:
               if Key in ['0'..'9'] then
                  S := S + Key;
            IStr:
               S := S + Key;
            IFname:
               if (Upcase (Key) in ['A'..'Z']) or
                  (Key in ['0'..'9']) or (Key='-') then
                  S := S + Upcase (Key);
            end;
         end
      else if (Key = LeftK) or (Key=#$08) then
         S := copy (S,1,length (S)-1);
      StartF := false;
      until (Key=Return) or (Key=Escape);
   if Key=Escape then
      S := OldS;
   end;


{}
{ Give message and ask Yes/No }
{}
function InYN (M:string; Def:boolean):boolean;
begin
   Clearline (3);
   clearline (4);
   ClearLine (5);
   fastwrite (63,5,$1f,M);
   fastwrite (63+length(M),5,$9e,'_');
   repeat
      GetKey;
      until UpCase (Key) in ['Y','N',Escape];
   if UpCase (Key)='Y' then
      Def := true
   else
      Def := false;
   ClearLine (5);
   InYN := Def;
   end;

{}
{ Input a something on the screen's bottom line, with a message }
{}
procedure InName (M:string; Ext:OurString; var S:OurString;
   IType:InputType);
begin
   ClearLine (3);
   ClearLine (4);
   ClearLine (5);
   fastwrite (75-length (M),3,$1f,M);
   fastwrite (63,5,$0f,'        '+Ext);
   InString (63,5,$1e,$0f,8,IType,S);
   ClearLine (3);
   ClearLine (4);
   ClearLine (5);
   end;

procedure ErrDelay;
begin
   SoundAdd (1,Music ('s004x114x9'));
   Delay (2000);
   end;

function CheckErr:boolean;
var
   ErrName:OurString;
begin
   if IOResult = 0 then
      CheckErr := false
   else begin
      case IOResult of
         2:   ErrName := 'File not found!';
         3:   ErrName := 'Path not found!';
         101: ErrName := 'Disk full!';
         else ErrName := 'DOS Error!';
         end;
      ClearLine (5);
      fastwrite (63,5,$1f,ErrName);
      ErrDelay;
      CheckErr := true;
      end;
   end;



{}
{ New game G }
{}
procedure NewGame;
var
   C:integer;
begin
   ArcRoomx;
   for C := 0 to G.NumRooms do begin
      FreeMem (G.RoomPtr [C],G.RoomSize [C]);
      end;
   end;

{}
{}
{ Load entire game (G) }
{}
function LoadGame (Name,Ext:OurString; FirstFlag:boolean):boolean;
const
   AnimC: array [0..7] of byte =
      ($14,$1c,$15,$1d,$16,$1e,$17,$1f);
   AnimS: array [0..7] of string [5] =
      ('....|','...*/','..*.-','.*..\',
       '*...|','..../','....-','....\');
var
   F:     file;
   Point: pointer;
   C:     integer;
   Anim:  integer;
   {}
   procedure Animate;
   begin
      fastwrite (69,5,AnimC[Anim],AnimS[Anim]);
      Anim := (Anim+1) mod 8;
      end;
begin
   LoadGame := false;
   {}
   Anim := 0;
   ClearLine (4);
   ClearLine (5);
   ClearLine (5);
   fastwrite (62,5,$1f,'Loading.....');
   {}
   assign (F,Name+Ext);
   reset (F,1);
   if CheckErr then exit;
   {}
   NewGame;
   {}
   BlockRead (F, TempHeap^, HeaderLen);
   if CheckErr then exit;
   {}
   Point := TempHeap;
   {}
   Move (Point^, G.NumRooms, SizeOf (G.NumRooms));
   IncP (Point, SizeOf (G.NumRooms));
   if G.NumRooms < 0 then begin
      if (G.NumRooms<>-1) then begin {Version mismatch!}
         fastwrite (63,5,$1e,'You need a newer');
         fastwrite (63,6,$1e,' version of ZZT!');
         exit;
         end
      else begin
         Move (Point^, G.NumRooms, SizeOf (G.NumRooms));
         IncP (Point, SizeOf (G.NumRooms));
         end;
      end;
   {}
   Move (Point^, G.I, SizeOf (G.I));
   IncP (Point, SizeOf (G.I));
   {}
   if FirstFlag then begin
      G.NumRooms   := 0;
      G.I.Room     := 0;
      G.I.PlayFlag := true;
      end;
   {}
   for C := 0 to G.NumRooms do begin
      Animate;
      BlockRead (F, G.RoomSize [C], SizeOf (G.RoomSize [C]));
      GetMem (G.RoomPtr [C], G.RoomSize [C]);
      BlockRead (F, G.RoomPtr [C]^, G.RoomSize [C]);
      end;
   {}
   close (F);
   UnarcRoomx (G.I.Room);
   GameName := Name;
   LoadGame := true;
   LoadHi;
   {}
   ClearLine (5);
   {}
   end;

{}
{ Save the entire game G with file Name & Ext}
{}
procedure SaveGame (Name,Ext:OurString);
var
   F:         file;
   C, Size:   integer;
   Point:     pointer;
   VersionInt:integer;
begin
   ArcRoomx;
   {}
   fastwrite (63,5,$1f,'Saving...');
   {}
   assign (F,Name+Ext);
   rewrite (F,1);
   if CheckErr then exit;
   {}
   Point := TempHeap;
   {}
   FillChar (TempHeap^,HeaderLen,#0); {Zero header}
   {}
   VersionInt := -1;
   Move (VersionInt,Point^,SizeOf (VersionInt));
   IncP (Point, SizeOf (VersionInt));
   {}
   Move (G.NumRooms, Point^, SizeOf (G.NumRooms));
   IncP (Point, SizeOf (G.NumRooms));
   {}
   Move (G.I, Point^, SizeOf (G.I));
   IncP (Point, SizeOf (G.I));
   {}
   BlockWrite (F, TempHeap^, HeaderLen); {Fixed length}
   if CheckErr then exit;
   {}
   for C := 0 to G.NumRooms do begin
      BlockWrite (F, G.RoomSize [C],  SizeOf (G.RoomSize [C]));
      if CheckErr then exit;
      BlockWrite (F, G.RoomPtr  [C]^, G.RoomSize [C]);
      if CheckErr then exit;
      end;
   close (F);
   UnarcRoomx (G.I.Room);
   {}
   ClearLine (5);
   end;

{}
{ Prompted Save }
{}
procedure DoSave (Msg:OurString; var Name:OurString; Ext:OurString);
var
   S:OurString;
begin
   S := Name;
   InName (Msg,Ext,S,IFname);
   if (Key<>Escape) and (S <> '') then begin
      Name := S;
      if Ext = WorldExt then
         G.I.OrigName := Name;
      SaveGame (Name,Ext);
      end;
   end;

{}
{ Menu of *.ZZT Files }
{}
function WorldMenu (Ext:OurString):boolean;
var
   Files: ScrollType;
   S:     searchrec;
   Str:   string;
   C:     integer;
begin with Files do begin
   InitScroll (Files);
   if Ext = WorldExt then
      Title := 'ZZT Worlds'
   else
      Title := 'Saved Games';
   WorldMenu:= false;
   PickFlag := true;
   findfirst ('*'+Ext,AnyFile,S);
   while DosError=0 do begin
      Str := copy (S.Name,1,length (S.Name)-4);
      for C:=1 to Wnum do begin
         if Str=Wname[c] then Str := Wdescr[c];
         end;
      AddScrollLine (Files,Str);
      findnext (S);
      end;
   {}
   AddScrollLine (Files,'Exit');
   {}
   OpenScroll (Files);
   ViewScroll (Files,false,false);
   CloseScroll;
   if (Cur < NumLines) and (not Abort) then begin
      Str := Line [Cur]^;
      if Pos (' ',Str)<>0 then
         Str := copy (Str,1,Pos (' ',Str)-1);
      WorldMenu := LoadGame (Str,Ext,false);
      cls (#$db,$44);
      end;
   {}
   EmptyScroll (Files);
   end; end;

{}
{ Get scroll text that is stored in an object }
{}
procedure GetScrollText (N:integer; var S:ScrollType);
var
   TempStr: string;
   TempPtr: pointer;
   TempChr: char;
   C:       integer;
begin with U,Objs [N] do begin
   InitScroll (S);
   TempStr := '';
   TempPtr := Inside;
   for C := 0 to InsideLen do begin
      Move (TempPtr^,TempChr,1);
      if TempChr = #$0d then begin
         AddScrollLine (S,TempStr);
         TempStr := '';
         end
      else
         TempStr := TempStr + TempChr;
      IncP (TempPtr,1);
      end;
   end; end;

procedure AddObj (Xc,Yc:integer; Kindc:byte; Colorc:integer; Cyclec:integer;
   Prototype:ObjType);
begin with U do begin
   if NumObjs < MaxObjs then begin
      NumObjs := NumObjs + 1;
      Objs [NumObjs] := Prototype;   {Set intrinsic properties}
      with Objs [NumObjs] do begin   {Set extrinsic properties}
         X      := Xc;
         Y      := Yc;
         Cycle  := Cyclec;
         Under  := Board [Xc,Yc];
         Offset := 0;
         end;
      if Prototype.Inside <> nil then begin {Clone scroll text}
         Getmem (Objs [NumObjs].Inside,Prototype.InsideLen);
         move (Prototype.Inside^,Objs [NumObjs].Inside^,
            Prototype.InsideLen);
         end;
      if Info [Board [Xc,Yc].Kind].Terrain then
         Board [Xc,Yc].Color := (ColorC and $0f) +
            (Board [Xc,Yc].Color and $70)
      else
         Board [Xc,Yc].Color := ColorC;
      Board [Xc,Yc].Kind := KindC;
      if Yc>0 then
         DrawCell (Xc,Yc);
      end;
   end; end;

{}
{ Kill an object and move all other objects back. }
{}
procedure KillObj (N:integer);
var
   C:       integer;
label
   SkipFree;
begin with U,Objs[N] do begin
   {}
   if InsideLen <> 0 then begin
      for C := 1 to NumObjs do begin
         if (Objs[C].Inside=Inside) and (C<>N) then {**} {BOUND object!}
            goto SkipFree;
         end;
      freemem (Inside,InsideLen);
      {} SkipFree:
      end;
   {}
   if N < ObjNum then
      ObjNum := ObjNum - 1;
   {}
   Board    [X,Y] := Under;
   if Y>0 then
      DrawCell (X,Y);
   {}
   for C := 1 to NumObjs do begin  {Re-order pointers to other objects}
      if Objs [C].Child >= N then begin
         if Objs [C].Child = N then begin
            Objs [C].Child := -1;
            end
         else
            Objs [C].Child := Objs [C].Child - 1;
         end;
      if Objs [C].Parent >= N then begin
         if Objs [C].Parent = N then begin
            Objs [C].Parent := -1;
            end
         else
            Objs [C].Parent := Objs [C].Parent - 1;
         end;
      end;
   {}
   for C := N+1 to NumObjs do
      Objs [C-1] := Objs [C];
   NumObjs := NumObjs-1;
   end; end;

{}
{ Returns # of object at X,Y, or -1 if none is there }
{}
function ObjAt (Xc,Yc:integer):integer;
var
   N:integer;
begin with U do begin
   N := -1; {See if player is there too}
   repeat
      N := N + 1;
      until ((Objs[N].X=Xc) and (Objs[N].Y=Yc)) or (N>NumObjs);
   if N>NumObjs then
      ObjAt := -1
   else
      ObjAt := N;
   end; end;

{}
{ If an object is at this position, remove it }
{ Returns false if object can't be removed (player) }
{}
function FreeCell (Xc,Yc:integer):boolean;
var
   C:integer;
   R:boolean;
begin with U do begin
   C := ObjAt (Xc,Yc);
   if C>0 then begin
      KillObj (C);
      R := true;
      end
   else if C<0 then begin
      if not Info [Board [Xc,Yc].Kind].Terrain then begin
         Board [Xc,Yc].Kind := Empty;
         end;
      R := true;
      end
   else  {C = 0, player}
      R := false;
   DrawCell (Xc,Yc);
   FreeCell := R;
   end; end;

{}
{ Move object #Nc to new coordinates (Xc,Yc) }
{ DOES NOT check to see if board at Xc,Yc is free or not! }
{}
procedure MoveObj (Nc,Xc,Yc:integer);
var
   OldUnder:     BoardCell;
   TempX, TempY: integer;
   OldX,  OldY:  integer;
   OldAttr:      integer;
begin with U,Objs [Nc] do begin
   {}
   OldAttr            := Board [Xc,Yc].Color and $f0;
   OldUnder           := Objs [Nc].Under;
   Objs [Nc].Under    := Board [Xc, Yc];
   {}
   if (Board [X,Y].Kind=Player) then
      Board [Xc,Yc].Color := Board [X,Y].Color
   else if Board [Xc,Yc].Kind = Empty then
      Board [Xc,Yc].Color := Board [X,Y].Color and $0f
   else
      {Assume terrain's background color}
      Board [Xc,Yc].Color:= (Board [X ,Y ].Color and $0f)+
         (Board [Xc,Yc].Color and $70);
   Board [Xc,Yc].Kind := Board [X,Y].Kind;
   Board [X, Y ]      := OldUnder;
   {}
   OldX := X;  OldY := Y;
   X    := Xc; Y    := Yc;
   {}
   DrawCell (X, Y);
   DrawCell (OldX, OldY);
   {}
   if (Nc=0) and (RoomInfo.IsDark) and (G.I.TorchTime > 0) then begin
      if (Sqr (OldX-X)+Sqr(OldY-Y))=1 then begin
        for TempX := X-TorchXs-3 to X + TorchXs+3 do begin
         if (TempX>=1) and (TempX<=Xs) then begin
            for TempY := Y-TorchYs-3 to Y+TorchYs+3 do begin
               if (TempY>=1) and (TempY<=Ys) then begin
                  if (((sqr(TempX-OldX)+2*sqr(TempY-OldY)) <TorchSize)) xor
                     (((sqr(TempX-Xc  )+2*sqr(TempY-Yc  )) <TorchSize)) then
                     DrawCell (TempX,TempY);
                  end;
               end;
            end;
         end;
        end
      else begin
         DoArea (OldX,OldY,0);
         DoArea (X,Y,0);
         end;
      end;
   end; end;


procedure InFancy (M:string; var S:OurString);
var
   X,Y:integer;
begin
   fastwrite (3,18,$4f,ScrollTop);
   fastwrite (3,19,$4f,ScrollMid);
   fastwrite (3,20,$4f,ScrollDiv);
   fastwrite (3,21,$4f,ScrollMid);
   fastwrite (3,22,$4f,ScrollMid);
   fastwrite (3,23,$4f,ScrollBot);
   {}
   fastwrite (4+(ScrollXl-length (M)) div 2,19,$4f,M);
   S := '';
   InString (10,22,$4f,$4e,ScrollXl-16,IStr,S);
   {}
   for Y := 18 to 23 do
      for X := 3 to 3+ScrollXl do
         DrawCell (X+1,Y+1);
   end;

procedure AddRoom;
begin
   if G.NumRooms < MaxRooms then begin
      ArcRoomx;
      G.NumRooms := G.NumRooms + 1;
      G.I.Room   := G.NumRooms;
      G.RoomSize [G.NumRooms] := 0;
      InitU;
      DrawBoard;
      repeat
         InFancy ('Room''s Title:',U.Title);
         until U.Title <> '';
      DrawBoard;
      end;
   end;

{}
{ Actual game-play section }
{}

function SignF (I:integer):integer;
{}
{ Returns -1 if I<0, 0 if I=0, 1 if I>0 }
{}
begin
   if I>0 then
      SignF := 1
   else if I<0 then
      SignF := -1
   else
      SignF := 0;
   end;

function DistF (A,B:Integer):integer;
{}
{ Returns absolute value of distance from A to B }
{}
begin
   if (A-B) >= 0 then
      DistF := A-B
   else
      DistF := B-A;
   end;

procedure PrintStats;
   var
      S:string[8];
      C:integer;
   begin
      if (PlayMode=Player) then begin with G,I do begin
         if U.RoomInfo.TimeLimit>0 then begin
            fastwrite (64,6,$1e,'   Time:');
            Str (U.RoomInfo.TimeLimit-RoomTime,S);
            fastwrite (72,6,$1e,S+' ');
            end
         else
            Clearline (6);
         {}
         if Strength < 0 then
            Strength := 0;
         {}
         Str (Strength,S);
         fastwrite (72,7, $1e, S+' ');
         {}
         Str (Ammo,S);
         fastwrite (72,8, $1e, S+'  ');
         {}
         Str (Torches,S);
         fastwrite (72,9, $1e, S+' ');
         {}
         Str (Gems,S);
         fastwrite (72,10,$1e, S+' ');
         {}
         Str (Score,S);
         fastwrite (72,11,$1e, S+' ');
         {}
         if TorchTime=0 then
            fastwrite (75,9,$16,'    ')
         else begin
            for C := 2 to 5 do
               if (TorchTime*5) div TorchLife >= C then
                  fastwrite (73+c,9,$16,#$b1)
               else
                  fastwrite (73+c,9,$16,#$b0);
            end;
         {}
         for C := 1 to 7 do
            if Keys [C] then
               fastwrite (71+C,12,$18+C,Info [AKey].Ch)
            else
               fastwrite (71+C,12,$1f,' ');
         {}
         if SoundF then
            fastwrite (65,15,$1f,' Be quiet')
         else
            fastwrite (65,15,$1f,' Be noisy');
         {}
         if Debug then begin
            Str (Memavail,S);
            fastwrite (69,4,$1e, 'm'+S+' ');
            end;
         {}
         end; end;
      end;

{}
{ PutBotMsg: Put a string message flashing on the screen's bottom }
{            for a specified # of hundredth seconds }
{}
procedure PutBotMsg (T:integer; S:String);
   begin with U do begin
      if ObjAt (0,0) <> -1 then begin
         KillObj (ObjAt (0,0));
         DrawBox;
         end;
      if S<>'' then begin
         AddObj (0,0,Special,0,1,NormObj);
         Objs [NumObjs].Rate := T div (GameCycle+1);
         RoomInfo.BotMsg := S;
         {UpdSpecial (NumObjs);}
         end;
      end; end;

{}
{ Zap object N - must be zappable & object - either player, enemy. }
{}
procedure ZapObj (Obj:integer);
var
   OldX,OldY:integer;
begin with U,Objs [Obj] do begin
   if Obj = 0 then begin
      if G.I.Strength > 0 then begin {Not already dead}
         G.I.Strength := G.I.Strength - 10;
         PrintStats;
         PutBotMsg (100,'Ouch!');
         Board [X,Y].Color := Info [Player].Col mod $10+$70;
         {Colorfully zap player}
         if G.I.Strength >0 then begin
            G.I.RoomTime := 0;
            if RoomInfo.ReEnter then begin
               {Re-Enter player 0 into room}
               SoundAdd (4,#$20+#1+#$23+#1+#$27+#1+#$30+#1+#$10+#1);
               Board [X,Y].Kind := Empty;
               DrawCell (X,Y);
               OldX := X; OldY := Y;
               X       := RoomInfo.StartX;
               Y       := RoomInfo.StartY;
               DoArea (OldX,OldY,0);
               DoArea (X,Y,0);
               StandBy := true;
               end;
            SoundAdd (4,#$10+#1+#$20+#1+#$13+#1+#$23+#1)
            end
         else
            SoundAdd (5,#$20+#3+#$23+#3+#$27+#3+#$30+#3+
                        #$27+#3+#$2a+#3+#$32+#3+#$37+#3+
                        #$35+#3+#$38+#3+#$40+#3+#$45+#3+#$10+#10);
         end
      end
   else begin
      case Board [X,Y].Kind of
         Bullet:
            SoundAdd (3,#$20+#1);
         Prog:
            begin end;
         else
            SoundAdd (3,#$40+#1+#$10+#1+#$50+#1+#$30+#1);
         end;
      KillObj (Obj);
      end;
   end; end;

{}
{ Procedure to zap whatever is at (X,Y) - it better be zapable! }
{ i.e. enemy, player, breakable wall }
{}
procedure Zap (X,Y:integer);
var
   Obj:integer;
begin
   Obj := ObjAt (X,Y); {if there is an object there}
   if Obj <> -1 then begin
      ZapObj (Obj);
      end
   else begin
      U.Board [X,Y].Kind := Empty;
      DrawCell (X,Y);
      end;
   end;

{}
{ Zap whatever is at X,Y with object N - zap both! }
{}
procedure ZapWith (Obj,X,Y:integer);
begin with U do begin
   if (Obj=0) and (G.I.EnerTime>0) then begin
      G.I.Score := G.I.Score + Info [U.Board [X,Y].Kind].Score;
      PrintStats;
      end
   else
      ZapObj (Obj);
   if (Obj>0) and (Obj <= ObjNum) then
      ObjNum := ObjNum - 1;
   if (U.Board [X,Y].Kind=Player) and (G.I.EnerTime>0) then begin
      G.I.Score := G.I.Score + Info [U.Board [Objs [Obj].X,
         Objs [Obj].Y].Kind].Score;
      PrintStats;
      end
   else begin
      Zap (X,Y);
      SoundAdd (2,#$10+#1);
      end;
   end; end;

{}
{ If there is a clear path, fire a bullet from current position }
{}
function TryFire (KindC:byte; X,Y,Dx,Dy,Who:integer):boolean;
{}
{ Intel = 0    fired by player }
{         else fired by enemy  }
{}
begin with U do begin
   if Info [Board [X+Dx,Y+Dy].Kind].GoThru or
      (Board [X+Dx,Y+Dy].Kind=Water) then begin
      AddObj (X+Dx,Y+Dy,KindC,Info [KindC].Col,1,NormObj);
      with Objs [NumObjs] do begin
         Intel := Who;
         Xd    := Dx;
         Yd    := Dy;
         Rate  := 100; {Sufficient!}
         end;
      TryFire := true;
      end
   else if (Board [X+Dx,Y+Dy].Kind=BreakWall) or
      ((Info [Board [X+Dx,Y+Dy].Kind].KillAble) and
      (boolean (Who) = (Board[X+Dx,Y+Dy].Kind=Player)) and
      (G.I.EnerTime <= 0)) then begin
      {}
      Zap (X+Dx,Y+Dy);
      SoundAdd (2,#$10+#1);
      TryFire := true;
      end
   else
      TryFire := false;
   end; end;

{}
{ Pick a random direction - X is weighted twice over Y }
{}
procedure PickRandomDir (var Xd,Yd:integer);
begin
   Xd := random (3)-1; {-1, 0 or 1}
   if Xd=0 then
      Yd := random (2)*2-1 {-1 or 1}
   else
      Yd := 0;
   end;

{}
{ Seek player - point Xd,Yd to player, given X,Y of referance }
{ Picks direction (X,Y) at random if either can be used }
{}
procedure SeekPlayer (X,Y:integer; var Xd,Yd:integer);
begin
   Xd := 0; Yd := 0;
   if (random (2)<1) or (U.Objs [0].y=y) then
      Xd := Signf (U.Objs [0].x-x);
   if Xd = 0 then
      Yd := Signf (U.Objs [0].y-y);
   if G.I.EnerTime>0 then begin {Not always appropriate}
      Xd := -Xd;
      Yd := -Yd;
      end;
   end;

{}
{ Local draw-board procedure }
{}
procedure PDrawBoard;
begin
   Cls (#$Db,$05);
   DrawBoard;
   end;

{}
{ Note when player has moved into a new room - bottom messages, &c }
{}

procedure NoteEnterNewRoom;
begin with U do begin
   RoomInfo.StartX := Objs [0].X;
   RoomInfo.StartY := Objs [0].Y;
   if RoomInfo.IsDark and G.First.EnterDark then begin
      PutBotMsg (200,'Room is dark - you need to light a torch!');
      G.First.EnterDark := false;
      end;
   G.I.RoomTime := 0;
   PrintStats;
   end; end;

{}
{ Attempt to put player thru Passage at (Xc,Yc) }
{}
procedure EnterPassage (Xc,Yc:integer);
var
   OldRoom:      integer;
   PassageColor: byte;
   Tx,Ty:        integer;
   DestX,DestY:  integer;
begin with U do begin
   PassageColor := Board [Xc,Yc].Color;
   OldRoom   := G.I.Room;
   {}
   SwitchRooms (Objs [ObjAt (Xc,Yc)].Room);
   {}
   DestX := 0;
   for Tx := 1 to Xs do begin
      for Ty := 1 to Ys do begin
         if (Board [Tx,Ty].Kind  = Passage) and
            (Board [Tx,Ty].Color = PassageColor) then begin
            DestX := Tx;
            DestY := Ty;
            end;
         end;
      end;
   Board [Objs [0].X,Objs [0].Y].Kind  := Empty;
   Board [Objs [0].X,Objs [0].Y].Color := $00;
   if DestX <> 0 then begin {Put player on passage if there}
      Objs [0].X := DestX;
      Objs [0].Y := DestY;
      end;
   StandBy    := true;
   SoundAdd (4,#$30+#1+#$34+#1+#$37+#1+
               #$31+#1+#$35+#1+#$38+#1+
               #$32+#1+#$36+#1+#$39+#1+
               #$33+#1+#$37+#1+#$3a+#1+
               #$34+#1+#$38+#1+#$40+#1);
   PDrawBoard;
   NoteEnterNewRoom;
   end; end;

procedure SecretCmd;
var
   S:OurString;
   C:integer;
   Flag:boolean;
begin with G,I do begin
   S := '';
   ClearLine (4);
   ClearLine (5);
   InString (63,5,$1e,$0f,11,Istr,S);
   Flag  := true;
   if (S[1]='+') or (S[1]='-') then begin
      if S[1]='-' then Flag := false;
      S := copy (S,2,length (S)-1);
      for C := 1 to length (S) do
         S[C] := upcase (S[C]);
      if Flag=true then
         SetFlag (S)
      else
         ClearFlag (S);
      end;
   if FlagNum ('DEBUG') >= 0 then begin
      if S='health' then Strength := Strength + 50
      else if S='ammo' then Ammo := Ammo + 5
      else if S='keys' then for C := 1 to 7 do Keys[C] := true
      else if S='torches' then Torches := Torches + 3
      else if S='time' then RoomTime := RoomTime - 30
      else if S='gems' then Gems := Gems + 5
      else if S='dark' then begin
         U.RoomInfo.IsDark := Flag;
         DrawBoard;
         end
      else if S='zap' then with U,Objs [0] do begin
         for C := 0 to 3 do begin
           Zap      (X+UDLRx[C],Y+UDLRy[C]);
           Board    [X+UDLRx[C],Y+UDLRy[C]].Kind := Empty;
           DrawCell (X+UDLRx[C],Y+UDLRy[C]);
         end;
      end;
   end;
   SoundAdd (10,#$27+#4);
   clearline (4);
   clearline (5);
   PrintStats;
   end;
 end;

procedure About;
begin
   ViewDoc ('ABOUT.HLP','About ZZT...');
   end;

procedure PlayGame (DoDraw:boolean);
var
   Halt:    boolean;
   BlinkOn: boolean;
   {}
   procedure PrintCmds;
   begin
      ClearText;
      clearline (0);
      clearline (1);
      clearline (2);
      fastwrite (61,0,$1f,'    - - - - -      ');
      fastwrite (62,1,$70,  '      ZZT      ');
      fastwrite (61,2,$1f,'    - - - - -      ');
      {}
      if (PlayMode=Player) then begin
         fastwrite (64,7, $1e, ' Health:');
         fastwrite (64,8, $1e, '   Ammo:');
         fastwrite (64,9, $1e, 'Torches:');
         fastwrite (64,10,$1e, '   Gems:');
         fastwrite (64,11,$1e, '  Score:');
         fastwrite (64,12,$1e, '   Keys:');
         {}
         fastwrite (62,7, $1f,Info [Player].Ch);
         fastwrite (62,8, $1b,Info [Ammo].Ch);
         fastwrite (62,9, $16,Info [Torch].Ch);
         fastwrite (62,10,$1b,Info [Gem].Ch);
         fastwrite (62,12,$1f,Info [AKey].Ch);
         {}
         fastwrite (62,14 ,$70,' T ');
         fastwrite (65,14,$1f,' Torch');
         fastwrite (62,15,$30,' B '); {Sound - be quiet / noisy}
         fastwrite (62,16,$70,' H ');
         fastwrite (65,16,$1f,' Help');
         {}
         fastwrite (67,18,$30,' '+#$18+#$19+#$1a+#$1b+' ');
         fastwrite (72,18,$1f,' Move');
         fastwrite (61,19,$70,' Shift '+#$18+#$19+#$1a+#$1b+' ');
         fastwrite (72,19,$1f,' Shoot');
         {}
         fastwrite (62,21,$70,' S ');
         fastwrite (65,21,$1f,' Save game');
         fastwrite (62,22,$30,' P ');
         fastwrite (65,22,$1f,' Pause');
         fastwrite (62,23,$70,' Q ');
         fastwrite (65,23,$1f,' Quit');
         end
      else if (PlayMode=Monitor) then begin
         InNum (false,66,21,'Game speed:;FS',Speed);
         fastwrite (62,21,$70,' S ');
         {}
         fastwrite (62,7,$30,' W ');
         fastwrite (65,7,$1e,' World:');
         if G.I.OrigName <> '' then
            fastwrite (69,8,$1f,G.I.OrigName)
         else
            fastwrite (69,8,$1f,'Untitled');
         {}
         fastwrite (62,11,$70,' P ');
         fastwrite (65,11,$1f,' Play');
         fastwrite (62,12,$30,' R ');
         fastwrite (65,12,$1e,' Restore game');
         fastwrite (62,13,$70,' Q ');
         fastwrite (65,13,$1e,' Quit');
         {}
         fastwrite (62,16,$30,' A ');
         fastwrite (65,16,$1f,' About ZZT!');
         fastwrite (62,17,$70,' H ');
         fastwrite (65,17,$1e,' High Scores');
         if RegEdit then begin
            fastwrite (62,18,$30,' E ');
            fastwrite (65,18,$1e,' Board Editor');
            end;
      end;
      end;
   {}
begin with U do begin {PlayGame}
   {}
   PrintCmds;
   PrintStats;
   if FirstThru then begin
     About;
     if (IntroName <> '') then begin
         ClearLine (8);
         fastwrite (69,8,$1f,IntroName);
         if not LoadGame (IntroName,WorldExt,true) then InitGame;
         end;
      EntryRoom := G.I.Room;
      SwitchRooms (0);
      FirstThru := false;
   end;
   {}
   with Objs[0] do begin
      Board [X,Y].Kind  := PlayMode;
      Board [X,Y].Color := Info [PlayMode].Col;
      end;
   {}
   if (PlayMode=Monitor) then begin
      PutBotMsg (0,'');
      fastwrite (62,5,$1b,'Pick a command:');
      end;
   {}
   if DoDraw then
      PDrawBoard;
   {}
   GameCycle := Speed * 2;
   Done      := false;
   Halt      := false;
   Counter   := random (100);
   ObjNum    := NumObjs+1;
   {}
   repeat
      repeat
         if StandBy then with U.Objs [0] do begin
            {}
            { Pause until player moves in valid direction }
            {}
	    if TimePassed (Sec100,25) then
               BlinkOn := not BlinkOn;
            {}
            if BlinkOn then
               fastwrite (X-1,Y-1,Info [Player].Col,Info [Player].Ch)
            else begin
               if Board [X,Y].Kind = Player then
                  fastwrite (X-1,Y-1,$0f,' ')
               else
                  DrawCell (X,Y);
               end;
            fastwrite (64,5,$1f,'Pausing...');
            CheckCtrl;
            if (Key=Escape) then AskQuitGame;
            if (Dx1<>0) or (Dy1 <>0) then begin
               Info [Board [X+Dx1,Y+Dy1].Kind].Touch (X+Dx1,Y+Dy1,0,Dx1,Dy1);
               end;
            if ((Dx1<>0) or (Dy1<>0)) and
               (Info [Board [X+Dx1, Y+Dy1].Kind].GoThru) then begin
               {}
               if Board [X,Y].Kind = Player then
                  MoveObj (0,X+Dx1,Y+Dy1) {Beginning of game}
               else begin
                  { Entered thru passage, so player is on top of object }
                  DrawCell (X,Y);
                  X := X + Dx1;  Y := Y + Dy1;
                  Board [X,Y].Kind  := Player;
                  Board [X,Y].Color := Info [Player].Col;
                  DrawCell (X,Y);
                  DoArea (X,Y,0);
                  DoArea (X-Dx1,Y-Dy1,0);
                  end;
               StandBy := false;
               Clearline (5);
               Counter     := random (100);
	       ObjNum      := NumObjs+1;
               G.I.PlayFlag:= true;
               end;
            end
         else if (ObjNum <= U.NumObjs) then with Objs [ObjNum] do begin
            if (Cycle <> 0) and
               ((Counter mod Cycle) =
               (Objnum   mod Cycle)) then begin
               {}
               { This is done so that updating of objects is skewed, and  }
               { the cycles take approximately the same times to complete }
               {}
            Info [Board [X,Y].Kind].Update (ObjNum);
            end;
            ObjNum := ObjNum + 1;
            end;
         if (ObjNum > NumObjs) and not Done then begin
	    if TimePassed (Sec100,GameCycle) then begin
               Counter := Counter + 1;
               if Counter > 420 then  {7*5*4*3, so cycle is smooth}
                  Counter := 1;
               ObjNum     := 0;
               CheckCtrl;
               end;
            end;
         until Halt or Done;
      until Done;
   SoundStop;
   if (PlayMode=Player) then begin
      if (G.I.Strength <= 0) then
         NoteScore (G.I.Score);
      end
   else if (PlayMode=Monitor) then begin
      ClearLine (5);
      end;
   with Objs[0] do begin
      Board [X,Y].Kind := Player;
      Board [X,Y].Color:= Info [Player].Col;
      end;
   SoundOff := false;
   end; end;


{}
{ Menu - provides access to game itself, board editor, demo, and DOS. }
{}
procedure Menu;
var
   ReDraw:   boolean;
   DoPlay:   boolean;
begin with U do begin
   {}
   ExitProgram := false;
   FirstThru   := true;
   EntryRoom   := 0;
   ReDraw      := true;
   {}
   repeat
      SwitchRooms (0);
      repeat
         PlayMode := Monitor;
         DoPlay   := false;
         StandBy  := false;
         {}
         PlayGame (ReDraw);
         {}
         ReDraw   := false;
         {}
         case Upcase (Key) of
            'W': begin
               if WorldMenu (WorldExt) then begin
                  EntryRoom := G.I.Room;
                  ReDraw := true;
                  end;
               end;
            'P': begin
               if G.I.PlayFlag and not Debug then begin
                  DoPlay := LoadGame (G.I.OrigName,WorldExt,false);
                  EntryRoom := G.I.Room;
                  end
               else
                  DoPlay := true;
               if DoPlay then begin
                  SwitchRooms (EntryRoom);
                  NoteEnterNewRoom;
                  end;
               end;
            'A': About;
            'E': begin
               if RegEdit then begin
                  DesignBoard;
                  EntryRoom := G.I.Room;
                  ReDraw := true;
                  end;
               end;
            '|': begin
               SecretCmd;
               end;
            'S': begin
               InNum (true,66,21,'Game speed:;FS',Speed);
               Key := #0;
               end;
            'R': begin
               if WorldMenu (SaveExt) then begin
                  EntryRoom := G.I.Room;
                  SwitchRooms (EntryRoom);
                  DoPlay := true;
                  end;
               end;
            'H': begin
               LoadHi;
               ViewHi (1);
               end;
            Escape,'Q': begin
               ExitProgram := InYN ('Quit ZZT? ',true)
               end;
            end;
         if DoPlay then begin
            PlayMode := Player;
            StandBy  := true;
            PlayGame (true);
            ReDraw := true;
            end;
         until ReDraw or ExitProgram;
      until ExitProgram;
   end; end;

{}
{ Annoyingly view PLEAD FILE.}
{}
procedure AnnoyView;
var
   S:           String;
   F:           file;
   C, N, Y, Col:integer;
   Flag:        boolean;
   TempP:       pointer;
begin
   SetCBreak (false);
   S := 'END'+chr(ord('1')+random(4))+'.MSG';
   {}
   Y   := 0;
   Col := $0f;
   {}
   for C := 1 to HelpData.Num do begin
      if HelpData.Names[c] = S then begin
         assign (F,HelpFile);
         reset  (F,1);
         seek   (F,HelpData.Offsets[c]);
         Flag := true;
         while (IoResult=0) and (Flag) do begin
            blockread (F,S,1);
            TempP := ptr (seg (S),ofs(S)+1);
            if length (S) = 0 then
               dec (Col)
            else if S<>'@' then
               fastwrite (0,Y,Col,S)
            else
               Flag := false;
            inc (Y);
            end;
         close (F);
         gotoxy (1,23);
         exit;
         end;
      end;
   end;

begin
   end.

