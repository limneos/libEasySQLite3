libEasySQLite3 
==============
Library that adds convenience methods for SQLite databases management
-------------------------------

by Elias Limneos
----------------
web: limneos.net

email: iphone (at) limneos (dot) net

twitter: @limneos

Intro
-----

libEasySQLite3 adds the class SQLiteManager that manages basic sqlite3 functions. 
You can open sqlite databases, perform queries , insert, alter, delete , 
returning results in NSArrays and NSDictionaries for convenience and better management.


Example (cycript)
-------

	manager=[[SQLiteManager alloc] initWithDBPath: @"/var/mobile/Library/SMS/sms.db" createIfNotExists:NO];
	// "<SQLiteManager: 0x18d220>"
	
	[manager tables];
	// ["_SqliteDatabaseProperties","group_member","message","msg_group","msg_pieces","sqlite_sequence"]
	
	[manager columnTitlesForTable: @"message"];
	// ["ROWID","address","date","text","flags","replace","svc_center","group_id",
	// "association_id","height","UIFlags","version","subject","country","headers","recipients","read"]

	[manager resultOfQuery: @"select * from message order by ROWID desc limit 1"]; 
	// [{read:"1",UIFlags:"0",association_id:"0",flags:"2",address:"+306986352xxx",group_id:"1",text:"I'm waiting for you at the station\n",version:"0",replace:"0",height:"0",ROWID:"1",country:"gr",date:"1297304329"}]
	
	
The above example opens the SMS database on iPhone, lists its tables, gets table structure for table "message" and selects the first message entry.

Another example (in cycript , for quick understanding) , creating our own new database:

	manager=[[SQLiteManager alloc] initWithDBPath: @"/tmp/new.db"]; 
	// "<SQLiteManager: 0x18d220>"
	
	[manager dbName];
	// "new" 
	
	[manager tables];
	// []   (empty array = no tables)
	
	fields=[NSMutableArray array]; 
	[fields addObject:@"id"]; 
	[fields addObject:@"message"]; 
	[fields addObject:@"timestamp"]; 
	
	types=[NSMutableArray array]; 
	[types addObject:@"INTEGER PRIMARY KEY"]; 
	[types addObject:@"TEXT"]; 
	[types addObject:@"INTEGER"]; 
	
	[manager createTable:@"myTable" withFields:fields ofTypes:types];
	
	[manager tables];
	// [""myTable""]
	
	fieldsArray=[NSMutableArray array];
	[fieldsArray addObject:@"message"];
	[fieldsArray addObject:@"timestamp"];
	
	valuesArray=[NSMutableArray array];
	[valuesArray addObject:@"hello there"];
	[valuesArray addObject:[[NSDate date] timeIntervalSince1970]];
	
	[manager insertInto:@"myTable" fields:fieldsArray values:valuesArray]; 
	
	[manager selectAllFromTable: "myTable"];
	// [{id:"1",message:"hello there",timestamp:"1302123839.21203"}]
	
	[manager truncateTable: "myTable"];
	
	[manager dropTable: "myTable"];
	

Licence
-----------

libEasySQLite is open source

Compile
-------

libEasySQLite is compiled using Theos. For more information about 
Theos/Logos, visit http://bit.ly/af0Evu and http://hwtt.net/ths


Thanks
------

Permanent Thanks to:

 Optimo for being my mentor

 DHowett for Theos/Logos and all the background work he's done for the community

 Saurik for cycript and everything else

 Many other developers from IRC from which I've learned a lot, including
 rpetrich, BigBoss, DB42, kennytm, chpwn, mringwal, TheZimm, Yllier


