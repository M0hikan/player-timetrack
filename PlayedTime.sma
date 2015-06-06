@@ -0,0 +1,208 @@
/* Plugin generated by AMXX-Studio */
//My plugin never fail, if al else fail ROD OF AGES!

#include <amxmodx>
#include <sqlx>

#define PLUGIN "New Plug-In"
#define VERSION "0.Ox"
#define AUTHOR "Hades Ownage"

#pragma tabsize 0

new const SQL_TABLE[ ] = "player_time";
new g_pcvarHost;
new g_pcvaruUser;
new g_pcvarPass;
new g_pcvarDB;

new steamid[32]
new playedTime[32]
new string[32]

new Handle:g_SqlTuple;
new g_Error[ 512 ];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	g_pcvarHost = register_cvar( "furien_sql_host", "127.0.0.1" )
	g_pcvaruUser = register_cvar( "furien_sql_user", "root" )
	g_pcvarPass = register_cvar( "furien_sql_pass", "" )
	g_pcvarDB = register_cvar( "furien_sql_db", "cstrike" )

	//client commands
	register_clcmd("say /timetrack", "timeTrack");
	
	set_task( 0.1, "SqlInit" )
	//set_task(15.0, "PlayerAnnounce",0, _, _, "b") //later use
}

public SqlInit( )
{
	new szHost[ 32 ]
	new szUser[ 32 ]
	new szPass[ 32 ]
	new szDB[ 32 ]
	
	get_pcvar_string( g_pcvarHost, szHost, charsmax( szHost ) )
	get_pcvar_string( g_pcvaruUser, szUser, charsmax( szUser ) )
	get_pcvar_string( g_pcvarPass, szPass, charsmax( szPass ) )
	get_pcvar_string( g_pcvarDB, szDB, charsmax( szDB ) )
	
	g_SqlTuple = SQL_MakeDbTuple( szHost, szUser, szPass, szDB )
	
	new ErrorCode
	new Handle:SqlConnection = SQL_Connect( g_SqlTuple, ErrorCode, g_Error, charsmax( g_Error ) )
	
	if( SqlConnection == Empty_Handle )
		set_fail_state( g_Error )
	
	new Handle:Queries
	Queries = SQL_PrepareQuery( SqlConnection, "CREATE TABLE IF NOT EXISTS %s (id INT(11) PRIMARY KEY, steamid varchar(32), playedTime INT(11)) ", SQL_TABLE )
	
	if( !SQL_Execute( Queries ) )
	{
		SQL_QueryError( Queries, g_Error, charsmax( g_Error ) )
		set_fail_state( g_Error )
	}
	
	SQL_FreeHandle( Queries )
	SQL_FreeHandle( SqlConnection ) 
}

public plugin_end ( ) {
	
	SQL_FreeHandle ( g_SqlTuple )
	
}

public SaveData(id)
{

	static playTime
    playTime = get_user_time(id, 1) / 60;
    new name[32]
    get_user_name(id, name, 32)

	new szTemp[ 512 ]
	formatex( szTemp, charsmax( szTemp ), "UPDATE `%s` SET `playedTime` = `playedTime` + '%d' WHERE `%s`.`steamid` = '%s';", SQL_TABLE, playTime, SQL_TABLE,name)
	
	SQL_ThreadQuery( g_SqlTuple, "IgnoreHandle", szTemp )
}

public LoadData(id)
{
	static Data[1]; Data[0] = id

	new name[32]
    get_user_name(id, name, 31)
	
	new szTemp[ 512 ]
	formatex( szTemp, charsmax( szTemp ), "SELECT `steamid`,`playedTime` FROM %s WHERE (`%s`.`steamid` = '%s');", SQL_TABLE, SQL_TABLE, name)
	
	SQL_ThreadQuery( g_SqlTuple, "RegisterClient", szTemp, Data, 1 )
}


public RegisterClient( FailState, Handle:Query, Error[ ], Errcode, Data[ ], DataSize )
{
	if( SQL_IsFail( FailState, Errcode, Error ) )
		return PLUGIN_HANDLED_MAIN
	
	static id; id = Data[0]
	
	if( SQL_NumResults( Query ) < 1 )
	{

		static playTime
    	playTime = get_user_time(id, 1) / 60;
    	new name[32]
        get_user_name(id, name, 31)


		new szTemp[ 512 ]
		formatex( szTemp, charsmax( szTemp ), "INSERT INTO %s (steamid, playedTime) VALUES('%s', '0');", SQL_TABLE, name, playTime)
		
		SQL_ThreadQuery( g_SqlTuple, "IgnoreHandle", szTemp )

	}
	
	SQL_FreeHandle(Query)
	return PLUGIN_CONTINUE
}

public timeTrack(id){

	new name[32]
    get_user_name(id, name, 31)

	static Data[1]; Data[0] = id
    
    new szTemp[512]
    formatex( szTemp, charsmax( szTemp ), "SELECT `steamid`,`playedTime` FROM %s WHERE (`%s`.`steamid` = '%s');", SQL_TABLE, SQL_TABLE, name)
    SQL_ThreadQuery(g_SqlTuple,"Sql_PlayedTime",szTemp,Data,1)
        
}

public Sql_PlayedTime(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
    if(FailState == TQUERY_CONNECT_FAILED)
            log_amx("Load - Could not connect to SQL database.  [%d] %s", Errcode, Error)
    else if(FailState == TQUERY_QUERY_FAILED)
            log_amx("Load Query failed. [%d] %s", Errcode, Error)

	static id; id = Data[0]

	new name[32]
    get_user_name(id, name, 31)

    if( SQL_NumResults( Query ) > 0 )
	{

		steamid[id] = SQL_ReadResult(Query, 0, string, 31)
		playedTime[id] = SQL_ReadResult(Query, 1)
   

    client_print(id,print_chat,"[AMXX] You are playing for about %d minutes.", playedTime[id])

	}
    
    return PLUGIN_HANDLED
} 

public client_putinserver( id ){
	LoadData(id)	
}

public client_disconnect(id){

	SaveData(id)

}


public IgnoreHandle( FailState, Handle:Query, Error[ ], Errcode, Data[ ], DataSize )
	SQL_FreeHandle( Query )

SQL_IsFail( const FailState, const Errcode, const Error[ ] ) {
	if( FailState == TQUERY_CONNECT_FAILED )
	{
		log_amx( "[Error] Could not connect to SQL database: %s", Error )
		return true
	}
	
	else if( FailState == TQUERY_QUERY_FAILED )
	{
		log_amx( "[Error] Query failed: %s", Error )
		return true
	}
	
	else if( Errcode )
	{
		log_amx( "[Error] Error on query: %s", Error )
		return true
	}
	
	return false
}
