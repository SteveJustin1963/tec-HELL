program Hellschreiber;

uses crt;

const
  width = 79;
  height = 24;

var
  x, y: integer;
  ch: char;

begin
  x := width div 2;
  y := height div 2;
  ch := '@';
  textbackground(0);
  clrscr;
  textcolor(7);
  gotoxy(x, y);
  write(ch);
  while not keypressed do
  begin
    if x < width then
      inc(x)
    else
    begin
      x := 1;
      if y < height then
        inc(y)
      else
        y := 1;
    end;
    gotoxy(x, y);
    write(ch);
  end;
  readln;
end.
