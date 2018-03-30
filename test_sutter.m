baud = 9600;
bytesize = 8;
stopbits = 1;
a=serial('COM8','BaudRate',baud,'DataBits',bytesize,'StopBits',stopbits);
a.Terminator='CR';
fopen(a)
fwrite(a,[uint8(98) uint8(13)],'uint8')
fread(a,1)
xyz=[100,0,-100];
xyz=xyz(:);
xyz_bytes = typecast(int32(xyz .* 25),'uint8')';
% add the "m" and the CR to create the move command
move = [uint8(109) xyz_bytes uint8(13)];
% send binary result to Sutter and measure time until move is acknowledged
fwrite(a,move,'uint8'); tic
% Sutter replies with a CR after move finishes
cr=[]; %#ok<NASGU>
cr=fread(a,1,'uint8');
fclose(a)