{$I-}
unit Edit;

interface

uses
   FastWr, Crt, Dos, Keyboard, SoundU,
   GameCtrl,
   Scrolls;


procedure LoadHi;
procedure SaveHi;
procedure NoteScore (Score:integer);
procedure SetViewHi (var S:ScrollType);
procedure ViewHi (N:integer);
procedure OurEditScroll (var S:ScrollType);
procedure EditDoc;
function  RoomTitle (N:integer; NoneFlag:boolean):OurString;
function  InRoom (M:string; Def:integer; NoneFlag:boolean):integer;
procedure DesignBoard;

implementation

uses
   Glob, Obj, Lang, Main;

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


procedure DesignBoard; {Board designer subprogram}
var
   CurCategory:    integer;
   TempColor:      integer;
   {}
   ModFlag:        boolean;
   {}
   Done:           boolean;
   Mode:           (MoveMode, Draw, Text);
   Mx, My:         integer;
   CurPattern:     integer;
   CurColor:       integer;
   C,e:            integer;
   TempFlag:       boolean;
   TempStr:        OurString;
   {}
   LastObj:        ObjType; {Last-entered object is saved as pattern}
   LastObjFlag:    boolean;
   LastCell:       BoardCell;
   LastX,LastY:    integer;
   {}
   BlinkCount:     integer;
   {}
   procedure PrintCmds;
   var
      C:      integer;
      TempCh: char;
   begin
      ClearText;
      clearline (1);
      fastwrite (61,0,$1f,'     - - - -       ');
      fastwrite (62,1,$70,  '  ZZT Editor   ');
      fastwrite (61,2,$1f,'     - - - -       ');
      {}
      fastwrite (61,4, $70, ' L ');
      fastwrite (64,4, $1f, ' Load');
      {}
      fastwrite (61,5, $30, ' S ');
      fastwrite (64,5, $1f, ' Save');
      {}
      fastwrite (70,4, $70, ' H ');
      fastwrite (73,4, $1e, ' Help');
      {}
      fastwrite (70,5, $30, ' Q ');
      fastwrite (73,5, $1f, ' Quit');
      {}
      fastwrite (61,7, $70, ' B ');
      fastwrite (65,7, $1f, ' Switch boards');
      {}
      fastwrite (61,8, $30, ' I ');
      fastwrite (65,8, $1f, ' Board Info');
      {}
      fastwrite (61,10, $70, '  f1   ');
      fastwrite (68,10, $1f, ' Item');
      {}
      fastwrite (61,11, $30, '  f2   ');
      fastwrite (68,11, $1f, ' Creature');
      {}
      fastwrite (61,12, $70, '  f3   ');
      fastwrite (68,12, $1f, ' Terrain');
      {}
      fastwrite (61,13, $30, '  f4   ');
      fastwrite (68,13, $1f, ' Enter text');
      {}
      fastwrite (61,15, $70, ' Space ');
      fastwrite (68,15, $1f, ' Plot');
      {}
      fastwrite (61,16, $30, '  Tab  ');
      fastwrite (68,16, $1f, ' Draw mode');
      {}
      fastwrite (61,18, $70, ' P ');
      fastwrite (64,18, $1f, ' Pattern');
      {}
      fastwrite (61,19, $30, ' C ');
      fastwrite (64,19, $1f, ' Color:');
      {}
      for C := 9 to 15 do begin
         fastwrite (61+c, 22, C, #$db);
         end;
      for C := 1 to NumPats do
         fastwrite (61+c, 22, $0f, Info [Pats [C]].Ch);
      {}
      if Info [LastCell.Kind].PrintF then
         Info [LastCell.Kind].Print (LastX,LastY,TempCh)
      else
         TempCh := Info [LastCell.Kind].Ch;
      fastwrite (62+NumPats,22,LastCell.Color,TempCh);
      {}
      fastwrite (61,24,$1f,' Mode:');
      end;
   {}
   procedure DrawAdj (X,Y:integer);
   var
      C:integer;
      NewX,NewY:integer;
   begin
      DrawCell (X,Y);
      for C := 0 to 3 do begin
         NewX := X+UDLRx[C]; NewY := Y+UDLRy[C];
         if (NewX>=1) and (NewX<=Xs) and (NewY>=1) and (NewY<=Ys) then
            DrawCell (NewX, NewY);
         end;
      end;
   {}
   procedure PrintStats;
   begin
      if Mode=Draw then
         fastwrite (68,24,$9e,'Drawing on ')
      else if Mode=Text then
         fastwrite (68,24,$9e,'Text entry ')
      else if Mode=MoveMode then
         fastwrite (68,24,$1e,'Drawing off');
      {}
      fastwrite (72,19,$1e,Colors [CurColor-8]);
      {}
      fastwrite (CurPattern+61,21,$1f,#$1f);
      fastwrite (CurColor+ 61,21,$1f,#$1f);
      end;
   {}
   { Draw board with bottom information - just for design }
   {}
   procedure DDrawBoard;
   var
      S:String;
   begin
      DrawBox;
      PrintCmds;
      {Cls (#$db,$44);}
      Str (G.I.Room,S);
      DrawBoard;
      if U.Title <> '' then
         fastwrite ((Xs - 1 - length (U.Title)) div 2,0,$70,' '+U.Title+' ')
      else
         fastwrite ((Xs-8) div 2,0,$70,' Untitled ');
      end;
   {}
   { SetBoard: put character/color on board, set last-object info }
   {}
   procedure SetBoard (X,Y:byte; Kindc:byte; Colorc:byte);
   begin with U do begin
      Board [X,Y].Kind  := Kindc;
      Board [X,Y].Color := Colorc;
      LastCell          := Board [X,Y];
      LastObjFlag       := false;
      LastX := X; LastY := Y;
      DrawAdj (X,Y);
      end; end;
   {}
   procedure AskSave;
   begin
      Key := #0;
      if ModFlag then
         if InYn ('Save first? ',true) and (Key<>Escape) then
            DoSave ('Save world',GameName,WorldExt);
         G.I.OrigName := GameName;
      end;
   {}
   function Free (X,Y:integer):boolean;
   begin
      ModFlag := true;
      Free    := FreeCell (X,Y);
      DrawAdj (X,Y);
      end;
   {}
   { FreeNew - return true ONLY if (Mx,My) can be cleared, and there is }
   { another available object to put there. }
   {}
   function FreeNew: boolean;
   begin with U do begin
      if NumObjs < MaxObjs then
         FreeNew := Free (Mx,My)
      else
         FreeNew := false;
      end; end;
   {}
   { Put current pattern or object at cursor }
   {}
   procedure PlotBoard (Mx,My:integer);
   begin with U,Board [Mx,My] do begin
      if CurPattern <= NumPats then begin {Put pattern down}
         if Free (Mx,My) then begin
            Kind := Pats [CurPattern];
            Color := CurColor;
            end;
         end
      else begin {Put last object or character down}
         if LastObjFlag then begin
            if FreeNew then begin
               AddObj (Mx,My,LastCell.Kind,LastCell.Color,LastObj.Cycle,
                  LastObj);
               end;
            end
         else if Free (Mx,My) then
            Board [Mx,My] := LastCell;
         end;
      DrawAdj (Mx,My);
      end; end;
   {}
   procedure SetBoardInfo;
   const
      UDLRmsg: array [0..3] of String [20] =
         ('       Board '+#$18,
          '       Board '+#$19,
          '       Board '+#$1b,
          '       Board '+#$1a);
   var
      Choices:   ScrollType;
      C:         integer;
      TempS:     OurString;
      Done:      boolean;
      {}
      function Yn (F:boolean):string;
      begin
         if F then
            Yn := 'Yes'
         else
            Yn := 'No ';
         end;
      {}
   begin with U do begin
      Choices.Title := 'Board Information';
      OpenScroll (Choices);
      with Choices do begin
         Cur      := 1;
         NumLines := 9;
         PickFlag := true;
         Done     := false;
         for C := 1 to NumLines do
            new (Line [C]);
         repeat
            PickFlag := true;
            NumLines := 10;
            for C := 1 to NumLines do
               new (Line [C]);
            Line [1]^ := '         Title: '+U.Title;
            Str (RoomInfo.CanShoot,TempS);
            Line [2]^ := '      Can fire: '+TempS+' shots.';
            Line [3]^ := ' Board is dark: '+Yn (RoomInfo.IsDark);
            for C := 4 to 7 do
               Line [C]^ := UDLRmsg [c-4] +': '+
                  RoomTitle (RoomInfo.RoomUDLR [C-4],true);
            Line [8]^ := 'Re-enter when zapped: '+Yn (RoomInfo.ReEnter);
            Str (RoomInfo.TimeLimit,TempS);
            Line [9]^ := '  Time limit, 0=None: '+TempS + ' sec.';
            Line [10]^:= '          Quit!';
            {}
            ViewScroll (Choices,false,false);
            if (Key = Return) and (Cur>=1) and (Cur<=8) then
               ModFlag := true;
            if Key = Return then case Cur of
               1: begin
                  InFancy ('New title for board:',U.Title);
                  Done := true;
                  CloseScroll;
                  end;
               2: begin
                  Str (RoomInfo.CanShoot,TempS);
                  InName ('Maximum shots?','',TempS,INum);
                  if TempS <> '' then begin
                     Val (TempS,RoomInfo.CanShoot,C);
                     end;
                  PrintCmds;
                  end;
               3: begin
                  RoomInfo.IsDark   := not RoomInfo.IsDark;
                  end;
               4,5,6,7: begin
                  RoomInfo.RoomUDLR [Cur-4] :=
                     InRoom (UDLRmsg [Cur-4],RoomInfo.RoomUDLR [Cur-4],true);
                  if RoomInfo.RoomUDLR [Cur-4] > G.NumRooms then begin
                     AddRoom;
                     end;
                  Done := true;
                  end;
               8: begin
                  RoomInfo.ReEnter := not RoomInfo.ReEnter;
                  end;
               9: begin
                  Str (RoomInfo.TimeLimit,TempS);
                  InName ('Time limit?',' Sec',TempS,INum);
                  if TempS <> '' then begin
                     Val (TempS,RoomInfo.TimeLimit,C);
                     end;
                  PrintCmds;
                  end;
               10: begin
                  Done := true;
                  CloseScroll;
                  end;
               end
            else begin
               Done := true;
               CloseScroll;
               end;
            until Done;
         EmptyScroll (Choices);
         end;
      end; end;
   {}
   procedure EditScrollObj (N:integer; Str:string);
   var
      S:       ScrollType;
      C,D:     integer;
      TempStr: OurString;
      TempChr: char;
      TempPtr: pointer;
   begin with U,Objs [N] do begin
      S.Title := Str;
      OpenScroll (S);
      S.PickFlag := false;
      {}
      GetScrollText (N,S);
      if InsideLen > 0 then begin
         FreeMem (Inside,InsideLen);
         InsideLen := 0;
         end;
      {}
      OurEditScroll  (S);
      {}
      for C := 1 to S.NumLines do begin
         InsideLen := InsideLen + length (S.Line [C]^) + 1;
         end;
      {}
      GetMem (Inside,InsideLen);
      TempPtr := Inside;
      for C := 1 to S.NumLines do begin
         for D := 1 to length (S.Line [C]^) do begin
            TempChr := S.Line [C]^[D];
            Move (TempChr,TempPtr^,1);
            IncP (TempPtr,1);
            end;
         TempChr := #$0d;
         Move (TempChr,TempPtr^,1);
         IncP (TempPtr,1);
         end;
      {}
      EmptyScroll (S);
      CloseScroll;
      Key := #0;
      end; end;
   {}
   procedure ModifyObj (N:integer);
   var
      ObjKind: byte;
      C:       integer;
      Heading: string;
      TempRoom:byte;
      Yc:      integer;
      TempByte:byte;
      {}
      procedure DoParams (InFlag:boolean);
      begin with U,Objs[N] do begin
         Key := #0;
         Yc  := 9;
         {}
         if Info [ObjKind].MsgIntel<>'' then begin
            if Info [ObjKind].MsgScroll = '' then
               InNum (InFlag,63,Yc,Info [ObjKind].MsgIntel,Intel)
            else begin
               if Intel = 0 then
                  Intel := G.Def [ObjKind].Intel;
               DrawCell (X,Y);
               InChar (InFlag,63,Yc,Info [ObjKind].MsgIntel,Intel);
               DrawCell (X,Y);
               end;
            if InFlag then
               G.Def [ObjKind].Intel := Intel;
            Yc := Yc + 4;
            end;
         if (Key<>Escape) and (Info [ObjKind].MsgScroll<>'') then begin
            if InFlag then
               EditScrollObj (N,Info [ObjKind].MsgScroll);
            end;
         if (Key<>Escape) and (Info [ObjKind].MsgRate<>'') then begin
            TempByte := Rate mod $80;
            InNum (InFlag,63,Yc,Info [ObjKind].MsgRate,TempByte);
            if InFlag then begin
               Rate := (Rate and $80) + TempByte;
               G.Def [ObjKind].Rate := Rate;
               end;
            Yc := Yc + 4;
            end;
         if (Key<>Escape) and (Info [ObjKind].MsgRateH<>'') then begin
            TempByte := Rate div $80;
            InChoice (InFlag,Yc,Info [ObjKind].MsgRateH,
               'Bullets Stars',TempByte);
            if InFlag then begin
               Rate := (Rate mod $80)+$80*TempByte;
               G.Def [ObjKind].Rate := Rate;
               end;
            Yc := Yc + 4;
            end;
         if (Key<>Escape) and (Info [ObjKind].MsgDir <> '') then begin
            InDir (InFlag,Yc,Info [ObjKind].MsgDir,Xd,Yd);
            if InFlag then begin
               G.Def [ObjKind].Xd := Xd;
               G.Def [ObjKind].Yd := Yd;
               end;
            Yc := Yc + 4;
            end;
         if (Key<>Escape) and (Info [ObjKind].MsgRoom<>'') then begin
            if InFlag then begin
               TempRoom := InRoom (Info[ObjKind].MsgRoom, Room,true);
               if TempRoom <> 0 then begin
                  Room := TempRoom;
                  G.Def [ObjKind].Room := G.I.Room;
                     {Make cur room the default}
                  if Room > G.NumRooms then begin
                     AddRoom;
                     LastObjFlag    := false;
                     LastCell.Kind  := Empty;
                     LastCell.Color := $0f;
                     end;
                  G.Def [ObjKind].Room := Room;
                  end
               else
                  Key := Escape;
               Yc := Yc + 4;
               end
            else begin
               fastwrite (63,Yc,$1f,'Room: '+
                  copy (RoomTitle (Room,true),1,10));
               end;
            end;
         end; end;
   {}
   begin with U,Objs [N] do begin
      ClearText;
      ObjKind := Board [X,Y].Kind;
      {}
      ModFlag := true;
      {}
      Heading := '';
      for C := 0 to ObjKind do begin
         if (Info [C].Category=Info [ObjKind].Category) and
            (Info [C].Heading<>'') then
            Heading := Info [C].Heading;
         end;
      {}
      fastwrite (64,6,$1e,Heading);
      fastwrite (64,7,$1f,Info [ObjKind].Descr);
      {}
      DoParams (false);
      DoParams (true);
      {}
      if Key <> Escape then begin
         LastObjFlag   := true;
         LastObj       := Objs [N];
         LastCell      := Board [X,Y];
         LastX := X; LastY := Y;
         end;
      end; end;
   {}
   procedure ImportExport;
   var
      C: byte;
      F: file;
   label
      Out;
   begin with G,I do begin
      C := 1;
      InChoice (True,3,'Transfer board:','Import Export',C);
      if Key<>Escape then begin
         if (C=0) then begin
            InName ('Import board','.BRD',IEName,IFname);
            if (Key<>Escape) and (IEName<>'') then begin
               assign (F,IEName+'.BRD');
               reset (F,1);
               if CheckErr then goto Out;
               {}
               ArcRoomx;
               freemem (RoomPtr [Room],RoomSize[Room]);
               {}
               blockread (F,RoomSize [Room],sizeof (RoomSize [Room]));
               if not CheckErr then begin
                  getmem (RoomPtr [Room],RoomSize [Room]);
                  blockread (F,RoomPtr [Room]^,RoomSize [Room]);
                  end;
               if CheckErr then begin
                  RoomSize [Room] := 0;
                  InitU;
                  DDrawBoard;
                  end
               else begin
                  UnarcRoomx (Room);
                  DDrawBoard;
                  end;
               end;
            end
         else if (C=1) then begin
            InName ('Export board','.BRD',IEName,IFname);
            if (Key<>Escape) and (IEName<>'') then begin
               assign (F,IEName+'.BRD');
               rewrite (F,1);
               if CheckErr then goto Out;
               {}
               ArcRoomx;
               blockwrite (F,RoomSize [Room],sizeof (RoomSize[Room]));
               blockwrite (F,RoomPtr [Room]^,RoomSize [Room]);
               UnarcRoomx (Room);
               {}
               if CheckErr then goto Out;
               close (F);
               end;
            end;
         end;
      {} Out:
      PrintCmds;
      end; end;
   {}
   procedure PaintFill (X,Y:integer; Bkgnd:BoardCell);
   var
      Dir:     integer;
      TempCell:BoardCell;
      N,C:     byte;
      Xt,Yt:   array [0..255] of integer; {Circular buffer}
   begin with U do begin
      N := 1; C := 0;
      while N <> C do begin
         TempCell := Board [X,Y];
         PlotBoard (X,Y);
         if (TempCell.Kind <>Board [X,Y].Kind) or
            (TempCell.Color<>Board [X,Y].Color) then begin
            for Dir := 0 to 3 do with Board [X+UDLRx[Dir],Y+UDLRy[Dir]] do
               begin
               if (Kind=Bkgnd.Kind) and
                  ((Bkgnd.Kind=Empty) or (Color=Bkgnd.Color)) then begin
                  Xt [N] := X+UDLRx [Dir];
                  Yt [N] := Y+UDLRy [Dir];
                  N := N + 1;
                  end;
               end;
            end;
         C := C + 1;
         X := Xt [C];
         Y := Yt [C];
         end;
      end; end;
   {}
begin with U do begin
   if (G.I.PlayFlag) or (FlagNum ('SECRET')>=0) then begin
      NewGame;
      InitGame;
      end;
   InitInfoEdit;
   Counter := 0;
   {}
   ModFlag      := false;
   Mx           := Xs div 2;
   My           := Ys div 2;
   Mode         := MoveMode;
   CurPattern   := 1;
   CurColor     := $0e;
   BlinkCount   := 0;
   {}
   LastObjFlag    := false;
   LastCell.Kind  := Empty;
   LastCell.Color := $0f;
   {}
   if (G.I.Room<>0) then
      SwitchRooms (G.I.Room);
   DDrawBoard;
   if (G.NumRooms = 0) then
      AddRoom;
   {}
   Done := false;
   {}
   repeat
      if Mode=Draw then begin
         PlotBoard (Mx,My);
         end;
      CheckCtrl;
      if (Key=#0) and (Dx1=0) and (Dy1=0) and (not Fire1) then begin
         {}
         { Blink cursor }
         {}
	 if TimePassed (Sec100,15) then begin
            BlinkCount := (BlinkCount+1) mod 3;
            end;
         if (BlinkCount=0) then
            DrawCell (Mx,My)
         else
            fastwrite (Mx-1, My-1, $0f, #$c5);
         {}
         { Update status }
         {}
         PrintStats;
         end
      else
         DrawCell (Mx, My);
      {}
      if (Mode = Text) then begin
         if (Key>=#$20) and (Key < #$80) then begin
            if (Free (Mx,My)) then begin
               Board [Mx,My].Kind := CurColor-9+TextCol;
               Board [Mx,My].Color:= ord (Key);
               DrawAdj (Mx,My);
               Dx1 := 1;
               Dy1 := 0;
               end;
            Key := #0;
            end
         else if (Key=#$08) and (Mx>1) and
            (Free (Mx-1,My)) then begin
            Mx := Mx - 1;
            end
         else if (Key = Return) or (Key = Escape) then begin
            Mode := MoveMode;
            Key := #0;
            end;
         end; {fall through}
      {}
      with Board [Mx,My] do begin
         if Fire1 or (Key=Space) then begin
            Fire1Off := true;
            if (Kind = Empty) or (Info [Kind].Terrain and
               LastObjFlag and (CurPattern>NumPats)) or
               (Dx1<>0) or (Dy1<>0) then
               PlotBoard (Mx,My)
            else begin
               TempFlag := Free (Mx,My);
               if TempFlag then
                  U.Board [Mx,My].Kind := Empty; {Overwrite terrain}
               end;
            end;
         if (Dx1<>0) or (Dy1<>0) then begin
            Mx := Mx + Dx1;
            if Mx < 1  then Mx := 1;
            if Mx > Xs then Mx := Xs;
            My := My + Dy1;
            if My < 1  then My := 1;
            if My > Ys then My := Ys;
            Fastwrite (Mx-1, My-1, $0f, #$c5);
            if (Key=#0) and (Joyflag) then
               Delay (70);
            Fire1Off := false;
            end;
         case upcase (Key) of
            '`': DDrawBoard;
            'P': begin {Select pattern}
               fastwrite (62,21,$1f,'       ');
               if CurPattern <= NumPats then
                  CurPattern := CurPattern + 1
               else
                  CurPattern := 1;
               end;
            'C': begin {Color}
               fastwrite (72,19,$1e,'       ');
               fastwrite (69,21,$1f,'        ');
               if (CurColor mod $10) <> $f then
                  CurColor := CurColor + 1
               else
                  CurColor := (CurColor div $10) * $10+9;
               end;
            'L': begin
               AskSave;
               if Key<>Escape then begin
                  if WorldMenu (WorldExt) then begin
                  if (G.I.PlayFlag or (FlagNum ('SECRET')>=0)) and
                        not Debug then begin
                        ClearLine (3);
                        ClearLine (4);
                        ClearLine (5);
                        fastwrite (63,4,$1e,'Can not edit');
                        if G.I.PlayFlag then
                           fastwrite (63,5,$1e,'a saved game!')
                        else
                           fastwrite (63,5,$1e,'  '+G.I.OrigName+'!');
                        ErrDelay;
                        NewGame;
                        InitGame;
                        end;
                     ModFlag := false;
                     DDrawBoard;
                     end;
                  end;
               PrintCmds;
               end;
            'S': begin
               DoSave ('Save world:',GameName,WorldExt);
               if Key<>Escape then
                  ModFlag := false;
               PrintCmds;
               end;
            'Z': begin
               if InYN ('Clear board? ',false) then begin
                  for C := U.NumObjs downto 1 do
                     KillObj (C);
                  InitU;
                  DDrawBoard;
                  end
               else
                  PrintCmds;
               end;
            'N': begin
               if InYN ('Make new world? ',false)and(Key<>Escape)then begin
                  AskSave;
                  if Key<>Escape then begin
                     NewGame;
                     InitGame;
                     DDrawBoard;
                     ModFlag := false;
                     end;
                  end;
               PrintCmds;
               end;
            'Q',Escape: begin
               Done := true;
               end;
            'B': begin  {Switch boards}
               C := InRoom ('Switch boards',G.I.Room,false);
               if Key <> Escape then begin
                  if C>G.NumRooms then
                     if InYN ('Add new board? ',false) then
                        AddRoom;
                  SwitchRooms (C);
                  DDrawBoard;
                  end;
               PrintCmds;
               end;
            '?': begin
               SecretCmd;
               PrintCmds;
               end;
            Tab: if Mode = MoveMode then
                  Mode := Draw
               else
                  Mode := MoveMode;
            f1,f2,f3: begin
               fastwrite (Mx-1,My-1,$0f, #$c5); {Put cursor on}
               for C := 3 to 20 do
                  Clearline (C);
               case Key of
                  f1: CurCategory := 1;
                  f2: CurCategory := 2;
                  f3: CurCategory := 3;
                  end;
               {}
               { Print choices }
               {}
               C := 3;
               for E := 0 to NumClasses do begin
                  if Info [E].Category = CurCategory then begin
                     if Info [E].Heading <> '' then begin
                        C := C + 1;
                        fastwrite (65,C,$1e,Info [E].Heading);
                        C := C + 1;
                        end;
                     fastwrite (61,C,$30 + ($40*(C mod 2)),
                        ' '+Info [E].KeyCode+' ');
                     fastwrite (65,C,$1f,Info [E].Descr);
                     if Info [E].Col = $ff then
                        TempColor := CurColor mod $10+$10
                     else if Info [E].Col = $fe then
                        TempColor := (CurColor * $10) - $71
                     else if Info [E].Col = $fd then
                        TempColor := (CurColor-8)*$11+8
                     else if (Info [E].Col and $70) = 0 then
                        TempColor := Info [E].Col mod $10+$10
                     else
                        TempColor := Info [E].Col;
                     fastwrite (78,C,TempColor, Info [E].Ch);
                     C := C + 1;
                     end;
                  end;
               GetKey;
               for E := 1 to NumClasses do begin
                  if (Info [E].Category = CurCategory) and
                     (Info [E].KeyCode  = Upcase (Key)) then begin
                     {}
                     { Put it here! }
                     {}
                     if E = Player then begin
                        if Free (Mx,My) then
                           MoveObj (0,Mx,My);
                        end
                     else begin
                        if Info [E].Col = $ff then
                           TempColor := CurColor
                        else if Info [E].Col = $fe then
                           TempColor := CurColor * $10 - $71
                        else if Info [E].Col = $fd then
                           TempColor := (CurColor-$8) * $11 + 8
                        else
                           TempColor := Info [E].Col;
                        {}
                        if (Info [E].Cycle = -1) then begin
                           {}
                           { Put down non-object item }
                           {}
                           if Free (Mx,My) then
                              SetBoard (Mx,My,E,TempColor);
                           end
                        else begin
                           {}
                           { Put down object }
                           {}
                           if FreeNew then begin
                              AddObj (Mx,My,E,TempColor,Info [E].Cycle,
                                 NormObj);
                              {}
                              with Objs [NumObjs] do begin
                                 if Info [E].MsgIntel<>'' then
                                    Intel := G.Def [E].Intel;
                                 if Info [E].MsgRate<>'' then
                                    Rate  := G.Def [E].Rate;
                                 if Info [E].MsgDir<>'' then begin
                                    Xd    := G.Def [E].Xd;
                                    Yd    := G.Def [E].Yd;
                                    end;
                                 if Info [E].MsgRoom<>'' then
                                    Room  := G.Def [E].Room;
                                 end;
                              {}
                              ModifyObj (NumObjs);
                              if Key = Escape then
                                 KillObj (NumObjs)
                              {}
                              end; {else}
                           end; {if}
                        end; {if}
                     end; {if}
                  end; {for}
               PrintCmds;
               end; {case}
            f4: begin {Text}
               if Mode <> Text then
                  Mode := Text
               else
                  Mode := MoveMode;
               end;
            'H': begin {Help}
               ViewDoc ('editor.hlp','World editor help');
               end;
            'X': begin {Paint-fill in current pattern}
               PaintFill (Mx,My,Board [Mx,My]);
               end;
            '!': begin {Edit text file}
               EditDoc;
               PrintCmds;
               end;
            'T': begin {Transfer Import/Export}
               ImportExport;
               end;
            Enter: begin {Modify object}
               if ObjAt (Mx,My)>=0 then begin
                  ModifyObj (ObjAt (Mx,My));
                  PrintCmds;
                  end
               else begin
                  LastObjFlag := false;
                  LastCell    := Board [Mx,My];
                  end;
               end;
            'I': begin {Board info}
               SetBoardInfo;
               end;
            end;
         end;
      if Done then begin
         AskSave;
         if Key=Escape then begin
            Done := false;
            PrintCmds;
            end;
         end;
      until Done;
   Key    := #0;
   InitInfoPlay;
   end; end;

{}
{ Load high scores }
{}
procedure LoadHi;
var
   F:File of HiType;
   C:integer;
begin
   assign (F,G.I.OrigName+'.HI');
   reset (F);
   if IOResult=0 then
      read (F,HiScores);
   close (F);
   if (IOResult<>0) then begin
      for C := 1 to NumHi do begin
         HiScores [C].Name  := '';
         HiScores [C].Score := -1;
         end;
      end;
   end;

{}
{ Save high scores }
{}
procedure SaveHi;
var
   F:File of HiType;
begin
   assign (F,G.I.OrigName+'.HI');
   rewrite (F);
   write (F,HiScores);
   close (F);
   if CheckErr then exit;
   end;


{}
{ Set up to view high scores }
{}
procedure SetViewHi (var S:ScrollType);
var
   C:       integer;
   TempStr: string;
begin
   InitScroll (S);
   AddScrollLine (S,'Score  Name');
   AddScrollLine (S,'-----  ----------------------------------');
   for C := 1 to NumHi do begin
      if HiScores [C].Name <> '' then begin
         Str (HiScores[C].Score:5,TempStr);
         AddScrollLine (S,TempStr+'  '+HiScores [C].Name);
         end;
      end;
   end;

procedure ViewHi (N:integer);
var
   S:ScrollType;
begin
   S.Cur := N;
   SetViewHi (S);
   if S.NumLines > 2 then begin
      S.Title := 'High scores for '+G.I.OrigName;
      OpenScroll (S);
      ViewScroll (S,false,true);
      CloseScroll;
      end;
   EmptyScroll (S);
   end;

procedure OurEditScroll (var S:ScrollType);
begin
   ClearText;
   fastwrite (61,4 ,$30,' Return ');
   fastwrite (64,5 ,$1f,' Insert line');
   fastwrite (61,7 ,$70,' Ctrl-Y ');
   fastwrite (64,8 ,$1f,' Delete line');
   fastwrite (61,10,$30,' Cursor keys ');
   fastwrite (64,11,$1f,' Move cursor');
   fastwrite (61,13,$70,' Insert ');
   fastwrite (64,14,$1f,' Insert mode: ');
   fastwrite (61,16,$30,' Delete ');
   fastwrite (64,17,$1f,' Delete char');
   fastwrite (61,19,$70,' Escape ');
   fastwrite (64,20,$1f,' Exit editor');
   EditScroll (S);
   end;

procedure EditDoc;
var
   S:       ScrollType;
   Filename:OurString;
begin
   Filename := '';
   InName ('File to edit','.HLP',Filename,IFname);
   if Filename <> '' then begin
      LoadScroll ('*'+Filename+'.HLP',S);
      S.Title := 'Editing '+Filename;
      OpenScroll (S);
      OurEditScroll (S);
      SaveScroll (Filename+'.HLP',S);
      EmptyScroll (S);
      CloseScroll;
      end;
   end;

procedure NoteScore (Score:integer);
var
   S:    ScrollType;
   Name: OurString;
   C,N:  integer;
begin
   N := 1;
   while (N<=NumHi) and (Score < HiScores[N].Score) do
      N := N + 1;
   if (N <= NumHi) and (Score>0) then begin
      for C := NumHi-1 downto N do begin
         HiScores [C+1] := HiScores [C];
         end;
      HiScores [N].Score := Score;
      HiScores [N].Name  := '-- You! --';
      SetViewHi (S);
      S.Cur := N;
      S.Title := 'New high score for '+G.I.OrigName;
      OpenScroll (S);
      DrawScroll (S,false,false);
      Name := '';
      InFancy ('Congratulations!  Enter your name:',Name);
      HiScores [N].Name := Name;
      SaveHi;
      CloseScroll;
      DrawBoard;
      EmptyScroll (S);
      end;
   end;

{}
{ Return title of room }
{}
function RoomTitle (N:integer; NoneFlag:boolean):OurString;
var
   Point:pointer;
   S:    OurString;
begin
   if (N=0) and NoneFlag then
      RoomTitle := 'None'
   else if N=G.I.Room then
      RoomTitle := U.Title
   else begin
      Point := G.RoomPtr [N];
      Move (Point^, S, SizeOf (OurString));
      RoomTitle := S;
      end;
   end;

{}
{ Pick a room from all possible choices }
{}
function InRoom (M:string; Def:integer; NoneFlag:boolean):integer;
var
   S:String;
   N,Code:integer;
   RoomList:ScrollType;
begin
   with RoomList do begin
      Title    := M;
      Cur      := Def+1;
      PickFlag := true;
      NumLines := 0;
      for N := 0 to G.NumRooms do
         AddScrollLine (RoomList,RoomTitle (N,NoneFlag));
      AddScrollLine (RoomList,'Add new board');
      {}
      OpenScroll (RoomList);
      ViewScroll (RoomList,false,false);
      CloseScroll;
      {}
      EmptyScroll (RoomList);
      end;
   if Key=Escape then
      InRoom := 0
   else
      InRoom := RoomList.Cur-1;
   end;

begin
   end.
