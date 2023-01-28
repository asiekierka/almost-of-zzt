program BuildHLP;

const
   MaxHelpFiles=24;

var
   HelpData:   record
      Num:     integer;
      Names:   array [1..MaxHelpFiles] of string [50];
      Offsets: array [1..MaxHelpFiles] of longint;
      end;
   RealNames: array [1..MaxHelpFiles] of string [50];
   ListFname: string;
   OutFname:  string;
   T:         text;
   F:         file;
   C:         integer;
   TempS:     string;
   TempB:     byte;
   TempP:     pointer;

begin with HelpData do begin
   ListFname := ParamStr (1);
   writeln;
   assign (T,ListFname);
   reset (T);
   readln (T,OutFname);
   writeln ('Writing: ',OutFname);
   Num := 0;
   repeat
      Num := Num + 1;
      readln (T,RealNames[Num]);
      if copy (RealNames[Num],1,1)='*' then begin
         readln (T,Names[Num]);
         RealNames[Num] := copy (RealNames[Num],2,length (RealNames[Num])-1);
         end
      else
         Names[Num] := RealNames [Num];
      for c := 1 to length (Names [Num]) do
         Names [Num][c] := upcase (names [Num][c]);
      until RealNames [Num]='';
   close (T);
   HelpData.Num := HelpData.Num - 1;
   {}
   assign (F,OutFname);
   rewrite (F,1);
   blockwrite (F,HelpData,sizeof (HelpData));
   for c:=1 to HelpData.Num do begin
      writeln ('   ...',HelpData.Names[c]);
      Offsets [c] := filepos (F);
      assign (T,RealNames[c]);
      reset (T);
      while not EOF (T) do begin
         readln (T,TempS);
         TempB := length (TempS);
         blockwrite (F,TempB,1);
         TempP := ptr (seg(TempS),ofs(TempS)+1);
         if (TempB <> 0) then
            blockwrite (F,TempP^,TempB);
         end;
      TempB := 1;
      blockwrite (F,TempB,1);
      TempB := ord ('@');
      blockwrite (F,TempB,1);
      close (T);
      end;
   seek (F,0);
   blockwrite (F,HelpData,sizeof (HelpData));
   close (F);
   end; end.
