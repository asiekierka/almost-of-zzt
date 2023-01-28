{$I-}
unit Obj;

interface

uses
   FastWr, Crt, Dos, Keyboard, SoundU,
   GameCtrl,
   Scrolls;

procedure InitDef;
procedure InitFirst;
procedure Revolve (X,Y,DirC:integer);
procedure PushThruXPorter (X,Y,Dx,Dy:integer);
procedure MoveTo (X1,Y1,X2,Y2:integer);
procedure Push (X,Y,Dx,Dy:integer);
procedure DoArea (Xc,Yc:integer; Code:integer);
procedure AskQuitGame;
procedure InitInfo;
procedure InitInfoEdit;
procedure InitInfoPlay;


procedure UpdNothing  (N:integer);
procedure UpdSpecial  (N:integer);
procedure UpdEnemy    (N:integer);
procedure UpdSEnemy   (N:integer);
procedure UpdWanderer (N:integer);
procedure UpdChaser   (N:integer);
procedure UpdCentiH   (N:integer);
procedure UpdCenti    (N:integer);
procedure UpdBullet   (N:integer);
procedure UpdShooter  (N:integer);
procedure UpdConveyorCW (N:integer);
procedure UpdConveyorCCW(N:integer);
procedure UpdBomb     (N:integer);
procedure UpdXporter  (N:integer);
procedure UpdSBomb    (N:integer);
procedure UpdSlime    (N:integer);
procedure UpdShark    (N:integer);
procedure UpdProg     (N:integer);
procedure UpdDuper    (N:integer);
procedure UpdPusher   (N:integer);
procedure UpdPlayer   (N:integer);
procedure UpdMonitor  (N:integer);
procedure UpdScroll   (N:integer);
procedure UpdBlinkWall(N:integer);


procedure TouchNothing (X,Y,P:integer; var Dx,Dy:integer);
procedure TouchEnemy   (X,Y,P:integer; var Dx,Dy:integer);
procedure TouchBomb    (X,Y,P:integer; var Dx,Dy:integer);
procedure TouchXPorter (X,Y,P:integer; var Dx,Dy:integer);
procedure TouchEnergizer (X,Y,P:integer; var Dx,Dy:integer);
procedure TouchProg    (X,Y,P:integer; var Dx,Dy:integer);
procedure TouchKey     (X,Y,P:integer; var Dx,Dy:integer);
procedure TouchAmmo    (X,Y,P:integer; var Dx,Dy:integer);
procedure TouchGem     (X,Y,P:integer; var Dx,Dy:integer);
procedure TouchPassage (X,Y,P:integer; var Dx,Dy:integer);
procedure TouchDoor    (X,Y,P:integer; var Dx,Dy:integer);
procedure TouchPush    (X,Y,P:integer; var Dx,Dy:integer);
procedure TouchTorch   (X,Y,P:integer; var Dx,Dy:integer);
procedure TouchInvisoWall (X,Y,P:integer; var Dx,Dy:integer);
procedure TouchBrush   (X,Y,P:integer; var Dx,Dy:integer);
procedure TouchFakeWall(X,Y,P:integer; var Dx,Dy:integer);
procedure TouchBound   (X,Y,P:integer; var Dx,Dy:integer);
procedure TouchWater   (X,Y,P:integer; var Dx,Dy:integer);
procedure TouchSlime   (X,Y,P:integer; var Dx,Dy:integer);
procedure TouchScroll  (X,Y,P:integer; var Dx,Dy:integer);

procedure PrintNothing  (X,Y:integer;  var C:Char);
procedure PrintShooter  (X,Y:integer;  var C:Char);
procedure PrintLine2    (X,Y:integer;  var C:Char);
procedure PrintConveyorCW  (X,Y:integer;  var C:Char);
procedure PrintConveyorCCW (X,Y:integer;  var C:Char);
procedure PrintBomb     (X,Y:integer;  var C:Char);
procedure PrintXporter  (X,Y:integer;  var C:Char);
procedure PrintSBomb    (X,Y:integer;  var C:Char);
procedure PrintBlinkWall(X,Y:integer;  var C:Char);
procedure PrintDuper    (X,Y:integer;  var C:Char);
procedure PrintProg     (X,Y:integer;  var C:Char);
procedure PrintPusher  (X,Y:integer;  var C:Char);


implementation

uses
   Glob, Edit, Lang, Main;


{}
{ Update procedures for all objects }
{}

{$F+}

procedure UpdNothing (N:integer); {Null update procedure}
begin
   end;

procedure TouchNothing (X,Y,P:integer; var Dx,Dy:integer);
   {null touch procedure}
begin
   end;

procedure PrintNothing (X,Y:integer; var C:char);
begin
   C := '?';
   end;

procedure UpdSpecial (N:integer);
begin with U,Objs [N] do begin
   case X of
      0: begin {Bottom message}
         fastwrite ((Xs-length(RoomInfo.BotMsg))div 2,Ys-1,
            (Rate mod 7)+9,' '+RoomInfo.BotMsg+' ');
         Rate := Rate - 1;
         if (Rate <= 0) then begin
            KillObj (N);
            ObjNum := ObjNum - 1;
            DrawBox;
            RoomInfo.BotMsg := '';
            end;
         end;
      end;
   end; end;

procedure TouchEnemy (X,Y,P:integer; var Dx,Dy:integer);
begin
   ZapWith (P,X,Y);
   end;

procedure UpdEnemy (N:integer);
var
   Dx,Dy:integer;
begin with U,Objs [N] do begin
   if Random (10)>Intel then {be dumb}
      PickRandomDir (Dx,Dy)
   else {be smart}
      SeekPlayer (X,Y,Dx,Dy);
   {}
   if Info [Board [X+Dx,Y+Dy].Kind].GoThru then
      MoveObj (N,X+Dx,Y+Dy)
   else if Board [X+Dx,Y+Dy].Kind = Player then
      ZapWith (N,X+Dx,Y+Dy);
   end; end;

procedure UpdSEnemy (N:integer);
var
   Flag:     boolean;
   FireKind: byte;
begin with U,OBjs [N] do begin
   FireKind := Bullet; if (Rate >= $80) then FireKind := SBomb;
   if random (10)*3 <= (Rate mod $80) then begin
      if DistF (X,Objs[0].X)<=2 then
         Flag := TryFire (FireKind,X,Y,0,SignF (Objs [0].Y-Y),1)
      else
         Flag := false;
   if (not Flag) and (DistF (Y,Objs[0].Y)<=2) then
      Flag := TryFire (FireKind,X,Y,SignF (Objs [0].X-X),0,1);
      end;
   UpdEnemy (N);
   end; end;

procedure UpdWanderer (N:integer);
begin with U,Objs [N] do begin
   if (Xd=0) and (Yd=0) then begin {Resting}
      if random (17) >= (8+Rate) then begin {Start moving}
         if random (9) <= Intel then begin {Move smartly}
            SeekPlayer (X,Y,Xd,Yd);
            end
         else begin {Move stupidly}
            PickRandomDir (Xd,Yd);
            end;
         end;
      end
   else begin {Moving}
      if ((Y=Objs [0].Y) or (X=Objs [0].X)) and
         (random (9) <= Intel) then begin
         SeekPlayer (X,Y,Xd,Yd);
         end;
      with Board [X+Xd,Y+Yd] do begin
         if Kind=Player then
            ZapWith (N,X+Xd,Y+Yd)
         else if Info [Kind].GoThru then begin
            MoveObj (N,X+Xd,Y+Yd);
            if random (17) >= (8+Rate) then begin {Stop moving}
               Xd := 0;
               Yd := 0;
               end;
            end
         else begin
            Xd := 0; Yd := 0;
            end;
         end;
      end;
   end; end;

procedure UpdChaser (N:integer);
var
   Dx,Dy:integer;
begin with U,Objs [N] do begin
   if (X<>Objs [0].X) and
      (DistF (Y,Objs[0].Y) <= (8-Intel)) then begin
      Dx := SignF (Objs [0].X-X);
      Dy := 0;
      end
   else if DistF (X,Objs[0].X) <= (8-Intel) then begin
      Dy := SignF (Objs [0].Y-Y);
      Dx := 0;
      end
   else begin
      Dx := 0; Dy := 0;
      end;
   with Board [X+Dx,Y+Dy] do begin
      if Info [Kind].GoThru then
         MoveObj (N,X+Dx,Y+Dy)
      else if (Kind=Player) or (Kind=BreakWall) then
         ZapWith (N,X+Dx,Y+Dy);
      end;
   end; end;

procedure UpdCentiH (N:integer);
var
   Dx,Dy:      integer;
   TempX,TempY:integer;
   Temp:       integer;
begin with U,Objs [N] do begin
   {}
   { Find a direction to move in }
   {}
   if (X=Objs[0].X) and (Random (10)<Intel) then begin
      { Intelligent - move toward player }
      Yd := Signf (Objs [0].y-y);
      Xd := 0;
      end
   else if (Y=Objs [0].Y) and (Random (10)<Intel) then begin
      Xd := Signf (Objs [0].X-X);
      Yd := 0;
      end
   else if (Random (10)*4<(Rate)) or ((Xd=0) and (Yd=0)) then begin
      { Deviant - make a sudden turn, or start motion }
      PickRandomDir (Xd,Yd);
      end;
   {}
   { Otherwise, continue in same direction. }
   { See if we can actually move in desired direction }
   {}
   if not (Info [Board [X+Xd,Y+Yd].Kind].GoThru or
      (Board [X+Xd,Y+Yd].Kind=Player)) then begin
      Dx := Xd;  Dy := Yd;
      {}
      { No, so pick a random direction to turn }
      {}
      Temp   := Yd * (random(2)*2-1); {Make 90 degree turn in}
      Yd     := Xd * (random(2)*2-1); {random direction}
      Xd     := Temp;
      if not (Info [Board [X+Xd,Y+Yd].Kind].GoThru or
         (Board [X+Xd,Y+Yd].Kind=Player)) then begin
         {}
         { Turn in other 90 degree direction }
         {}
         Xd := -Xd; Yd := -Yd;
         if not (Info [Board [X+Xd,Y+Yd].Kind].GoThru or
            (Board [X+Xd,Y+Yd].Kind=Player)) then begin
            {}
            { Switch into reverse of original direction }
            {}
            if Info [Board [X-Dx,Y-Dy].Kind].GoThru or
               (Board [X-Dx,Y-Dy].Kind=Player) then begin
               Xd := -Dx;
               Yd := -Dy;
               end
            else begin
               Xd := 0;
               Yd := 0;
               end;
            end;
         end;
      end;
   {}
   if (Xd=0) and (Yd=0) then begin
      {}
      { We are stuck, so switch head & tail. }
      {}
      Board [X,Y].Kind := Centi;
      Parent := -1;
      while Objs [N].Child > 0 do begin
         Temp            := Objs [N].Child;
         Objs [N].Child  := Objs [N].Parent;
         Objs [N].Parent := Temp;
         N               := Temp;
         end;
      Objs [N].Child := Objs [N].Parent;
      Board [Objs [N].X,Objs [N].Y].Kind := CentiH;
      end
   else if Board [X+Xd,Y+Yd].Kind = Player then begin {Kill player}
      if Child <> -1 then begin
         Board [Objs [Child].X,Objs[Child].Y].Kind := CentiH;
         Objs [Child].Xd   := Xd;
         Objs [Child].Yd   := Yd;
         DrawCell (Objs [Child].X,Objs [Child].Y);
         end;
      ZapWith (N,X+Xd,Y+Yd);
      end
   else begin
      {}
      { Move centipede }
      {}
      MoveObj (N,X+Xd,Y+Yd);
      {}
      { Now move the tails that trail behind }
      {}
      TempX := X-Xd;
      TempY := Y-Yd;
      Dx := Xd;
      Dy := Yd;
      {}
      repeat with U.Objs [N] do begin
         TempX := X-Xd;
         TempY := Y-Yd;
         Dx    := Xd;
         Dy    := Yd;
         if Child < 0 then begin
            {}
            { Has no known trailers. See if we can absorb any. }
            {}
            if (Board [TempX-Dx,TempY-Dy].Kind = Centi) and
               (Objs[ObjAt(TempX-Dx,TempY-Dy)].Parent < 0) then
               Child := ObjAt (TempX-Dx,TempY-Dy)
            else if (Board [TempX-Dy,TempY-Dx].Kind = Centi) and
               (Objs[ObjAt(TempX-Dy,TempY-Dx)].Parent < 0) then
               Child := ObjAt (TempX-Dy,TempY-Dx)
            else if (Board [TempX+Dy,TempY+Dx].Kind = Centi) and
               (Objs[ObjAt(TempX+Dy,TempY+Dx)].Parent < 0) then
               Child := ObjAt (TempX+Dy,TempY+Dx)
            end;
         if Child > 0 then begin
            Objs [Child].Parent := N;
            Objs [Child].Intel  := Intel;
            Objs [Child].Rate   := Rate;
            Objs [Child].Xd     := TempX-Objs [Child].X;
            Objs [Child].Yd     := TempY-Objs [Child].Y;
            MoveObj (Child,TempX,TempY);
            end;
         N := Child;
         end; until N = -1; {Can't check Child because WITH is over}
      end;
   end; end;

procedure UpdCenti (N:integer);
begin with U,Objs [N] do begin
   if Parent < 0 then
      if Parent < -1 then
         Board [X,Y].Kind := CentiH
      else
         Parent := Parent - 1; {Time delay - delay 1 move before changing}
         { This happens so we can be absorbed by any nearby heads}
   end; end;

procedure UpdBullet (N:integer);
var
   TempX, TempY,
   TempObj:      integer;
   TempKind:     byte;
   FirstRick:    boolean;
label
   Loop;
begin with U,Objs[N] do begin
   FirstRick := true;
   {}
   {} Loop:
   {}
   TempX := X+Xd; TempY := Y+Yd;
   TempKind := Board [TempX,TempY].Kind;
   {}
   {Used to DEC Rate and zap bullet}
   {}
   if (Info [TempKind].GoThru) or (TempKind=Water) then
      MoveObj (N,TempX,TempY) {Move bullet}
   else if (TempKind=Ricochet) and (FirstRick) then begin
      Xd := -Xd; Yd := -Yd;
      SoundAdd (1,#$f9+#1);
      FirstRick := false;
      goto Loop;
      end
   else if (TempKind=BreakWall) or (Info [TempKind].Killable and
      ((TempKind=Player) or (Intel=0))) then begin
      if Info [TempKind].Score<>0 then begin
         G.I.Score := G.I.Score +
            Info [TempKind].Score;
         PrintStats;
         end;
      ZapWith (N,TempX,TempY); {Remove bullet & target}
      end
   else if (Board [X+Yd,Y+Xd].Kind = Ricochet) and (FirstRick) then begin
      TempX := Xd; Xd := -Yd; Yd := -TempX;
      SoundAdd (1,#$f9+#1);
      FirstRick := false;
      goto Loop;
      end
   else if (Board [X-Yd,Y-Xd].Kind = Ricochet) and (FirstRick) then begin
      TempX := Xd; Xd := Yd; Yd := TempX;
      SoundAdd (1,#$f9+#1);
      FirstRick := false;
      goto Loop;
      end
   else begin
      KillObj (N); {Remove bullet}
      ObjNum := ObjNum - 1;
      if (TempKind=Prog) or (TempKind=Scroll) then begin
         TempObj := ObjAt (TempX,TempY);
         if LSendMsg (-TempObj, 'SHOT',false) then begin end;
         end;
      end;
   end; end;

procedure PrintShooter (X,Y:integer; var C:char);
begin with U do begin
   case (Counter mod 8) of
      0,1: C := #$18;
      2,3: C := #$1a;
      4,5: C := #$19;
      else C := #$1b;
      end;
   end; end;

procedure PrintLine2 (X,Y:integer; var C:char);
var
   I, A, K:integer;
begin with U do begin
   A := 1;
   K := 1;
   for I := 0 to 3 do begin
      case U.Board [X+UDLRx[I],Y+UDLRy[I]].Kind of
         Line2,Bound: A := A + K;
         end;
      K := K * 2;
      end;
   C := Line2String [A]
   end; end;

procedure UpdShooter (N:integer);
var
   Flag:     boolean;
   Dx,Dy:    integer;
   FireKind: byte;
begin with U,Objs [N] do begin
   DrawCell (X,Y);
   FireKind := Bullet; if (Rate >= $80) then FireKind := SBomb;
   if random (9) < (Rate mod $80) then begin {maybe fire a shot}
      if random (9)<=intel then begin {fire smart shot}
         if DistF (X,Objs[0].X) <= 2 then
            Flag := TryFire (FireKind,X,Y,0,SignF (Objs [0].Y-Y),1)
         else
            Flag := false;
         if (not Flag) and (DistF (Y,Objs[0].Y)<=2) then
            Flag := TryFire (FireKind,X,Y,SignF (Objs [0].X-X),0,1);
         end
      else begin {fire a random shot}
         PickRandomDir (Dx,Dy);
         Flag := TryFire (FireKind,X,Y,Dx,Dy,1);
         end;
      end;
   end; end;

procedure Revolve (X,Y,DirC:integer);
{}
{ Revolve eight surronding objects around point, Dir=1 clockwise }
{}
var
   C:           integer;
   Temp:        integer;
   X1,Y1:       integer;
   CanMoveThis: boolean;
   TempCell:    array [0..7] of BoardCell;
   StartC, EndC:integer;
   Cell:        BoardCell;
begin with U do begin
   if DirC = 1 then begin {Clockwise}
      StartC := 0;
      EndC   := 8;
      end
   else begin {Counter clockwise}
      StartC := 7;
      EndC   := -1;
      end;
   CanMoveThis := true;
   C := StartC;
   repeat
      TempCell [C] := Board [X+ClockX [C],Y+ClockY [C]];
      with TempCell [C] do begin
         if Kind = Empty then
            CanMoveThis := true
         else if not Info [Kind].Movable then
            CanMoveThis := false;
         end;
      C := C + DirC;
      until C=EndC;
   C := StartC;
   repeat
      with TempCell [C] do begin
         if CanMoveThis then begin
            if Info [Kind].Movable then begin
               X1 := X+ClockX [(C-DirC+8) mod 8];
               Y1 := Y+ClockY [(C-DirC+8) mod 8];
               if Info [Kind].Cycle > -1 then begin {Move obj}
                  Cell := Board [X+ClockX[C],Y+ClockY[C]];
                  Temp := ObjAt (X+ClockX [C],Y+ClockY [C]);
                  Board [X+ClockX[C],Y+ClockY[C]] := TempCell [C];
                     {Put player where he was before rotation}
                  Board [X1,Y1].Kind := Empty; {Must empty before MoveObj}
                  MoveObj (Temp,X1,Y1);
                  Board [X+ClockX[C],Y+ClockY[C]] := Cell;
                  end
               else begin
                  Board [X1,Y1] := TempCell [C];
                  DrawCell (X1,Y1);
                  end;
               {}
               if not Info [TempCell [(C+DirC+8) mod 8].Kind].Movable then
                  begin
                  Board [X+ClockX[C],Y+ClockY[C]].Kind := Empty;
                  DrawCell (X+ClockX[C],Y+ClockY[C]);
                  end;
               end
            else
               CanMoveThis := false;
            end
         else if Kind = Empty then
            CanMoveThis := true
         else if not Info [Kind].Movable then
            CanMoveThis := false;
         end;
      C := C + DirC;
      until C=EndC;
   end; end;

procedure PrintConveyorCw (X,Y:integer; var C:char);
begin with U do begin
   case (Counter div Info [ConveyorCw].Cycle) mod 4 of
      0:   C := #$b3;
      1:   C := '/';
      2:   C := #$c4;
      else C := '\';
      end;
   end; end;

procedure UpdConveyorCW (N:integer); {Clockwise conveyor}
begin with U,Objs [N] do begin
   DrawCell (X,Y);
   Revolve (X,Y,1);
   end; end;

procedure PrintConveyorCCW (X,Y:integer; var C:char);
begin with U do begin
   case (Counter div Info [ConveyorCCW].Cycle) mod 4 of
      3:   C := #$b3;
      2:   C := '/';
      1:   C := #$c4;
      else C := '\';
      end;
   end; end;

procedure UpdConveyorCCW (N:integer); {Counter-clockwise conveyor}
begin with U,Objs [N] do begin
   DrawCell (X,Y);
   Revolve (X,Y,-1);
   end; end;

procedure PrintBomb (X,Y:integer; var C:char);
begin with U,Objs [ObjAt (X,Y)] do begin;
   if Intel <= 1 then
      C := #$0b
   else
      C := chr (Intel+$30);
   end; end;

procedure UpdBomb (N:integer);
var
   TempX,TempY:integer;
begin with U,Objs [N] do begin
   if Intel > 0 then begin
      Intel := Intel - 1;
      DrawCell (X,Y);
      if (Intel=1) then begin  {Detonate bomb!}
         SoundAdd (1,#$60+#1+#$50+#1+#$40+#1+#$30+#1+#$20+#1+#$10+#1);
         DoArea (X,Y,1);
         end
      else if (Intel=0) then begin
         TempX := X;
         TempY := Y;
         KillObj (N);
         DoArea (TempX,TempY,2);
         end
      else if (Intel mod 2) = 0 then
         SoundAdd (1,#$f8+#1)
      else
         SoundAdd (1,#$f5+#1);
      end
   end; end;

procedure TouchBomb (X,Y,P:integer; var Dx,Dy:integer);
begin with U,Objs [ObjAt (X,Y)] do begin
   if Intel = 0 then begin
      Intel := 9;
      DrawCell (X,Y);
      PutBotMsg (200,'Bomb activated!');
      SoundAdd (4,#$30+#1+#$35+#1+#$40+#1+#$45+#1+#$50+#1);
      end
   else
      Push (X,Y,Dx,Dy);
   end; end;

procedure PushThruXPorter (X,Y,Dx,Dy:integer);
{}
{Push object at x,y into xporter at x+dx,y+dy}
{}
var
   NewX, NewY,
   DestX,DestY:integer;
   TempObj:    integer;
   Done,PastX: boolean;
begin with U,Objs [ObjAt (X+Dx,Y+Dy)] do begin
   if (Dx=Xd) and (Dy=Yd) then begin
      NewX  := X; NewY := Y; {Y=Objs[XPorter].Y, not passed parameter Y}
      DestX := -1;
      Done  := false;
      PastX := true;
      repeat
         NewX := NewX + Dx; NewY := NewY + Dy;
         with Board [NewX,NewY] do begin
            if Kind=Bound then
               Done := true
            else if PastX then begin
               PastX := false;
               if not Info [Kind].GoThru then
                  Push (NewX,NewY,Dx,Dy);
               if Info [Kind].GoThru then begin
                  Done  := true;
                  DestX := NewX; DestY := NewY;
                  end
               else
                  DestX := -1
               end;
            if (Kind=XPorter) then begin
               TempObj := ObjAt (NewX,NewY);
               if (Objs[TempObj].Xd=-Dx) and (Objs[TempObj].Yd=-Dy) then
                  PastX := true
               end;
            end;
         until Done;
      if (DestX<>-1) then begin
         MoveTo (X-Dx,Y-Dy,DestX,DestY);
         SoundAdd (3,#$30+#1+#$42+#1+#$34+#1+#$46+#1+#$38+#1+#$4a+#1+
            #$40+#1+#$52+#1);
         end;
      end;
   end; end;

procedure TouchXPorter (X,Y,P:integer; var Dx,Dy:integer);
begin
   PushThruXPorter (X-Dx,Y-Dy,Dx,Dy);
   Dx := 0; Dy := 0;
   end;

procedure UpdXPorter (N:integer);
begin with U,Objs[N] do begin
   DrawCell (X,Y);
   end; end;

procedure PrintXPorter (X,Y:integer; var C:char);
const
   HStr:string='^~^-v_v-';
   VStr:string='(<('+#$b3+')>)'+#$b3;
begin with U,Objs [ObjAt (X,Y)] do begin
   if Xd=0 then
      C := HStr [yd*2+3+((Counter div Cycle)mod 4)]
   else
      C := VStr [xd*2+3+((Counter div Cycle)mod 4)];
   end; end;

procedure PrintSBomb (X,Y:integer; var C:char);
const
   Str:string = #$b3+'/'+#$c4+'\';
begin with U do begin
   C := Str [1+(Counter mod 4)];
   Board [X,Y].Color := Board [X,Y].Color + 1;
   if Board [X,Y].Color > $0f then
      Board [X,Y].Color := $09;
   end; end;

procedure UpdSBomb (N:integer);
begin with U,Objs [N] do begin
   Rate := Rate - 1;
   if Rate <= 0 then begin
      KillObj (N);
      end
   else if (Rate mod 2)=0 then begin
      SeekPlayer (X,Y,Xd,Yd);
      with Board [X+Xd,Y+Yd] do begin
         if (Kind=Player) or (Kind=BreakWall) then
            ZapWith (N,X+Xd,Y+Yd)
         else begin
            if not Info [Kind].GoThru then
               Push (X+Xd,Y+Yd,Xd,Yd);
            if (Info [Kind].GoThru) or (Kind=Water) then
               MoveObj (N,X+Xd,Y+Yd);
            end;
         end;
      end
   else
      DrawCell (X,Y);
   end; end;

procedure TouchEnergizer (X,Y,P:integer; var Dx,Dy:integer);
begin with U do begin
   SoundAdd (9,
      #$20+#3+#$23+#3+#$24+#3+#$25+#3+#$35+#3+#$25+#3+#$23+#3+#$20+#3+
      #$30+#3+#$23+#3+#$24+#3+#$25+#3+#$35+#3+#$25+#3+#$23+#3+#$20+#3+
      #$30+#3+#$23+#3+#$24+#3+#$25+#3+#$35+#3+#$25+#3+#$23+#3+#$20+#3+
      #$30+#3+#$23+#3+#$24+#3+#$25+#3+#$35+#3+#$25+#3+#$23+#3+#$20+#3+
      #$30+#3+#$23+#3+#$24+#3+#$25+#3+#$35+#3+#$25+#3+#$23+#3+#$20+#3+
      #$30+#3+#$23+#3+#$24+#3+#$25+#3+#$35+#3+#$25+#3+#$23+#3+#$20+#3+
      #$30+#3+#$23+#3+#$24+#3+#$25+#3+#$35+#3+#$25+#3+#$23+#3+#$20+#3);
   Board [X,Y].Kind := Empty;
   DrawCell (X,Y);
   G.I.EnerTime := EnerLife;
   PrintStats;
   if G.First.TouchEner then begin
      PutBotMsg (200,'Energizer - You are invincible');
      G.First.TouchEner := false;
      end;
   if LSendMsg (0,'ALL:ENERGIZE',false) then begin end;
   end; end;

procedure UpdSlime (N:integer);
var
   C,SlimeColor,Num: integer;
   TempX,TempY:      integer;
begin with U,Objs [N] do begin
   if Intel < Rate then begin
      Intel := Intel + 1;
      end
   else begin
      SlimeColor := Board [X,Y].Color;
      Intel := 0;
      TempX := X; TempY := Y; {Byte -> integer}
      Num := 0;
      for C := 0 to 3 do begin
         if Info [Board [TempX+UDLRx[C], TempY+
            UDLRy[C]].Kind].GoThru then begin
            if Num = 0 then begin
               MoveObj (N,TempX+UDLRx[C], TempY+UDLRy[C]);
               Board [TempX, TempY].Color := SlimeColor;
               Board [TempX, TempY].Kind  := BreakWall;
               DrawCell (TempX, TempY);
               end
            else begin
               AddObj (TempX+UDLRx [C],TempY+UDLRy[C],Slime,
                  SlimeColor, Info [Slime].Cycle,NormObj);
               Objs [NumObjs].Rate := Rate;
               end;
            Num := Num + 1;
            end;
         end;
      if Num = 0 then begin {Couldn't move}
         KillObj (N);
         Board [TempX,TempY].Kind  := BreakWall;
         Board [TempX,TempY].Color := SlimeColor;
         DrawCell (TempX,TempY);
         end;
      end;
   end; end;

procedure TouchSlime (X,Y,P:integer; var Dx,Dy:integer);
var
   TempColor:integer;
begin with U do begin
   TempColor := Board [X,Y].Color;
   ZapObj (ObjAt (X,Y));
   Board [X,Y].Kind  := BreakWall;
   Board [X,Y].Color := TempColor;
   DrawCell (X,Y);
   SoundAdd (2,#$20+#1+#$23+#1);
   end; end;

procedure UpdShark (N:integer);
var
   Dx,Dy:integer;
begin with U,Objs [N] do begin
   if Random (10)>Intel then {be dumb}
      PickRandomDir (Dx,Dy)
   else {be smart}
      SeekPlayer (X,Y,Dx,Dy);
   {}
   if Board [X+Dx,Y+Dy].Kind = Water then
      MoveObj (N,X+Dx,Y+Dy)
   else if Board [X+Dx,Y+Dy].Kind = Player then
      ZapWith (N,X+Dx,Y+Dy);
   end; end;

procedure PrintBlinkWall (X,Y:integer; var C:char);
begin
   C := #$ce;
   end;

procedure UpdBlinkWall (N:integer);
var
   TempX, TempY:integer;
   DoneF       :boolean;
   TempObj:     integer;
   WallKind:    integer;
begin with U,Objs [N] do begin
   if Room = 0 then
      Room := Intel + 1;
   if Room = 1 then begin
      TempX := X+Xd; TempY := Y+Yd;
      if Xd <> 0 then
         WallKind := HorizWall
      else
         WallKind := VertWall;
      while (Board [TempX,TempY].Kind = WallKind) and
          (Board [TempX,TempY].Color= Board [X,Y].Color) do begin {undo wall}
          Board [TempX,TempY].Kind := Empty;
          DrawCell (TempX, TempY);
          TempX := TempX + Xd;
          TempY := TempY + Yd;
          Room := Rate*2+1; {Time off}
          end;
       if (TempX=X+Xd) and (TempY=Y+Yd) then begin {turn wall on}
          DoneF := false;
          repeat
             if (Board [TempX,TempY].Kind <> Empty) and
                (Info [Board [TempX,TempY].Kind].Killable) then begin
                Zap (TempX,TempY);
                end;
             if (Board [TempX,TempY].Kind = Player) then begin
                TempObj := ObjAt (TempX,TempY); {Player's object}
                if Xd<>0 then begin
                   if Board [TempX,TempY-1].Kind = Empty then
                      MoveObj (TempObj,TempX,TempY-1)
                   else if Board [TempX,TempY+1].Kind = Empty then
                      MoveObj (TempObj,TempX,TempY+1);
                   end
                else begin
                   if Board [TempX+1,TempY].Kind = Empty then
                      MoveObj (TempObj,TempX+1,TempY)
                   else if Board [TempX-1,TempY].Kind = Empty then
                      MoveObj (TempObj,TempX+1,TempY);
                   end;
                if Board [TempX,TempY].Kind = Player then begin
                   {Really kill player}
                   while G.I.Strength > 0 do begin
                      ZapObj (TempObj);
                      end;
                   DoneF := true;
                   end;
                end;
             if (Board [TempX,TempY].Kind = Empty) then begin
                Board [TempX,TempY].Kind := WallKind;
                Board [TempX,TempY].Color := Board [X,Y].Color;
                DrawCell (TempX,TempY);
                end
             else
                DoneF := true;
             TempX := TempX + Xd;
             TempY := TempY + Yd;
             until DoneF;
          Room := Rate * 2+1;
          end;
       end
   else
      Room := Room - 1;
   end; end;

procedure MoveTo (X1,Y1,X2,Y2:integer);
var
   TempObj:integer;
begin with U do begin
   TempObj := ObjAt (X1,Y1);
   if TempObj >= 0 then
      MoveObj (TempObj,X2,Y2)
   else begin
      Board [X2,Y2] := Board [X1,Y1];
      DrawCell (X2,Y2);
      Board [X1,Y1].Kind  := Empty;
      DrawCell (X1,Y1);
      end;
   end; end;

procedure Push (X,Y,Dx,Dy:integer);
var
   TempObj:integer;
begin with U,Board [X,Y] do begin
   if ((Kind=SliderNS) and (Dx=0)) or
      ((Kind=SliderEW) and (Dy=0)) or
      (Info [Kind].Movable) then begin
      {}
      if Board [X+Dx,Y+Dy].Kind = XPorter then
         PushThruXPorter (X,Y,Dx,Dy)
      else if Board [X+Dx,Y+Dy].Kind <> Empty then
         Push (X+Dx,Y+Dy,Dx,Dy);
      {}
      if (not Info [Board [X+Dx,Y+Dy].Kind].GoThru) and
         (Info [Board [X+Dx,Y+Dy].Kind].Killable) and
         (Board [X+Dx,Y+Dy].Kind <> Player) then
         Zap (X+Dx,Y+Dy);
      {}
      if (Info [Board [X+Dx,Y+Dy].Kind].GoThru) then begin
         MoveTo (X,Y,X+Dx,Y+Dy);
         end;
      end;
   end; end;


procedure PrintDuper (X,Y:integer; var C:char);
begin with U,Objs [ObjAt (X,Y)] do begin
   case Intel of
      1: C := #$fa;
      2: C := #$f9;
      3: C := #$f8;
      4: C := 'o';
      5: C := 'O';
      else
         C := #$fa;
      end;
   end; end;

procedure UpdProg (N:integer);
var
   TempFlag: boolean;
begin with U,Objs [N] do begin
   if (Offset >= 0) then begin
      ExecObj (N,Offset,'Interaction');
      end;
   if (Xd<>0) or (Yd<>0) then begin
      if Info [Board [X+Xd,Y+Yd].Kind].GoThru then
         MoveObj (N,X+Xd,Y+Yd)
      else
         TempFlag := LSendMsg (-N,'THUD',false);
      end;
   end; end;

procedure PrintProg (X,Y:integer; var C:char);
begin
   C := chr (U.Objs [ObjAt (X,Y)].Intel);
   end;

procedure TouchProg (X,Y,P:integer; var Dx,Dy:integer);
var
   N:integer;
   TempFlag:boolean;
begin
   N := ObjAt (X,Y);
   TempFlag := LSendMsg (-N, 'TOUCH',false);
   end;

procedure UpdDuper (N:integer);
var
   TempObj:integer;
{}
{ Character swapping may cause display inconsistency in some }
{ cases, but is mostly unavoidable }
{}
begin with U,Objs [N] do begin
   if Intel <= 4 then begin
      Intel := Intel+1;
      DrawCell (X,Y);
      end
   else begin
      Intel := 0;
      if Board [X-Xd,Y-Yd].Kind = Player then
         Info [Board [X+Xd,Y+Yd].Kind].Touch (X+Xd,Y+Yd,0,Dx1,Dy1)
      else begin
         if Board [X-Xd,Y-Yd].Kind <> Empty then
            Push (X-Xd,Y-Yd,-Xd,-Yd);
         if Board [X-Xd,Y-Yd].Kind = Empty then begin
            TempObj := ObjAt (X+Xd,Y+Yd);
            if (TempObj > 0) then begin
               if NumObjs < (MaxObjs+24) then begin
                  AddObj (X-Xd,Y-Yd,Board [X+Xd,Y+Yd].Kind,
                     Board [X+Xd,Y+Yd].Color, Objs [TempObj].Cycle,
                     Objs [TempObj]);
                  DrawCell (X-Xd,Y-Yd);
                  end;
               end
            else if (TempObj <> 0) then begin
               Board [X-Xd,Y-Yd] := Board [X+Xd,Y+Yd];
               DrawCell (X-Xd,Y-Yd);
               end;
            SoundAdd (3,#$30+#2+#$32+#2+#$34+#2+#$35+#2+#$37+#2);
            end
         else
            SoundAdd (3,#$18+#1+#$16+#1);
         end;
      Intel := 0;
      DrawCell (X,Y);
      end;
   Cycle := (9-Rate)*3; {Duplication rate, 3-27}
   end; end;

procedure UpdScroll (N:integer);
begin with U,Objs [N] do begin
   Board [X,Y].Color := Board [X,Y].Color + 1;
   if Board [X,Y].Color > $0f then
      Board [X,Y].Color := $09;
   DrawCell (X,Y);
   end; end;

procedure TouchScroll (X,Y,P:integer; var Dx,Dy:integer);
var
   S:      ScrollType;
   N:      integer;
   TempFlag:boolean;
begin
   N := ObjAt (X,Y);
   with U,Objs [N] do begin
      S.PickFlag := false;
      S.Cur      := 1;
      SoundAdd (2,Music ('c-c+d-d+e-e+f-f+g-g'));
      Offset := 0;
      ExecObj (N,Offset,'Scroll');
      end;
   KillObj (ObjAt (X,Y)); {May have changed}
   end;


procedure TouchKey (X,Y,P:integer; var Dx,Dy:integer);
var
   D:integer;
begin with U do begin
   D := Board [X,Y].Color mod $8;
   if G.I.Keys [D] then begin
      PutBotMsg (200,'You already have a '+Colors [D]+' key!');
      SoundAdd (2,#$30+#2+#$20+#2);
      end
   else begin
      G.I.Keys [D] := true;
      Board [X,Y].Kind := Empty;
      PrintStats;
      PutBotMsg (200,'You now have the '+Colors[D]+' key.');
      SoundAdd (2,#$40+#1+#$44+#1+#$47+#1+
                  #$40+#1+#$44+#1+#$47+#1+
                  #$40+#1+#$44+#1+#$47+#1+#$50+#2)
      end;
   end; end;

procedure TouchAmmo (X,Y,P:integer; var Dx,Dy:integer);
begin with U do begin
   G.I.Ammo := G.I.Ammo + 5;
   Board [X,Y].Kind := Empty;
   PrintStats;
   SoundAdd (2,#$30+#1+#$31+#1+#$32+#1);
   if G.First.GotAmmo then begin
      G.First.GotAmmo := false;
      PutBotMsg (200,'Ammunition - 5 shots per container.');
      end;
   end; end;

procedure TouchGem (X,Y,P:integer; var Dx,Dy:integer);
begin with G,I do begin
   Gems     := Gems + 1;
   Strength := Strength + 1;
   Score    := Score+ 10;
   U.Board [X,Y].Kind := Empty;
   PrintStats;
   SoundAdd (2,#$40+#1+#$37+#1+#$34+#1+#$30+#1);
   if First.GotGem then begin
      First.GotGem := false;
      PutBotMsg (200,'Gems give you Health!');
      end;
   end; end;

procedure TouchPassage (X,Y,P:integer; var Dx,Dy:integer);
begin with U do begin
   EnterPassage (X,Y);
   Dx := 0; Dy := 0;
   end; end;

procedure TouchDoor (X,Y,P:integer; var Dx,Dy:integer);
var
   D:integer;
begin with U do begin
   D := (Board [X,Y].Color div $10) mod $8;
   if G.I.Keys [D] then begin
      { Open door - remove it }
      Board [X,Y].Kind := Empty;
      DrawCell (X,Y);
      G.I.Keys [D] := false;
      PrintStats;
      PutBotMsg (200,'The '+Colors[D]+' door is now open.');
      SoundAdd (3,#$30+#1+#$37+#1+#$3b+#1+
                  #$30+#1+#$37+#1+#$3b+#1+#$40+#4);
      end
   else begin {Can not go thru - do not have key }
      PutBotMsg (200,'The '+Colors[D]+' door is locked!');
      SoundAdd (3,#$17+#1+#$10+#1);
      end;
   end; end;

procedure TouchPush (X,Y,P:integer; var Dx,Dy:integer);
begin
   Push (X,Y,Dx,Dy);
   SoundAdd (2,#$15+#1);
   end;

procedure PrintPusher (X,Y:integer; var C:char);
begin with U,Objs [ObjAt (X,Y)] do begin
   if Xd=1 then
      C := #$10
   else if Xd=-1 then
      C := #$11
   else if Yd=-1 then
      C := #$1e
   else
      C := #$1f;
   end; end;

procedure UpdPusher (N:integer);
var
   TempObj:integer;
   TempX,TempY:integer;
begin with U do begin
   with Objs [N] do begin
      TempX := X; TempY := Y;
      if not Info [Board [X+Xd,Y+Yd].Kind].GoThru then begin
         Push (X+Xd,Y+Yd,Xd,Yd);
         end;
      end;
   N := ObjAt (TempX, TempY); {May change}
   with Objs [N] do begin
      if Info [Board [X+Xd,Y+Yd].Kind].GoThru then begin
         MoveObj (N,X+Xd,Y+Yd);
         SoundAdd (2,#$15+#1);
         if Board [X-Xd*2,Y-Yd*2].Kind = Pusher then begin
            TempObj := ObjAt (X-Xd*2,Y-Yd*2);
            if (Objs [TempObj].Xd = Xd) and (Objs [TempObj].Yd = Yd) then
               Info [Pusher].Update (TempObj);
            end;
         end;
      end;
   end; end;

procedure TouchTorch (X,Y,P:integer; var Dx,Dy:integer);
begin
   G.I.Torches := G.I.Torches + 1;
   U.Board [X,Y].Kind := Empty;
   DrawCell (X,Y);
   PrintStats;
   if G.First.GotTorch then
      PutBotMsg (200,'Torch - used for lighting in the underground.');
   G.First.GotTorch := false;
   SoundAdd (3,#$30+#1+#$39+#1+#$34+#2);
   end;

procedure TouchInvisoWall (X,Y,P:integer; var Dx,Dy:integer);
begin with U,Board [X,Y] do begin
   Kind := NormWall;
   DrawCell (X,Y);
   SoundAdd (3,#$12+#1+#$10+#1);
   PutBotMsg (100,'You are blocked by an invisible wall.');
   end; end;

procedure TouchBrush (X,Y,P:integer; var Dx,Dy:integer);
begin with U do begin
   Board [X,Y].Kind := Empty;
   DrawCell (X,Y);
   SoundAdd (3,#$39+#1);
   if G.First.MakePath then
      PutBotMsg (200,'A path is cleared through the forest.');
   G.First.MakePath := false;
   end; end;

procedure TouchFakeWall (X,Y,P:integer; var Dx,Dy:integer);
begin
   if G.First.TouchFake then
      PutBotMsg (150,'A fake wall - secret passage!');
   G.First.TouchFake := false;
   end;

procedure TouchBound (X,Y,P:integer; var Dx,Dy:integer);
var
   RoomDir:integer;
   OldRoom:integer;
   NewX,NewY:integer;
begin with U do begin
   NewX := Objs [0].X; NewY := Objs [0].Y;
   if Dy=-1 then begin
      RoomDir := 0; {Up}
      NewY    :=Ys;
      end
   else if Dy = 1 then begin
      RoomDir := 1; {Down}
      NewY    := 1;
      end
   else if Dx = -1 then begin
      RoomDir := 2; {Left}
      NewX    := Xs;
      end
   else begin
      RoomDir := 3; {Right}
      NewX    := 1;
      end;
   if U.RoomInfo.RoomUDLR [RoomDir] <> 0 then begin
      OldRoom := G.I.Room;
      SwitchRooms (U.RoomInfo.RoomUDLR [RoomDir]);
      if (Board [NewX,NewY].Kind<>Player) then
         Info [Board [NewX,NewY].Kind].Touch (NewX,NewY,P,Dx1,Dy1);
      if (Info [Board [NewX,NewY].Kind].GoThru) or
         (Board [NewX,NewY].Kind=Player) then begin
         if Board [NewX,NewY].Kind<>Player then
            MoveObj (0,NewX,NewY);
         PDrawBoard;
         Dx := 0; Dy := 0;
         NoteEnterNewRoom;
         end
      else begin
         SwitchRooms (OldRoom);
         end;
      end;
   end; end;

procedure TouchWater (X,Y,P:integer; var Dx,Dy:integer);
begin
   SoundAdd (3,#$40+#1+#$50+#1);
   PutBotMsg (100,'Your way is blocked by water.');
   end;

procedure DoArea (Xc,Yc:integer; Code:integer);
var
   TempX, TempY,TempInt:integer;
   TempFlag:            boolean;
begin with U do begin
   for TempX := Xc-TorchXs-1 to Xc+TorchXs+1 do if
      (TempX>=1) and (TempX <= Xs) then begin
      {}
      for TempY := Yc-TorchYs-1 to Yc+TorchYs+1 do if
         (TempY>=1) and (TempY <= Ys) then
         with Board [TempX,TempY] do begin
         {}
         if (Code>0)and((sqr(TempX-Xc)+2*sqr(TempY-Yc))<TorchSize) then begin
            if Code=1 then begin
               if Info [Kind].MsgScroll<>'' then begin
                  TempInt := ObjAt (TempX,TempY);
                  if (TempInt>0) then
                     TempFlag := LSendMsg (-TempInt, 'BOMBED',false);
                  end;
               if (Info [Kind].Killable) or (Kind=SBomb) then
                  Zap (TempX,TempY);
               if (Kind = Empty) or (Kind = BreakWall) then begin
                  Kind  := BreakWall;
                  Color := random (7)+9;
                  DrawCell (TempX,TempY);
                  end;
               end
            else begin
               if Kind=BreakWall then begin
                  Kind := Empty;
                  end;
               end;
            end;
         DrawCell (TempX,TempY);
         end;
      end;
   end; end;

procedure AskQuitGame;
begin
   if G.I.Strength <= 0 then begin
      Done := true;
      DrawBox;
      end
   else begin
      Done := InYN ('End this game? ',true);
      if Key=Escape then
         Done := false;
      end;
   Key := #0;
   end;

procedure UpdPlayer (N:integer);
var
   TempX, TempY:integer;
   Flag:        boolean;
   C,D:         integer;
   {}
begin with U,Objs [N] do begin
   {}
   if (G.I.EnerTime > 0) then begin
      if Info [Player].Ch = #$02 then
         Info [Player].Ch := #$01
      else
         Info [Player].Ch := #$02;
      {}
      if (Counter mod 2)<>0 then
         Board [X,Y].Color := $0f
      else
         Board [X,Y].Color := $0f+$10*((Counter mod 7)+1);
      DrawCell (X,Y);
      end
   else if (Board [X,Y].Color <> $1f) or (Info [Player].Ch <> #$02) then begin
      Board [X,Y].Color := $1f;
      Info [Player].Ch := #$02;
      DrawCell (X,Y);
      end;
   {}
   if G.I.Strength <= 0 then begin
      Dx1 := 0; Dy1 := 0; Fire1 := false;
      if ObjAt (0,0)=-1 then
         PutBotMsg (32000,' Game over  -  Press ESCAPE');
      GameCycle := 0;
      SoundOff  := true;
      end;
   {}
   if (Fire1) then begin
      if (Dx1<>0) or (Dy1<>0) then begin
         if RoomInfo.CanShoot=0 then begin
            if G.First.CantShootHere then
               PutBotMsg (200,'Can''t shoot in this place!');
            G.First.CantShootHere := false;
            end
         else if G.I.Ammo = 0 then begin
            if G.First.NoAmmo then
               PutBotMsg (200,'You don''t have any ammo!');
            G.First.NoAmmo := false;
            end
         else begin
            D := 0;
            for C := 0 to NumObjs do begin
               if (Board [Objs[C].X,Objs[C].Y].Kind=Bullet) and
                  (Objs[C].Intel=0) then
                  D := D + 1;
               end;
            if (D<U.RoomInfo.CanShoot) and
               TryFire (Bullet,X,Y,Dx1,Dy1,0) then begin
               G.I.Ammo := G.I.Ammo - 1;
               PrintStats;
               SoundAdd (2,#$40+#1+#$30+#1+#$20+#1);
               Dx1 := 0; Dy1 := 0;
               end;
            end;
         end;
      end
   {}
   else if (Dx1<>0) or (Dy1<>0) then begin
      Info [Board [X+Dx1,Y+Dy1].Kind].Touch (X+Dx1,Y+Dy1,0,Dx1,Dy1);
      if (Dx1<>0) or (Dy1<>0) then begin
         if SoundF and not MakeSound then
            Sound (110);
         if Info [Board [X+Dx1,Y+Dy1].Kind].GoThru then begin
            if SoundF and not MakeSound then
               NoSound;
            MoveObj (0,X+Dx1, Y+Dy1);
            end
         else if SoundF and not MakeSound then
            NoSound;
         end;
      end;
   {}
   case Upcase (Key) of
      'T': if G.I.TorchTime <= 0 then begin
         if (G.I.Torches > 0) then begin
            if RoomInfo.IsDark then begin
               G.I.Torches   := G.I.Torches - 1;
               G.I.TorchTime := TorchLife;
               DoArea (X,Y,0);
               PrintStats;
               end
            else if G.First.DontNeedTorch then begin
               PutBotMsg (200,'Don''t need torch - room is not dark!');
               G.First.DontNeedTorch := false;
               end;
            end
         else if G.First.NoTorch then begin
            PutBotMsg (200,'You don''t have any torches!');
            G.First.NoTorch := false;
            end;
         end;
      Escape, 'Q': begin
         AskQuitGame;
         end;
      'S': begin
         DoSave ('Save game:',SaveName,SaveExt);
         end;
      'P': begin
         if (G.I.Strength > 0) then
            StandBy := true;
         end;
      'B': begin
         SoundF := not SoundF;
         SoundStop;
         PrintStats;
         Key := ' ';
         end;
      'H': begin
         ViewDoc ('GAME.HLP','Playing ZZT');
         end;
      'F': begin
         ViewDoc ('ORDER.HLP','Order form');
         end;
      '?': begin
         SecretCmd;
         Key := #0;
         end;
      end;
   if G.I.TorchTime > 0 then begin
      G.I.TorchTime := G.I.TorchTime - 1;
      if G.I.TorchTime <= 0 then begin
         DoArea (X,Y,0);
         SoundAdd (3,#$30+#1+#$20+#1+#$10+#1);
         end;
      if (G.I.TorchTime mod (TorchLife div 5))=0 then
         PrintStats; {Does it when = 0}
      end;
   {}
   if G.I.EnerTime > 0 then begin
      G.I.EnerTime := G.I.EnerTime - 1;
      if G.I.EnerTime = 10 then begin
         SoundAdd (9,#$20+#3+#$1a+#3+#$17+#3+#$16+#3+
                     #$15+#3+#$13+#3+#$10+#3);
         end
      else if G.I.EnerTime <= 0 then begin
         Board [X,Y].Color := Info [Player].Col;
         DrawCell (X,Y);
         end
      end;
   {}
   if (U.RoomInfo.TimeLimit > 0) and (G.I.Strength>0) then begin
      if TimePassed (G.I.LastSec,100) then begin
         G.I.RoomTime := G.I.RoomTime + 1;
         if G.I.RoomTime = (U.RoomInfo.TimeLimit-10) then begin
            PutBotMsg (200,'Running out of time!');
            SoundAdd (3,#$40+#6+#$45+#6+#$40+#6+
                        #$35+#6+#$40+#6+#$45+#6+#$40+#10);
            end
         else if G.I.RoomTime > U.RoomInfo.TimeLimit then begin
            ZapObj (0);
            end;
         PrintStats;
         end;
      end;
   {}
   end; end;

procedure UpdMonitor (N:integer);
begin
   if UpCase (Key) in ['W', 'P', 'A', 'E', 'S', 'R',
      'H', 'N', Escape, 'Q', '|'] then Done := true;
   end;

{$F-}


{}
{ Init table of first-did's for help }
{}
procedure InitFirst;
begin with G.First do begin
   GotAmmo       := true;
   NoAmmo        := true;
   CantShootHere := true;
   GotTorch      := true;
   NoTorch       := true;
   DontNeedTorch := true;
   EnterDark     := true;
   MakePath      := true;
   TouchFake     := true;
   GotGem        := true;
   TouchEner     := true;
   end; end;


{}
{ Info for game }
{}

procedure InitInfo;
var
   C:integer;
begin
   {}
   { Characters & colors that are used as graphics, associated with each }
   { type of item/object that can be on the board }
   { Color - $ff = no default, any color allowed }
   {}
   for C := 0 to NumClasses do with Info [C] do begin
      Ch        := ' ';
      Col       := $ff;
      Killable  := false;
      Movable   := false;
      ShowInDark:= false;
      Terrain   := false;
      GoThru    := false;
      PrintF    := false;
      Cycle     := -1;
      Update    := UpdNothing;
      Print     := PrintNothing;
      Touch     := TouchNothing;
      Category  := 0;
      KeyCode   := #0;
      Descr     := '';
      Heading   := '';
      MsgIntel  := '';
      MsgRate   := '';
      MsgRateH  := '';
      MsgRoom   := '';
      MsgDir    := '';
      MsgScroll := '';
      Score     := 0;
      end;
   {}
   with Info [Empty] do begin {Empty space}
      Ch       := ' ';
      Col      := $70;
      Movable  := true;
      GoThru   := true;
      Descr    := 'Empty';
      end;
   with Info [Monitor] do begin {Game monitor}
      Ch       := ' ';
      Col      := $07;
      Cycle    := 1;
      Update   := UpdMonitor;
      Descr    := 'Monitor';
      end;
   with Info [Water] do begin {Water terrain}
      Ch       := #$b0;
      Col      := $f9;
      Terrain  := true;
      Category := CTerrain;
      Touch    := TouchWater;
      KeyCode  := 'W';
      Descr    := 'Water';
      Heading  := 'Terrains:';
      end;
   with Info [Brush] do begin
      Ch       := #$b0;
      Col      := $20;
      GoThru   := false;
      Touch    := TouchBrush;
      Category := CTerrain;
      KeyCode  := 'F';
      Descr    := 'Forest';
      end;
   with Info [Player] do begin {Smiley}
      Ch        := #$02;
      Col       := $1f;
      Killable  := true;
      Movable   := true;
      ShowInDark:= true;
      Cycle     := 1;
      Update    := UpdPlayer;
      Category  := CItem;
      KeyCode   := 'Z';
      Descr     := 'Player';
      Heading   := 'Items:';
      end;
   with Info [Enemy] do begin {Moving enemy}
      Ch       := #$ea;
      Col      := $0c;
      Killable := true;
      Movable  := true;
      Cycle    := 2;
      Update   := UpdEnemy;
      Touch    := TouchEnemy;
      Category := CCreature;
      KeyCode  := 'L';
      Descr    := 'Lion';
      Heading  := 'Beasts:';
      MsgIntel := 'Intelligence?';
      Score    := 1;
      end;
   with Info [SEnemy] do begin {Shooting enemy}
      Ch       := #$e3;
      Col      := $0b;
      Killable := true;
      Movable  := true;
      Cycle    := 2;
      Update   := UpdSEnemy;
      Touch    := TouchEnemy;
      Category := CCreature;
      KeyCode  := 'T';
      Descr    := 'Tiger';
      MsgIntel := 'Intelligence?';
      MsgRate  := 'Firing rate?';
      MsgRateH := 'Firing type?';
      Score    := 2;
      end;
   with Info [CentiH] do begin {Centipede head segment}
      Ch       := #$e9;
      Killable := true;
      Cycle    := 2;
      Update   := UpdCentiH;
      Touch    := TouchEnemy;
      Category := CCreature;
      KeyCode  := 'H';
      Descr    := 'Head';
      Heading  := 'Centipedes';
      MsgIntel := 'Intelligence?';
      MsgRate  := 'Deviance?';
      Score    := 1;
      end;
   with Info [Centi] do begin {Centipede body segment}
      Ch       := 'O';
      Killable := true;
      Cycle    := 2;
      Update   := UpdCenti;
      Touch    := TouchEnemy;
      Category := CCreature;
      KeyCode  := 'S';
      Descr    := 'Segment';
      Score    := 3;
      end;
   with Info [Bullet] do begin {Normal bullet}
      Ch       := #$f8;
      Col      := $0f;
      Killable := true;
      Cycle    := 1;
      Update   := UpdBullet;
      Touch    := TouchEnemy;
      Descr    := 'Bullet';
      end;
   with Info [SBomb] do begin {Smart bomb}
      Ch       := 'S';
      Col      := $0f;
      KillAble := false;
      Cycle    := 1;
      Update   := UpdSBomb;
      Touch    := TouchEnemy;
      PrintF   := true;
      Print    := PrintSBomb;
      Descr    := 'Star';
      end;
   with Info [AKey] do begin {Key - unlocks color-coded doors}
      Ch       := #$0c;
      Movable  := true;
      Touch    := TouchKey;
      Category := CItem;
      KeyCode  := 'K';
      Descr    := 'Key';
      end;
   with Info [Ammo] do begin {Ammo pile}
      Ch       := #$84;
      Col      := $03;
      Movable  := true;
      Touch    := TouchAmmo;
      Category := CItem;
      KeyCode  := 'A';
      Descr    := 'Ammo';
      end;
   with Info [Gem] do begin
      Ch       := #$04;
      Movable  := true;
      Touch    := TouchGem;
      Killable := true;
      Category := CItem;
      KeyCode  := 'G';
      Descr    := 'Gem';
      end;
   with Info [Passage] do begin {Passage to another room}
      Ch        := #$f0;
      Col       := $fe;
      Cycle     := 0;
      ShowInDark:= true;
      Touch     := TouchPassage;
      Category  := CItem;
      KeyCode   := 'P';
      Descr     := 'Passage';
      MsgRoom   := 'Room thru passage?';
      end;
   with Info [Door] do begin {Door - need keys to unlock}
      Ch       := #$0a;
      Col      := $fe;
      Touch    := TouchDoor;
      Category := CItem;
      KeyCode  := 'D';
      Descr    := 'Door';
      end;
   with Info [Scroll] do begin
      Ch       := #$e8;
      Col      := $0f;
      Touch    := TouchScroll;
      Update   := UpdScroll;
      Movable  := true;
      Cycle    := 1;
      Category := CItem;
      KeyCode  := 'S';
      Descr    := 'Scroll';
      MsgScroll:= 'Edit text of scroll';
      end;
   with Info [Duper] do begin {Duplicator}
      Ch       := #$fa;
      Col      := $0f;
      Cycle    := 2;
      Update   := UpdDuper;
      PrintF   := true;
      Print    := PrintDuper;
      Category := CItem;
      KeyCode  := 'U';
      Descr    := 'Duplicator';
      MsgDir   := 'Source direction?';
      MsgRate  := 'Duplication rate?;SF';
      end;
   with Info [Torch] do begin
      Ch        := #$9d;
      Col       := $06;
      ShowInDark:= true;
      Touch     := TouchTorch;
      Category  := CItem;
      KeyCode   := 'T';
      Descr     := 'Torch';
      end;
   with Info [Shooter] do begin {Spinning shooter}
      Ch       := #$18;
      Cycle    := 2;
      Update   := UpdShooter;
      PrintF   := true;
      Print    := PrintShooter;
      Category := CCreature;
      KeyCode  := 'G';
      Descr    := 'Spinning gun';
      MsgIntel := 'Intelligence?';
      MsgRate  := 'Firing rate?';
      MsgRateH := 'Firing type?';
      end;
   with Info [Wanderer] do begin {Intermittent walker}
      Ch       := #$05;
      Col      := $0d;
      KillAble := true;
      Movable  := true;
      Cycle    := 1;
      Update   := UpdWanderer;
      Touch    := TouchEnemy;
      Category := CCreature;
      KeyCode  := 'R';
      Descr    := 'Ruffian';
      MsgIntel := 'Intelligence?';
      MsgRate  := 'Resting time?';
      Score    := 2;
      end;
   with Info [Chaser] do begin {Seeks player, can zap walls}
      Ch       := #$99;
      Col      := $06;
      KillAble := true;
      Movable  := true;
      Cycle    := 3;
      Update   := UpdChaser;
      Touch    := TouchEnemy;
      Category := CCreature;
      KeyCode  := 'B';
      Descr    := 'Bear';
      Heading  := 'Creatures:';
      MsgIntel := 'Sensitivity?';
      Score    := 1;
      end;
   with Info [Slime] do begin
      Ch       := '*';
      Col      := $ff;
      Killable := false;
      Cycle    := 3;
      Update   := UpdSlime;
      Touch    := TouchSlime;
      Category := CCreature;
      KeyCode  := 'V';
      Descr    := 'Slime';
      MsgRate  := 'Movement speed?;FS';
      end;
   with Info [Shark] do begin
      Ch       := '^';
      Col      := $07;
      Killable := false;
      Cycle    := 3;
      Update   := UpdShark;
      Category := CCreature;
      KeyCode  := 'Y';
      Descr    := 'Shark';
      MsgIntel := 'Intelligence?';
      end;
   with Info [ConveyorCW] do begin
      Ch       := '/';
      Cycle    := 3;
      PrintF   := true;
      Update   := UpdConveyorCW;
      Print    := PrintConveyorCW;
      Category := CItem;
      KeyCode  := '1';
      Descr    := 'Clockwise';
      Heading  := 'Conveyors:';
      end;
   with Info [ConveyorCCW] do begin
      Ch       := '\';
      Cycle    := 2;
      PrintF   := true;
      Print    := PrintConveyorCCW;
      Update   := UpdConveyorCCW;
      Category := CItem;
      KeyCode  := '2';
      Descr    := 'Counter';
      end;
   {}
   with Info [SolidWall] do begin {Solid, indestructable wall}
      Ch       := #$db;
      Category := CTerrain;
      Heading  := 'Walls:';
      KeyCode  := 'S';
      Descr    := 'Solid';
      end;
   with Info [NormWall] do begin {Patterned, indestructable wall}
      Ch       := #$b2;
      Category := CTerrain;
      KeyCode  := 'N';
      Descr    := 'Normal';
      end;
   with Info [Line2] do begin
      Ch       := #206;
      PrintF   := true;
      Print    := PrintLine2;
      Descr    := 'Line'
      end;
   with Info [VertWall] do begin {Solid, indestructable wall}
      Ch       := #$ba;
      end;
   with Info [HorizWall] do begin {Patterned, indestructable wall}
      Ch       := #$cd;
      end;
   with Info [Ricochet] do begin
      Ch       := #$2a;
      Col      := $0a;
      Category := CTerrain;
      KeyCode  := 'R';
      Descr    := 'Ricochet';
      end;
   with Info [BreakWall] do begin {Shootable wall}
      Ch       := #$b1;
      KillAble := false; {Only shootable, not killable}
      Category := CTerrain;
      KeyCode  := 'B';
      Descr    := 'Breakable';
      end;
   with Info [Block] do begin {Movable-pushable wall}
      Ch       := #$fe;
      Movable  := true;
      Touch    := TouchPush;
      Category := CTerrain;
      KeyCode  := 'O';
      Descr    := 'Boulder';
      end;
   with Info [SliderNS] do begin
      Ch       := #$12;
      Touch    := TouchPush;
      Category := CTerrain;
      KeyCode  := '1';
      Descr    := 'Slider (NS)';
      end;
   with Info [SliderEW] do begin
      Ch       := #$1d;
      Touch    := TouchPush;
      Category := CTerrain;
      KeyCode  := '2';
      Descr    := 'Slider (EW)';
      end;
   {}
   with Info [XPorter] do begin
      Ch       := #$c5;
      Touch    := TouchXporter;
      PrintF   := true;
      Print    := PrintXPorter;
      Cycle    := 2;
      Update   := UpdXPorter;
      Category := CTerrain;
      KeyCode  := 'T';
      Descr    := 'Transporter';
      MsgDir   := 'Direction?';
      end;
   {}
   with Info [Pusher] do begin {Pusher}
      Ch       := #$10;
      Col      := $ff;
      PrintF   := true;
      Print    := PrintPusher;
      Cycle    := 4;
      Update   := UpdPusher;
      Category := CCreature;
      KeyCode  := 'P';
      Descr    := 'Pusher';
      MsgDir   := 'Push direction?';
      end;
   {}
   with Info [Bomb] do begin
      Ch       := #$0b;
      PrintF   := true;
      Print    := PrintBomb;
      Movable  := true;
      Cycle    := 6;
      Update   := UpdBomb;
      Touch    := TouchBomb;
      Category := CItem;
      KeyCode  := 'B';
      Descr    := 'Bomb';
      end;
   {}
   with Info [Energizer] do begin
      Ch       := #$7f;
      Col      := $05;
      Touch    := TouchEnergizer;
      Category := CItem;
      KeyCode  := 'E';
      Descr    := 'Energizer';
      end;
   {}
   with Info [BlinkWall] do begin
      Ch       := #$ce;
      Cycle    := 1;
      Update   := UpdBlinkWall;
      PrintF   := true;
      Print    := PrintBlinkWall;
      Category := CTerrain;
      KeyCode  := 'L';
      Descr    := 'Blink wall';
      MsgIntel := 'Starting time';
      MsgRate  := 'Period';
      MsgDir   := 'Wall direction';
      end;
   {}
   with Info [FakeWall] do begin
      Ch       := #$b2;
      Category := CTerrain;
      Terrain  := true;
      GoThru   := true;
      Touch    := TouchFakeWall;
      KeyCode  := 'A';
      Descr    := 'Fake';
      end;
   {}
   with Info [InvisoWall] do begin
      Ch       := ' ';
      Category := CTerrain;
      Touch    := TouchInvisoWall;
      KeyCode  := 'I';
      Descr    := 'Invisible';
      end;
   {}
   with Info [Prog] do begin
      Ch       := #$02;
      Category := CCreature;
      Cycle    := 3;
      PrintF   := true;
      Print    := PrintProg;
      Update   := UpdProg;
      Touch    := TouchProg;
      KeyCode  := 'O';
      Descr    := 'Object';
      MsgIntel := 'Character?';
      MsgScroll:= 'Edit Program';
      end;
   {}
   with Info [Special] do begin
      Update := UpdSpecial;
      end;
   {}
   with Info [Bound] do begin
      Touch  := TouchBound;
      end;
   {}
   NumPats := 5;
   Pats [1] := SolidWall;
   Pats [2] := NormWall;
   Pats [3] := BreakWall;
   Pats [4] := Empty;
   Pats [5] := Line2;
   end;

procedure InitInfoEdit;
{}
{ InitInfo especially for editor }
{}
begin
   InitInfo;
   Info [InvisoWall].Ch  := #$b0;
   Info [InvisoWall].Col := $ff;
   EdFlag := true;
   end;

procedure InitInfoPlay;
{}
{ InitInfo especially for playing game }
{}
begin
   InitInfo;
   EdFlag := false;
   end;

procedure InitDef;
{}
{ Init G.I.Def defaults }
{}
var
   C:integer;
begin with G do begin
   for C := 0 to NumClasses do with Def [C] do begin
      Intel := 4;
      Rate  := 4;
      Room  := 0;
      Xd    := 0;
      Yd    := -1;
      end;
   Def [Prog].Intel := 1; {Character=smiley}
   Def [Chaser].Intel := 8; {Sensitivity}
   end; end;

begin
   end.

