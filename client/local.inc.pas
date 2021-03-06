{$I ../server/Pam2Entities/types_impl.inc.pas}

function read_password_from_user(): AnsiString;
var c: char;
    wx: integer;
    wy: integer;
    i: integer;
begin

	wx := wherex;
	wy := wherey;

	result := '';

	repeat

		gotoxy( wx, wy );

		for i := 1 to length(result) do write('*');

		clreol;

		c := readkey;

		if c <> #0 then
		begin

			if c = #8 then
			begin

				if ( length( result ) > 0 ) then
					delete( result, length(result), 1 );

			end else
			if ord( c ) >= 32 then
			begin

				result := result + c;

			end;

		end else
		begin

			if ( keypressed ) then
				c := readkey
			else c := #0;

		end;

	until ( c = #13 ) and ( result <> '' );

end;

procedure do_login();
var read_user: boolean;
    read_password: boolean;
    wy: integer;
    ousername: ansistring;
begin

	ousername := username;

	read_user := false;
	wy := wherey;
	repeat
		gotoxy( 0, wy );
		clreol();
		write( 'Username' );

		if ( u_user = true ) then
		begin

			write(' [');

			textcolor(green);
			write( username );
			textcolor(lightgray);

			write(']: ');

		end else
		begin

			write(': ');

		end;

		readln( username );
		username := trim( lowercase( username ) );
		if ( length( username ) > 0 ) then
		begin
			if ( str_match_chars( username, FMT_USER ) ) then
			begin
				if ( str_match_chars( copy( username, 1, 1 ), FMT_USER_BEGIN ) ) then
				begin
					read_user := true;
				end
			end
		end else
		if ( u_user = true ) then
		begin
			username := ousername;
			read_user := true;
		end;
	until read_user = true;

	wy := wherey;
	read_password := false;
	repeat
		gotoxy(0,wy);
		clreol;
		write('Password: ');
		password := read_password_from_user;
		if ( length(password) > 0 ) then
		begin
			read_password := true;
		end;
	until read_password = true;

	u_user := true;
	u_pwd := true;

	writeln;
	textcolor(yellow);
	if ( ousername <> username ) then
		write( '* Setting username to "' + username + '"' );
	textcolor(lightgray);

end;

procedure do_host( query: TStrArray );
var read_host: boolean;
    wy: integer;
begin

	if ( length( query ) = 2 ) then
	begin
		
		read_host := FALSE;

		if ( str_match_chars( query[1], FMT_HOST ) ) then
		begin
			if ( str_match_chars( copy( query[1], 1, 1 ), FMT_HOST_BEGIN ) ) then
			begin

				read_host := true;

			end else
			begin

				read_host := false;

			end;
		end else
		begin

			read_host := false;

		end;

		if ( read_host = false ) then
		begin

			textcolor(red);
			writeln('invalid hostname');
			textcolor(lightgray);
			exit;

		end else
		begin

			hostname := query[1];
			u_host := true;

		end;

	end else
	if ( length( query ) = 1 ) then
	begin
		read_host := false;
		wy := wherey;
		repeat

			gotoxy( 0, wy );
			clreol;
			write( 'Hostname: ' );
			readln( hostname );
			hostname := trim( lowercase( hostname ) );

			if ( length( hostname ) > 0 ) then
			begin
				if ( str_match_chars( hostname, FMT_HOST ) ) then
				begin

					if ( str_match_chars( copy( hostname, 1, 1 ), FMT_HOST_BEGIN ) ) then
					begin
						read_host := true;
					end;

				end;
			end;

		until read_host = true;
		u_host := true;
	end else
	begin

		textcolor( red );
		writeln( 'invalid command number of arguments.' );
		textcolor ( lightgray );
		exit;

	end;

	textcolor(yellow);
	writeln( '* Setting hostname to "' + hostname + '"' );
	textcolor(lightgray);

	if u_user = false then do_login;

	
end;

procedure print_stderr( outs: AnsiString );
begin
	if length(outs) = 0 then exit;
	textcolor(red);
	writeln(outs);
	textcolor(lightgray);
end;

procedure print_json( data: TJSON; const indent: Integer = 0; const objectKey: AnsiString = '' );
var i: Integer;
    len: Integer;
    tabs: AnsiString;
    keys: TStrArray;
    maxKeyLen: Integer;
    l2: Integer;
begin

	tabs := '';
	
	for i := 1 to indent do tabs := tabs + ' ';

	write( tabs );

	if ( objectKey <> '' ) then
	begin
		textcolor(magenta);
		write( objectKey );
		textcolor(lightgray);
	end;

	if ( data = NIL ) then
	begin
		textcolor(red);
		write( 'null' );
		textcolor(lightgray);
	end else
	if ( data.typeof = 'number' ) then
	begin
		textcolor(lightgreen);
		write( data.getAsInt( 0 ) );
		textcolor(lightgray);
	end else
	if ( data.typeof = 'string' ) then
	begin

		if ( indent > 0 ) then
		begin

		write('''');
		textcolor(lightblue);
		write( data.getAsString('') );
		textcolor(lightgray);
		write('''');

		end else
		begin
		write( data.getAsString('') );
		end;

	end else
	if ( data.typeof = 'boolean' ) then
	begin
		textcolor(lightmagenta);
		if ( data.getAsBoolean(FALSE) = TRUE ) then
			write('true')
		else
			write('false');
		textcolor(lightgray);
	end else
	if ( data.typeof = 'null' ) then
	begin
		textcolor(red);
		write('null');
		textcolor(lightgray);
	end else
	if ( data.typeof = 'array' ) then
	begin

		writeln('[');

		len := data.count;

		for i := 0 to len - 1 do
		begin

			print_json( data.get( i ), indent + 4 );
			
			if ( i < len - 1 ) then
				writeln( ',' )
			else
				writeln;

		end;

		write(tabs, ']' );

	end else
	if ( data.typeof = 'object' ) then
	begin

		writeln( '{' );

		keys := data.keys;

		Len := length( keys );

		maxKeyLen := 0;

		for i := 0 to Len - 1 do
		begin

			L2 := Length( keys[i] );

			if ( L2 > maxKeyLen ) then
				maxKeyLen := L2;

		end;

		for i := 0 to Len - 1 do
		begin

			print_json( data.get( keys[i] ), indent + 4, padRight( keys[i], maxKeyLen ) + ' : ' );
			
			if ( i < len - 1 ) then
				writeln(',')
			else
				writeln;

		end;

		write( tabs, '}' );

	end;

end;

procedure print_stdout( outs: AnsiString );
var data: TJSON;
begin

	if length(outs) = 0 then exit;

	data := json_decode( outs );

	if ( data <> NIL ) then
	begin

		if ( data.typeof = 'object' ) then
		begin

			if ( data.hasOwnProperty( 'ok' ) and ( data.typeof('ok') = 'boolean' ) and data.get('ok',false) = true ) then
			begin

				if ( data.typeof('data') = 'object' ) and ( data.get('data').typeof('explain') = 'string' ) then
				begin

					textcolor(yellow);
					writeln(data.get('data').get('explain','The command completed successfully'));
					textcolor(lightgray);

					if ( data.get('data').typeof('data') <> 'undefined' ) then
					begin
						print_json( data.get('data').get('data') );
						writeln;
					end;

				end else
				begin
					textcolor(yellow);
					writeln('The command completed successfully');
					textcolor(lightgray);

				end;

			end else
			begin

				if ( data.hasOwnProperty('error') and ( data.typeof('error') = 'string' ) ) then
				begin

					print_stderr( data.get('error', '') );

				end else
				begin

					print_stderr('Unknown server error');

				end;

			end;

		end else
			print_stderr( 'Expected object in server response' );

		data.Free;

	end else

	print_stderr('Cannot decode from JSON: "' + outs + '"' );

end;

procedure exec_remote_command( query: TStrArray );
var args: TStrArray;
	i: integer;
	len: integer;

	AProcess: TProcess;
	OutputStream: TMemoryStream;
	ErrorStream: TMemoryStream;
	BytesRead: Integer;
	Buffer: array[1..2048] of byte;
	AStrings: TStringList;

	StdOutText: AnsiString;
	StdErrText: AnsiString;

begin
	setLength( args, 8 );

	len := length(query);

	//args[0] := node_path;
	args[0] := getApplicationDir() + PATH_SEPARATOR + 'pam2.js';
	args[1] := '-u';
	args[2] := username;
	args[3] := '-p';
	args[4] := password;
	args[5] := '-h';
	args[6] := hostname + ':42763';
	args[7] := '-q';

	for i := 0 to len - 1 do
	begin
		setLength( args, length(args)+1);
		args[ length( args) - 1 ] := query[i];
	end;

	len := length(args);


	AProcess := TProcess.Create(NIL);
	AProcess.Executable := node_path;

	for i := 0 to len - 1 do
		AProcess.Parameters.Add( args[i] );

	AProcess.Options := [poUsePipes];
	AProcess.Execute;

	OutputStream := TMemoryStream.Create;
	repeat
		BytesRead := AProcess.Output.Read(Buffer, 2048);
		OutputStream.Write(Buffer, BytesRead);
	until BytesRead = 0;

	ErrorStream := TMemoryStream.Create;
	repeat
		BytesRead := AProcess.StdErr.Read( Buffer, 2048 );
		ErrorStream.Write(Buffer,BytesRead);
	until BytesRead = 0;


	AProcess.Free;

	AStrings := TStringList.Create;
	OutputStream.Position := 0;
	AStrings.LoadFromStream( OutputStream );
	StdOutText := AStrings.Text;
	AStrings.Free;

	AStrings := TStringList.Create;
	ErrorStream.Position := 0;
	AStrings.LoadFromStream( ErrorStream );
	StdErrText := AStrings.Text;
	AStrings.Free;

	OutputStream.Free;
	ErrorStream.Free;

	StdOutText := sysutils.Trim( StdOutText );
	StdErrText := sysutils.Trim( StdErrText );

	if ( stdErrText <> '' ) then
	begin
		print_stderr( stdErrText );
		if ( StdOutText <> '' ) then
		begin
			print_stdout( StdOutText );
		end;
	end else
	begin
		if ( StdOutText <> '' ) then
			print_stdout( StdOutText );
	end;
end;

procedure do_help();
begin
	writeln;

	writeln('Available client commands list:' );
	textcolor(lightgreen); write('clear, cls    '); textcolor( lightgray ); writeln('Clears the screen');
	textcolor(lightgreen); write('help          '); textcolor( lightgray ); writeln('Shows this help');
	textcolor(lightgreen); write('help server   '); textcolor( lightgray ); writeln('Shows help about server query language (must be logged in)');
	textcolor(lightgreen); write('host, connect '); textcolor( lightgray ); writeln('Connect to a new PAM2 server');
	textcolor(lightgreen); write('login         '); textcolor( lightgray ); writeln('Change current user and password' );
	textcolor(lightgreen); write('quit          '); textcolor( lightgray ); writeln('Exits this program');
	writeln;
	writeln('Available keys:' );
	textcolor(lightgreen); write('UP, DOWN      '); textcolor( lightgray ); writeln('Navigate in history of current session' );
	textcolor(lightgreen); write('BKSPACE, DEL  '); textcolor( lightgray ); writeln('Delete char at cursor' );
	textcolor(lightgreen); write('ENTER         '); textcolor( lightgray ); writeln('Execute command' );
	textcolor(lightgreen); write('ESC           '); textcolor( lightgray ); writeln('Quit' );

	writeln;
end;