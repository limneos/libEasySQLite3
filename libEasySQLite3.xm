#import <sqlite3.h>
#import <substrate.h>


@interface SQLiteManager : NSObject{
	sqlite3 *dbHandle;
	NSString *dbPath;
	NSString *dbName;
}
@property (nonatomic, retain) NSString *dbPath; 
@property (nonatomic) sqlite3 *dbHandle; 
@property (nonatomic, retain) NSString *dbName; 
-(id)initWithDBPath:(NSString *)path;
-(id)initWithDBPath:(NSString *)path createIfNotExists:(BOOL)create; 
-(id)resultOfQuery:(NSString *)query;
-(id)resultOfQuery:(NSString *)query error:(NSError**)error; 
-(NSArray *)tables; 
-(id)structureOfTable:(NSString *)tableName;
-(id)columnTitlesForTable:(NSString *)tableName; 
-(int)rowCountForTable:(NSString *)tableName;
-(BOOL)isDBOpen; 
-(int)closeDB; 
-(NSString *)stringForErrorCode:(int)code;
@end

@interface SQLiteManager (ConvenientMethods)
-(id)createTable:(NSString *)tableName withFields:(NSArray *)values ofTypes:(NSArray *)types; 
-(id)selectAllFromTable:(NSString *)tableName;
-(id)select:(NSString *)whatToSelect fromTable:(NSString *)tableName;
-(id)select:(NSString *)whatToSelect fromTable:(NSString *)tableName additionalString:(NSString *)string;
-(id)insertInto:(NSString *)tableName fields:(NSArray *)fields values:(NSArray *)values;
-(id)updateTable:(NSString *)tableName setFields:(NSArray *)fields setValues:(NSArray *)values where:(NSString *)whereClause;
-(id)deleteFrom:(NSString *)tableName where:(NSString *)whereClause;
-(id)truncateTable:(NSString *)tableName; 
-(id)dropTable:(NSString *)tableName; 
@end




static BOOL writeAllSqliteQueriesToSyslog=0;



@implementation SQLiteManager

@synthesize dbPath,dbName,dbHandle;


-(id)initWithDBPath:(NSString *)path{
	return [self initWithDBPath:path createIfNotExists:YES];
}


-(id)initWithDBPath:(NSString *)path createIfNotExists:(BOOL)create {
	
		
	NSFileManager *fileman=[NSFileManager defaultManager];
	BOOL isDir;
	
	if (!([fileman fileExistsAtPath:path isDirectory:&isDir] && !isDir) && !create){
	NSLog(@"libEasySQLite: Database does not exist at path %@",path);
	return nil;
	}
	
	int sqliteErrorCode=sqlite3_open([path UTF8String], &dbHandle);
	
	if( sqliteErrorCode == SQLITE_OK) {
		self.dbPath=path;
		self.dbName=[[path lastPathComponent] stringByDeletingPathExtension];
		sqlite3_close(dbHandle);
		dbHandle=nil;
		return [super init];
	}
		
	else{
		self.dbHandle=nil;
		NSLog(@"libEasySQLite: Error: %@",[self stringForErrorCode:sqliteErrorCode]);
		return nil;
	}
		
	

}

-(BOOL)openDB{
	int sqliteErrorCode=sqlite3_open([self.dbPath UTF8String], &dbHandle);
	return sqliteErrorCode == SQLITE_OK;
}


-(int)closeDB{
	if (dbHandle){
		int closeResult = sqlite3_close(dbHandle);
		dbHandle=nil;
		return closeResult;
	}
return 0;
}



-(BOOL)isDBOpen{
return nil != dbHandle;
}


-(NSArray *)tables{
	
	if (![self isDBOpen]) {
		[self openDB];
	}
	
	NSMutableArray *tables=[NSMutableArray array];
	sqlite3_stmt *compiledQuery;
		
		if (sqlite3_prepare_v2(dbHandle, "SELECT name FROM sqlite_master WHERE type='table' order by name", -1, &compiledQuery, NULL) == SQLITE_OK)
		{
			
			int columncount=sqlite3_column_count(compiledQuery);

			while(sqlite3_step(compiledQuery) == SQLITE_ROW) {

				for(int j=0;j<columncount;j++){
				
					if (sqlite3_column_text(compiledQuery, j)){
					
					NSString *cell=[NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledQuery, j)];
					
						if (![cell isEqual:@"sqlite_stat1"]){
							[tables addObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledQuery, j)]];
						}
					}
				}
			}
		}
	
	[self closeDB];
	return [NSArray arrayWithArray:tables]; 
}




-(id)createTable:(NSString *)tableName withFields:(NSArray *)fields ofTypes:(NSArray *)types{

	if (!tableName || !fields || !types || [fields count]!=[types count] ) {
		NSLog(@"libEasySQLite: Error: Table name not defined, or missing / incorrect / unmatched count / of fields and types");
		return nil;
	}
	
	NSString *query=[NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (",tableName];
		
		for (unsigned i=0; i<[fields count]; i++){
			
			query=[query stringByAppendingString: [NSString stringWithFormat:@"%@ %@ ",[fields objectAtIndex:i] , [types objectAtIndex:i] ] ];
			if (i < [fields count]-1){
				query=[query stringByAppendingString:@","];
			}
		
		}
		
		query=[query stringByAppendingString:@")"];
		
	return [self resultOfQuery:query error:nil];
}


-(id)selectAllFromTable:(NSString *)tableName{
	return [self resultOfQuery:[NSString stringWithFormat:@"select * from %@",tableName] ];
}


-(id)select:(NSString *)whatToSelect fromTable:(NSString *)tableName {
	return [self select:whatToSelect fromTable:tableName additionalString:nil];
}


-(id)select:(NSString *)whatToSelect fromTable:(NSString *)tableName additionalString:(/*optional*/ NSString *)whereLimitEtcClause{
		NSString *query;
		
		if (!whereLimitEtcClause){
		query=[NSString stringWithFormat:@"select %@ from %@",whatToSelect,tableName];
		}
		else{
		query=[NSString stringWithFormat:@"select %@ from %@ %@",whatToSelect,tableName,whereLimitEtcClause];
		}
		
	return [self resultOfQuery:query error:nil];
}

-(id)insertInto:(NSString *)tableName fields:(NSArray *)fields values:(NSArray *)values{
	
	if (!tableName || !fields || !values || [fields count]!=[values count] ) {
		NSLog(@"libEasySQLite: Error: Table name not defined, or missing / incorrect / unmatched count / of fields and values");
		return nil;
	}
	
	NSString *query=[NSString stringWithFormat:@"INSERT into %@ (",tableName];
		
		for (unsigned i=0; i<[fields count]; i++){
			query=[query stringByAppendingString:[fields objectAtIndex:i] ];
			
			if (i < [fields count]-1){
				query=[query stringByAppendingString:@","];
			}
		}
		
	query=[query stringByAppendingString:@") VALUES ("];
	
		for (unsigned i=0; i<[values count]; i++){
			query=[query stringByAppendingString: [ NSString stringWithFormat:@"'%@'",[values objectAtIndex:i] ] ];
			
			if (i < [values count]-1){
				query=[query stringByAppendingString:@","];
			}
		}
	
	query=[query stringByAppendingString:@")"];
	
	return [self resultOfQuery:query error:nil];
}

-(id)updateTable:(NSString *)tableName setFields:(NSArray *)fields setValues:(NSArray *)values where:(NSString *)whereClause{
	
	if (!tableName || !fields || !values || [fields count]!=[values count] || !whereClause) {
		NSLog(@"libEasySQLite: Error: Either table name not defined, where clause is not defined , or missing / incorrect / unmatched count / of fields and values");
		return nil;
	}
	
	NSString *query=[NSString stringWithFormat:@"UPDATE %@ set ",tableName];
		
		for (unsigned i=0; i<[fields count]; i++){
			query=[query stringByAppendingString:[NSString stringWithFormat:@"%@='%@'" , [fields objectAtIndex:i] , [values objectAtIndex:i] ] ];
			
			if (i < [fields count]-1){
				query=[query stringByAppendingString:@","];
			}
		}
		
	
	query=[query stringByAppendingString:whereClause];
	
	
	return [self resultOfQuery:query error:nil];
}

-(id)deleteFrom:(NSString *)tableName where:(NSString *)whereClause{
	return [self resultOfQuery:[NSString stringWithFormat:@"delete from %@ %@",tableName,whereClause] error:nil];
}



-(id)structureOfTable:(NSString *)tableName{
	return [self resultOfQuery: [NSString stringWithFormat:@"pragma table_info(%@)",tableName] error: nil];
}

-(id)truncateTable:(NSString *)tableName{
	
	if (nil!=tableName) {
	
		return [self resultOfQuery:[NSString stringWithFormat:@"delete from %@",tableName] error:nil];
	
	}

	return nil;

}




-(id)dropTable:(NSString *)tableName{
	
	if (nil!=tableName) {
	
		return [self resultOfQuery:[NSString stringWithFormat:@"drop TABLE %@",tableName] error:nil];
	
	}

	return nil;

}





-(int)rowCountForTable:(NSString *)table{
		
		if (![self isDBOpen]){
		[self openDB];
		}
		
		sqlite3_stmt *compiledQuery;
		int columncount=0;
		NSString *preQuery=[NSString stringWithFormat:@"SELECT * from %@",table];
		if(sqlite3_prepare_v2(dbHandle, [preQuery UTF8String], -1, &compiledQuery, NULL) == SQLITE_OK) {
			columncount=sqlite3_column_count(compiledQuery);
		}
	 sqlite3_finalize(compiledQuery);
	 [self closeDB];
	return columncount; 
}






-(NSArray *)columnTitlesForTable:(NSString *)table{
	
	if (![self isDBOpen]){
	[self openDB];
	}

	NSMutableArray *columnTitles=[NSMutableArray array];
	
	NSArray *s=[self resultOfQuery:[NSString stringWithFormat:@"pragma table_info(%@)",table] error:nil];
	
	if (s){
	
		for (NSArray *row in s){
			if ([row count]>1){
			[columnTitles addObject:[row objectAtIndex:1]];
			}
		}
	}
	
	[self closeDB];
	
	return [NSArray arrayWithArray:columnTitles];
}

-(id)resultOfQuery:(NSString *)query {
	return [self resultOfQuery:query error:nil];
}


-(id)resultOfQuery:(NSString *)query error:(NSError **)error{
	
	if (![self isDBOpen]){
	[self openDB];
	}
		
	NSMutableArray *tables=[NSMutableArray array];
	
	sqlite3_stmt *compiledQuery;
	
	if(sqlite3_prepare_v2(dbHandle, [query UTF8String], -1, &compiledQuery, NULL) == SQLITE_OK) {
	
		int columncount=sqlite3_column_count(compiledQuery);
	
		NSArray *words = [query componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			NSString *table=nil;
		for (NSString *word in words){
			NSRange range1=[word rangeOfString:@"from" options:(NSCaseInsensitiveSearch)];
			NSRange range2=[word rangeOfString:@"into" options:(NSCaseInsensitiveSearch)];
			NSRange range3=[word rangeOfString:@"update" options:(NSCaseInsensitiveSearch)];
		
			if (range1.location!=NSNotFound || range2.location!=NSNotFound || range3.location!=NSNotFound ){
				if ([words count]>=[words indexOfObject:word]+1){
					table=[words objectAtIndex:[words indexOfObject:word]+1];
				}
			}
		}
		
		NSArray *columnTitles;
		NSMutableDictionary *rowsDict;
		NSMutableArray *rowsArray;
		
		if (table){
		columnTitles=[self columnTitlesForTable:table];
		}
		
		while(sqlite3_step(compiledQuery) == SQLITE_ROW) {
			
			if (table){
		    rowsDict=[NSMutableDictionary dictionary];
			}
			else{
			rowsArray=[NSMutableArray array];
			}
			
			for(int j=0;j<columncount;j++){
				if (sqlite3_column_text(compiledQuery, j)){
				if (table){
				[rowsDict setValue:[NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledQuery, j)] forKey:[columnTitles objectAtIndex:j]];
				}
				else{
				[rowsArray addObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(compiledQuery, j)] ];
				}
				}
			 }
			 if (table){
			 [tables addObject:rowsDict];
			 }
			 else{
			  [tables addObject:rowsArray];
			 }
		}
		
		
	}
	
	else
	
	{
	
		int errorCode=sqlite3_prepare_v2(dbHandle, [query UTF8String], -1, &compiledQuery, NULL);
	
	
		if (error != NULL) 	{
		
			NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
			[errorDetail setValue:[self stringForErrorCode:errorCode] forKey:NSLocalizedDescriptionKey];
			*error = [ [NSError errorWithDomain:@"libEasySQLite" code:errorCode userInfo:errorDetail] retain];
		
		}
	
		if (errorCode){
		NSLog(@"libEasySQLite: ERROR : Query: %@, Error: %@",query,[self stringForErrorCode:errorCode]);
		}
	
	return nil;
	
	}
	
	sqlite3_finalize(compiledQuery);
	
	[self closeDB];
	
return tables;

}




-(id)stringForErrorCode:(int)code{

	switch (code) 
	{
	case SQLITE_ERROR:
    return @"SQL error, syntax error or missing database";
    break;
  
	case SQLITE_INTERNAL:
    return @"Internal logic error in SQLite";
    break;
  
	case SQLITE_PERM:
    return @"Access permission denied";
    break;
  
	case SQLITE_ABORT:
    return @"Callback routine requested an abort";
    break;
	 
	case SQLITE_BUSY:
    return @"The database file is locked";
    break;
	
	case SQLITE_LOCKED:
    return @"A table in the database is locked";
    break;
	 
	case SQLITE_NOMEM:
    return @"A malloc() failed";
    break;
	
	case SQLITE_READONLY:
    return @"Attempt to write a readonly database";
    break;
	
	case SQLITE_INTERRUPT:
    return @"Operation terminated by sqlite3_interrupt()";
    break;
	
	case SQLITE_IOERR:
    return @"Some kind of disk I/O error occurred";
    break;
	
	case SQLITE_CORRUPT:
    return @"The database disk image is malformed";
    break;
	
	case SQLITE_NOTFOUND:
    return @"Unknown opcode in sqlite3_file_control()";
    break;
	
	case SQLITE_FULL:
    return @"Insertion failed because database is full";
    break;
	
	case SQLITE_CANTOPEN:
    return @"Unable to open the database file (check if exists and permissions)";
    break;
	
	case SQLITE_PROTOCOL:
    return @"Database lock protocol error";
    break;
	
	case SQLITE_EMPTY:
    return @"Database is empty";
    break;
	
	case SQLITE_SCHEMA:
    return @"The database schema changed";
    break;
	
	case SQLITE_TOOBIG:
    return @"String or BLOB exceeds size limit";
    break;
	
	case SQLITE_CONSTRAINT:
    return @"Abort due to constraint violation";
    break;
	
	case SQLITE_MISMATCH:
    return @"Data type mismatch";
    break;
	
	case SQLITE_MISUSE:
    return @"Library used incorrectly";
    break;
	
	case SQLITE_NOLFS:
    return @"Uses OS features not supported on host";
    break;
	
	case SQLITE_AUTH:
    return @"Authorization denied";
    break;
	
	case SQLITE_FORMAT:
    return @"Auxiliary database format error";
    break;
	
	case SQLITE_RANGE:
    return @"2nd parameter to sqlite3_bind out of range";
    break;
	
	case SQLITE_NOTADB:
    return @"File opened that is not a database file";
    break;
	
	case SQLITE_ROW:
    return @"sqlite3_step() has another row ready";
    break;
	
	case SQLITE_DONE:
    return @"sqlite3_step() has finished executing";
    break;
	
	
	default:
    return SQLITE_OK;

	}
	
	
}
-(void)dealloc{
	
	[self closeDB];
	[self.dbPath release];
	[self.dbName release];
	[super dealloc];
	
}
@end


 int (* orig_sqlite3_prepare_v2)(
  sqlite3 *db,            /* Database handle */
  const char *zSql,       /* SQL statement, UTF-8 encoded */
  int nByte,              /* Maximum length of zSql in bytes. */
  sqlite3_stmt **ppStmt,  /* OUT: Statement handle */
  const char **pzTail     /* OUT: Pointer to unused portion of zSql */
);

 int replaced_sqlite3_prepare_v2(
  sqlite3 *db,            /* Database handle */
  const char *zSql,       /* SQL statement, UTF-8 encoded */
  int nByte,              /* Maximum length of zSql in bytes. */
  sqlite3_stmt **ppStmt,  /* OUT: Statement handle */
  const char **pzTail     /* OUT: Pointer to unused portion of zSql */
){

int res=orig_sqlite3_prepare_v2(db,zSql,nByte,ppStmt,pzTail);
  
  if (writeAllSqliteQueriesToSyslog)	
	NSLog(@"SQLITE QUERY: %s",zSql);

return res;
}


__attribute__((constructor)) void libeasysqlite3() {
%init;
MSHookFunction(sqlite3_prepare_v2, replaced_sqlite3_prepare_v2, &orig_sqlite3_prepare_v2);
}