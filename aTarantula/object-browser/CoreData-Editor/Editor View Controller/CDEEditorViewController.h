#import <Cocoa/Cocoa.h>

@class CDEConfiguration;
@class CDEAutosaveInformation;
@interface CDEEditorViewController : NSViewController

#pragma mark - Displaying a Configuration
- (BOOL)configureWith:(nonnull CDEConfiguration *)configuration
             modelURL:(nonnull NSURL *)modelURL
             storeURL:(nonnull NSURL *)storeURL
          needsReload:(BOOL)needsReload
                error:( NSError * _Nullable * _Nullable)error;

#pragma mark - Saving
- (BOOL)save:(NSError * _Nullable * _Nullable)error;

#pragma mark - State
- (void)cleanup;

#pragma mark - Query Control
- (IBAction)takeQueryFromSender:(nonnull id)sender;

#pragma mark - Entity Operations
- (IBAction)deleteSelectedObjcts:(nonnull id)sender;
- (IBAction)insertObject:(nonnull id)sender;
@property (nonatomic, readonly, getter = canCreateCSVRepresentationWithSelectedObjects) BOOL canCreateCSVRepresentationWithSelectedObjects;
@property (nonatomic, readonly, getter = canDeleteSelectedManagedObjects) BOOL canDeleteSelectedManagedObjects;
@property (nonatomic, readonly, getter = canInsertManagedObject) BOOL canInsertManagedObject;
@property (nonatomic, nullable, retain, readonly) CDEAutosaveInformation * autosaveInformation;

@end
