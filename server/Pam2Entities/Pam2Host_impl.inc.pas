constructor TPam2Host.Create( _db: TPam2DB; hid: integer; hname: AnsiString; defaultHost: boolean; isSaved: boolean );
begin

	db := _db;

	needSave := not isSaved;
	deleted := FALSE;

	_host_id := hid;
	_host_name := hname;
	_default_host := defaultHost;

end;

constructor TPam2Host.Create( _db: TPam2DB; hid: integer );
begin

	db := _db;

	needSave := FALSE;
	deleted := FALSE;

	_host_id := hid;
	_host_name := '';
	_default_host := FALSE;

end;

procedure TPam2Host.snapshot();
begin

	if ( _host_id = 0 ) then exit;

	db.addSnapshot( 'HOST ' + IntToStr( _host_id ) );
	
	db.addSnapshot( '_host_name: ' + _host_name );
	db.addSnapshot( '_default_host: ' + IntToStr( Integer( _default_host ) ) );

	db.addSnapshot( 'needSave: ' + IntToStr( Integer( needSave ) ) );
	db.addSnapshot( 'deleted: ' + IntToStr( Integer( deleted ) ) );
	
	db.addSnapshot( 'END' );
end;

procedure TPam2Host.rollback( snapshotLine: AnsiString );
var propName: AnsiString;
    propValue: AnsiString;
    dotPos: Integer;
    len: Integer;
begin

	dotPos := Pos( ':', snapshotLine );

	if dotPos = 0 then begin
		raise Exception.Create( 'TPam2Host.rollback: Bad snapshot line ("' + snapshotLine + '". BUG.' );
		exit;
	end;

	len := Length( snapshotLine );

	propName := copy( snapshotLine, 1, dotPos - 1 );
	propValue := copy( snapshotLine, dotPos + 2, len );

	if propName = '_host_name' then
	begin
		_host_name := propValue;
	end else
	if propName = '_default_host' then
	begin
		_default_host := Boolean( StrToInt( propValue ) );
	end else
	if propName = 'needSave' then
	begin
		needSave := Boolean( StrToInt( propValue ) );
	end else
	if propName = 'deleted' then
	begin
		deleted := Boolean( StrToInt( propValue ) );
	end else
	raise Exception.Create('TPam2Host.rollback: Don''t know how to restore property "' + propName + '"' );

end;

function TPam2Host.Save(): boolean;
begin
	result := TRUE;
	needSave := FALSE;
end;

destructor TPam2Host.Free();
begin
	
	if needSave then
		Save();

	FreeWithoutSaving();

end;

destructor TPam2Host.FreeWithoutSaving();
begin
end;

procedure TPam2Host.setHostName( value: AnsiString );
var hName : AnsiString;
begin
	hName := normalize( value, ENTITY_HOST );
	if hName = '' then
	begin
		db.addError('Invalid host name "' + value + '"' );
	end else
	if hName = _host_name then
	begin
		// return
	end else
	if db.hostExists( hName, id ) then
	begin
		db.addError( 'A host with the same name "' + hName + '" allready exists!' );
	end else
	begin
		db.addExplanation( 'Rename host "' + _host_name + '" to "' + hName + '"' );
		_host_name := hName;
		needSave := TRUE;
	end;
end;

procedure TPam2Host.setDefaultHost( value: Boolean );

var defaultHost: TPam2Host;

begin

	if value <> _default_host then
	begin

		if value = TRUE then
		begin

			defaultHost := db.defaultHost;

			if defaultHost <> NIL then
				defaultHost.default := FALSE;

			_default_host := TRUE;

			db.addExplanation( 'Set default host to "' + _host_name + '"' );

		end else
		begin

			_default_host := FALSE;

			db.addExplanation( 'Remove the "default host" flag from host "' + _host_name + '"' );

		end;

		needSave := TRUE;

	end;

end;

procedure TPam2Host.updateIdAfterInsertion();
var i: Integer;
begin

	if (not deleted) and (_host_id = 0) then
	begin
		i := db.fetchSQLStatementResultAsInt('SELECT id FROM `host` WHERE name = "' + _host_name + '" LIMIT 1' );

		if i > 0 then
		begin
			_host_id := i;
			Console.log('Updated id of host ' + _host_name + ' to ' + IntToStr( _host_id ) );
		end else
		begin
			Console.error('Failed to update id of host ' + _host_name );
		end;
	end;
end;

procedure TPam2Host.remove();
begin

	if ( not deleted ) then
	begin
		deleted := TRUE;
		needSave := TRUE;
		db.unbindHSG( self );
		db.unbindHSU( self );
		db.unbindSHO( self );
	end;

end;

function TPam2Host.equals( host: TPam2Host ): Boolean;
begin
	if ( host = NIL ) then
	begin
		result := FALSE;
	end else
	begin

		if ( ( id > 0 ) and ( id = host.id ) ) or
		   ( ( hostName <> '' ) and ( hostName = host.hostName ) )

		then result := TRUE
		else result := FALSE;

	end;
end;

function TPam2Host._toJSON(): AnsiString;
begin
	result := '{"type":"host",';
	result := result + '"id":' + json_encode(_host_id) + ',';
	result := result + '"name":' + json_encode(_host_name) + ',';
	result := result + '"default":' + json_encode(_default_host);
	result := result + '}';
end;