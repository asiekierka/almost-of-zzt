unit glob;

interface

uses
   FastWr, Crt, Dos, Keyboard, SoundU,
   GameCtrl,
   Scrolls;

const
   GameTitle   = 'ZZT';
   WorldExt    = '.ZZT';
   SaveExt     = '.SAV';
   {}
   { Categories - 0=no category }
   {}
   CItem     = 1;
   CCreature = 2;
   CTerrain  = 3;
   {}
   {  All things that can be on the board - objects, items, walls, etc }
   {}
   Empty     = 0; {Misc}
   Bound     = 1;
   Special   = 2;
   Monitor   = 3;
   {}
   Player    = 4; {}{Items}
   Ammo      = 5; {}
   Torch     = 6; {}
   Gem       = 7; {}
   AKey      = 8; {}
   Door      = 9; {}
   Scroll    = 10;{}
   Passage   = 11;{}
   Duper     = 12;{}
   Bomb      = 13;{}
   Energizer = 14;{}
   SBomb     = 15;{Unlisted}
   ConveyorCW= 16;{}
   ConveyorCCW=17;{}
   Bullet    = 18;{}
   {}
   Water     = 19; {}{Terrains}
   Brush     = 20; {}
   Solidwall = 21; {}
   NormWall  = 22; {}
   BreakWall = 23; {}
   Block     = 24; {}
   SliderNS  = 25; {}
   SliderEW  = 26; {}
   FakeWall  = 27; {}
   InvisoWall= 28; {}
   BlinkWall = 29; {}
   Xporter   = 30; {}
   Line2     = 31; {}
   Ricochet  = 32; {}
   HorizWall = 33; {}
   {}
   Chaser    = 34; {Bad guys}
   Wanderer  = 35; {}
   Prog      = 36; {}
   Slime     = 37; {}
   Shark     = 38; {}
   Shooter   = 39; {}
   Pusher    = 40; {}
   Enemy     = 41; {}
   SEnemy    = 42; {}
   VertWall  = 43;
   CentiH    = 44; {}
   Centi     = 45; {}
   {}
   xxx1      = 46; {}
   {}
   TextCol   = 47;
   {}
   NumTextCols = 6; {1 to 7}
   {}
   NumClasses= TextCol+NumTextCols;
   {}
   Xs      = 60;  {X & Y dimentions of board}
   Ys      = 25;
   {}
   MaxXYs  = 2000; {Should just be (Xs+2) * (Ys+2)}
   {}
   MaxObjs = 150;  {Maximum number of objects allowed on board}
   MaxRooms= 100;  {Maximum number of rooms allowed in game world}
   NumFlags= 10;   {Number of ZZT-OOP flags}
   NumHi   = 30;   {Number of high scores to track}
   {}
   TempHeapSize = 20000; {At all times, have a temporary 20k buffer on hand}
   HeaderLen = 512; {Size of game world file's header}
   {}
   Colors: array [1..7] of String [8] =
      ('Blue','Green','Cyan','Red',       {Color names}
       'Purple','Yellow','White');
   {}
   TorchXS   = 8;     {Torch X-radius}
   TorchYS   = 5;     {Torch Y-radius}
   TorchSize = 50;    {Lesser of Xs^2, 2*Ys^2}
   TorchLife = 200;   {# of moves torch lasts without going out}
   EnerLife  = 75;    {# of moves energizer can go}
   {}
   ClockX: array [0..7] of integer = (-1,0,1,1,1,0,-1,-1); {Clockwise}
   ClockY: array [0..7] of integer = (1,1,1,0,-1,-1,-1,0); {Directions}
   {}
   UDLRx:  array [0..3] of integer = (0,0,-1,1); {Up-Down-Left-Right}
   UDLRy:  array [0..3] of integer = (-1,1,0,0); {directions}
   {}
   Spaces  = #$b3+'                   '; {Lots of spaces}

type
   {}
   { General purpose "screen coordinate" type for splotch}
   {}
   Coord= record
      X,Y: integer;
      end;
   {}
   { The playing board - definition of each cell }
   {}
   BoardCell = record
      Kind: byte;
      Color:byte;
      end;
   {}
   { The board - definition of whole thing;  Outer rows are always walls }
   {}
   BoardType= array [0..Xs+1,0..Ys+1] of BoardCell;
   {}
   { InfoType - building blocks of game, info about every abstract item }
   {}
   InfoType = record
      Ch:       char;
      Col:      byte;
         { Standard color, or }
         { $ff = selected color in foreground, on black }
         { $fe = selected color in background, with white }
      KillAble: boolean;  {Can we shoot it}
      Movable:  boolean;  {Can it be PUSHED by conveyor, block...?}
      ShowInDark:boolean; {Does it appear in dark rooms?}
      Terrain:  boolean;
      GoThru:   boolean;  {Can player go thru it?}
      PrintF:   boolean;
      Print:    procedure (X,Y:integer; var C:char);
                          {Special routine to print if Ch = SpecialPrint}
      Cycle:    integer;  {-1: not object, 0: no updates, >0 update}
      Update:   procedure (N:  integer);
      Touch:    procedure (X,Y,P:integer; var Dx,Dy:integer);
      Category: integer;      {Category for editor}
      Keycode:  char;         {Keystroke for editor}
      Descr:    string [20];  {Description for editor}
      Heading:  string [20];  {Optional heading for editor}
      MsgIntel,
      MsgRate,
      MsgRateH,
      MsgRoom,
      MsgDir,
      MsgScroll:string [20];  {Various messages for editor}
      Score:    integer;      {Score for shooting}
      end;
   {}
   { ObjType: characteristics of each individual object }
   {}
   ObjType = record
      X,Y:    byte; {Coordinates of object on screen, or Y=0 special code:}
                    {X=0: Bottom message flashing (Rate)}
      Xd,Yd:  integer;
      Cycle:  integer; {# of clock cycles before update}
      Intel:  byte;    {inteligence -cent/en/sen}
      Rate:   byte;    {firing rate-shoot/ lifetime-botmsg-cent /deviance-cent}
      Room:   byte;    {room number through passage}
      Child:  integer; {Chains of centipedes}
      Parent: integer;
      Under:  BoardCell;
      Inside: Pointer;
      Offset: integer; {Offset pointer to Inside}
      InsideLen:integer; {Signed!}
      XPad:   array [1..8] of byte;
      end;
   {}
   { ObjArray - array of all objects in a game, 0=player}
   {}
   ObjArray = array [0..MaxObjs+1] of ObjType;
   {}
   { RoomInfoType - holds information about room - darkness, etc. }
   {}
   RoomInfoType = record
      CanShoot: byte;
      {CanShoot: boolean;} {Shooting allowed in room?}
      IsDark:   boolean; {Room is dark - torch required}
      RoomUDLR: array [0..3] of byte; {Rooms up, down, ...}
      ReEnter:  boolean; {Re-enter room upon being zapped}
      BotMsg:   string [XS-2]; {Flashing msg. at bottom of screen...}
      StartX,
      StartY:   byte;  {Location of entry into room}
      TimeLimit:integer;
      YPad:     array [1..16] of byte;
      end;
   {}
   { RoomType - holds all variables related to current in-use room. }
   {}
   RoomType = record
      Title:    OurString;
      Board:    BoardType; {Contents of playing board}
      NumObjs:  integer;
      Objs:     ObjArray; {Objects in game}
      RoomInfo: RoomInfoType;
      end;
   {}
   { Player's inventory }
   {}
   InvType = record
      Ammo:     integer;
      Gems:     integer;
      Keys:     array [1..7] of boolean;
      Strength: integer;
      Room:     integer; {Current room #}
      Torches:  integer;
      TorchTime:integer;
      EnerTime: integer;
      InvisoTime:integer; {}
      Score:    integer;
      OrigName: string [20];
      Flags:    array [1..NumFlags] of String [20];
      RoomTime: integer; {Amt. of time in room}
      LastSec:  word;    {Used for room-timer}
      PlayFlag: boolean; {Has game been played since edit?}
      WPad:     array [1..14] of byte;
      end;
   {}
   { Is this the first time the user has ... ? }
   { Used for bottom help messages }
   {}
   FirstType = record
      GotAmmo,
      NoAmmo,
      CantShootHere,
      GotTorch,
      NoTorch,
      DontNeedTorch,
      EnterDark,
      MakePath,
      TouchFake,
      GotGem,
      TouchEner: boolean;
      Pad: array [1..15] of byte;
      end;
   {}
   { Used to store default parameters for objects }
   {}
   DefType = array [0..NumClasses] of
      record
         Intel,
         Rate,
         Room:    byte;
         Xd,
         Yd:      integer;
         end;
   {}
   { All rooms & information for entire game }
   {}
   GameType = record
      NumRooms: integer;
      RoomPtr:   array [0..MaxRooms] of Pointer;
         { Room 0: demo screen }
         { Room 1: starting room - player's start pos'n is important }
         { Room>1: other rooms in game }
         { Rooms are stored in memory as compressed garbage, and }
         {         decompressed only when needed. }
      RoomSize: array [0..MaxRooms] of integer;
         { Length of data stored at pointer }
      I:        InvType;   {Inventory}
      Def:      DefType;   {Defaults}
      First:    FirstType; {List of first-did's for help }
      end;
   {}
   RLEcelltype= record
      Len:       byte;
      Cell:      BoardCell;
      end;
   {}
   InputType = (INum,IFname,IStr);
   {}
   HiType = array [1..NumHi] of record
      Name:   OurString;
      Score:  integer;
      end;
   {}

const
   Border:   BoardCell = (Kind:NormWall; Color:$0e);
      {Visible, changable border}
   Boundary: BoardCell = (Kind:Bound; Color:$00);
      {Invisible, impenetrable, unchangable boundary around board}
   NormObj:ObjType = (
      X: 0; Y: 0;
      Xd:0; Yd:0;
      Cycle:   0;
      Intel:   0;
      Rate:    0;
      Room:    0;
      Child:   -1;
      Parent:  -1;
      Under:   (Kind:Empty;Color:$00);
      Inside:  nil;
      Offset:  0;
      InsideLen:0);
   {}
   Line2String:String [16] =
      #249+#208+#210+#186+
      #181+#188+#187+#185+
      #198+#200+#201+#204+
      #205+#202+#203+#206;

var
   {}
   { Splotch: array of every screen coordinate, in random order.  This }
   { is used to reduce the monotony of clearing the screen and drawing }
   { the board in normal, side-to-side fasion. }
   {}
   Splotch: array [0..MaxXYs] of Coord;
   {}
   GameName: OurString;   {Filename of board}
   SaveName: OurString;   {Filename of save-restore}
   IEName:   OurString;   {Editor import/export filename}
   IntroName:OurString;   {Game to load at startup}
   {}
   { U: The current board, modified as game progresses }
   {}
   U:           RoomType;
   {}
   { G: The current game, including all rooms, plus player's info }
   {}
   G:           GameType;
   {}
   ExitProgram: boolean; {True when user quits program }
   Done:        boolean; {Done with current game}
   PlayMode:    integer; {PLAYER or MONITOR or SPEEDMON?}
   EntryRoom:   integer;
   {}
   XYs:         integer; {# of cells in board = (xs+1)*(Ys+1)-1}
   {}
   Speed:       byte; {Selected game speed, 0-9}
   {}
   TempHeap:    pointer; {Pointer to temporary heap storage }
   {}
   Info:        array [0..NumClasses] of InfoType;
      {Items - bldg blocks of game}
   {}
   NumPats:     integer;
   Pats:        array [1..10] of byte;
   {}
   GameCycle:   integer; {# of Sec100s in each update cycle}
   Counter:     integer; {Tick counter - 1 per game update}
   ObjNum:      integer; {Loops thru all objects when playing}
   StandBy:     boolean; {Pausing flag}
   Sec100:      word;    {Used for timer, TimePassed(,)}
   {}
   EdFlag:      boolean; {We-are-in-editor flag}
   {}
   OldTextAttr: byte;    {DOS attributes upon entry}
   {}
   { Stuff used for language interpretter }
   {}
   LChar:       char;
   LWord:       string [20];
   LNum:        integer;
   {}
   Debug:       boolean; {Special debug mode}
   {}
   HiScores:    HiType;
   {}
   RegCopy:     string; {Registered copy?}
   RegWorld:    OurString;
   RegEdit:     boolean;
   SerNum:      OurString;
   FirstRun:    boolean;
   Reconfig:    boolean;
   {}
   FirstThru:   boolean; {First time thru menu for auto-about at start of session?}
   {}
   Wnum:        integer;
   Wname:       array [1..10] of OurString;
   Wdescr:      array [1..10] of OurString;

implementation



begin
   end.

