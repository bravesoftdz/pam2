type TServiceUserPassword = record

		service_id: integer;
		password: AnsiString;
		encType: byte; // CONSTANT ENCTYPE_*

end;

type TServiceHostGroupBinding = record
		service_id: integer;
		group_id: integer;
		allow: boolean;
end;

type TServiceHostUserBinding = record
		service_id: integer;
		user_id: integer;
		allow: boolean;
end;

type TServiceHostOptionsBinding = record
		service_id: integer;
		option_name: AnsiString;
		option_value: AnsiString;
end;

type TServiceHostUserOptionBinding = record
		service_id: integer;
		user_id: integer;
		option_name: AnsiString;
		option_value: AnsiString;
end;

type TServiceGroupOptionBinding = record
		service_id: integer;
		group_id: integer;
		option_name: AnsiString;
		option_value: AnsiString;
end;

type TPam2ServiceList = Array of TPam2Service;

{ mapping of table service_options }
type TPam2ServiceOptionBinding = record
	    option_value: AnsiString;
	    default_value: AnsiString;
end;