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
