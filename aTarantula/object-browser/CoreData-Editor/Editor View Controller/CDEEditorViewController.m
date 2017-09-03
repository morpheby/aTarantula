#import <Cocoa/Cocoa.h>
#import <CoreData/CoreData.h>

#import "CDEEditorViewController.h"
#import "CDEConfiguration.h"
#import "CDEEntitiesViewController.h"
#import "CDEManagedObjectsViewController.h"
#import "CDEManagedObjectsViewControllerDelegate.h"
#import "CDEEntitiesViewControllerDelegate.h"
#import "CDEManagedObjectsRequest.h"
#import "CDERelationshipsViewController.h"
#import "CDERelationshipsViewControllerDelegate.h"
#import "CDEManagedObjectViewController.h"
#import "CDEManagedObjectViewControllerDelegate.h"
#import "CDEValidationErrorsViewController.h"
#import "CDETwoColumnSplitViewController.h"
#import "CDEAutosaveInformation.h"

// Additions: Begin
#import "NSPersistentStoreCoordinator+CDEAdditions.h"
#import "NSManagedObjectModel-CDEAdditions.h"
#import "NSEntityDescription+CDEAdditions.h"
#import "NSRelationshipDescription+CDEAdditions.h"
// Additions: End

// 3rd Party: Begin
#import "BFNavigationController.h"
// 3rd Party: End


@interface CDEEditorViewController () <CDEEntitiesViewControllerDelegate, CDEManagedObjectsViewControllerDelegate, CDERelationshipsViewControllerDelegate, CDEManagedObjectViewControllerDelegate>

#pragma mark - Properties
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) CDEConfiguration *configuration;
@property (nonatomic, strong) CDEEntitiesViewController *entitiesViewController;
@property (nonatomic, strong) CDEManagedObjectsViewController *managedObjectsViewController;
@property (nonatomic, strong) CDEManagedObjectsViewController *detailManagedObjectsViewController;
@property (nonatomic, strong) CDEManagedObjectViewController *managedObjectViewController;
@property (nonatomic, strong) CDERelationshipsViewController *relationshipsViewController;
@property (nonatomic, strong) CDEValidationErrorsViewController *validationErrorsViewController;
@property (nonatomic, weak) id userDefaultsObserver;
@property (nonatomic, nullable, retain, readwrite) CDEAutosaveInformation *autosaveInformation;

#pragma mark - Nested Managed Objects
@property (strong) BFNavigationController *managedObjectsNavigationController;

#pragma mark - Container Views
@property (nonatomic, weak) IBOutlet NSView *entitiesContainer;
@property (nonatomic, weak) IBOutlet NSView *managedObjectsContainer;
@property (nonatomic, weak) IBOutlet NSView *detailContainer;
@property (nonatomic, weak) IBOutlet NSView *relationshipsContainer;
@property (nonatomic, weak) IBOutlet NSView *validationErrorsContainer;
@property (nonatomic, weak) IBOutlet NSTabView *managedObjectsTabView;
@property (nonatomic, weak) IBOutlet NSTabView *detailTabView;
@property (nonatomic, weak) IBOutlet NSTabView *nestedDetailTabView;

#pragma mark - Outlets
@property (nonatomic, weak) IBOutlet NSSplitView *splitView;

#pragma mark - SplitViews
@property (nonatomic, strong) CDETwoColumnSplitViewController *rightSplitViewController;
@property (nonatomic, weak) IBOutlet NSSplitView *rightSplitView;
@property (nonatomic, strong) CDETwoColumnSplitViewController *leftSplitViewController;
@property (nonatomic, weak) IBOutlet NSSplitView *leftSplitView;

@property (nonatomic, retain) NSArray *editor_topLevelObjects;

@end

@implementation CDEEditorViewController

#pragma mark - Creating
- (id)init {
  return [self initWithNibName:NSStringFromClass([self class]) bundle:nil];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (!self) {
        return nil;
    }
    NSArray *nibObjects = nil;
    if (![[NSBundle bundleForClass:[self class]] loadNibNamed:NSStringFromClass([self class])
                                                        owner:self
                                              topLevelObjects:&nibObjects]) {
        return nil;
    }

    self.view = [[nibObjects filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [[evaluatedObject class] isSubclassOfClass:[NSView self]];
    }]] firstObject];
    self.editor_topLevelObjects = nibObjects;

    [self configure_cdeEditorViewController];

    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nil];
    if(self) {
        [self configure_cdeEditorViewController];
    }
    return self;
}

- (void)configure_cdeEditorViewController {
    self.entitiesViewController = [CDEEntitiesViewController new];
    self.entitiesViewController.delegate = self;
    self.managedObjectsViewController = [CDEManagedObjectsViewController new];
    self.managedObjectsViewController.delegate = self;
    self.detailManagedObjectsViewController = [CDEManagedObjectsViewController new];
    self.detailManagedObjectsViewController.delegate = self;
    self.relationshipsViewController = [CDERelationshipsViewController new];
    self.relationshipsViewController.delegate = self;
    self.managedObjectViewController = [CDEManagedObjectViewController new];
    self.managedObjectViewController.delegate = self;
    self.validationErrorsViewController = [CDEValidationErrorsViewController new];

    __typeof__(self) __weak weakSelf = self;
    self.userDefaultsObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification object:[NSUserDefaults standardUserDefaults] queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [weakSelf.entitiesViewController updateUIOfVisibleEntities];
        [weakSelf.managedObjectsViewController updateUIOfVisibleObjects];
        [weakSelf.detailManagedObjectsViewController updateUIOfVisibleObjects];
        [weakSelf.relationshipsViewController updateUI];
        [weakSelf.managedObjectViewController updateDisplayedNames];
    }];
}

#pragma mark - Dealloc
- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self.userDefaultsObserver];
}


#pragma mark - NSViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  self.entitiesViewController.view.frame = self.entitiesContainer.bounds;
  [self.entitiesContainer addSubview:self.entitiesViewController.view];

  self.managedObjectsViewController.view.frame = self.managedObjectsContainer.bounds;
  self.managedObjectsViewController.canNavigateThroughObjectGraph = YES;
  self.managedObjectsNavigationController = [[BFNavigationController alloc] initWithFrame:self.managedObjectsContainer.bounds rootViewController:self.managedObjectsViewController];

  [self.managedObjectsContainer addSubview:self.managedObjectsNavigationController.view];

  self.detailManagedObjectsViewController.view.frame = self.detailContainer.bounds;
  [self.detailContainer addSubview:self.detailManagedObjectsViewController.view];

  self.relationshipsViewController.view.frame = self.relationshipsContainer.bounds;
  [self.relationshipsContainer addSubview:self.relationshipsViewController.view];

  self.validationErrorsViewController.view.frame = self.validationErrorsContainer.bounds;
  [self.validationErrorsContainer addSubview:self.validationErrorsViewController.view];

  self.rightSplitViewController = [[CDETwoColumnSplitViewController alloc] initWithSplitView:self.rightSplitView indexOfResizeableView:0 indexOfFixedSizeView:1];

  self.leftSplitViewController = [[CDETwoColumnSplitViewController alloc] initWithSplitView:self.leftSplitView indexOfResizeableView:0 indexOfFixedSizeView:1];
}

#pragma mark - Displaying a Configuration

- (BOOL)configureWith:(CDEConfiguration *)configuration
             model:(NSManagedObjectModel *)model
             objectContext:(NSManagedObjectContext *)context
                error:(NSError *__autoreleasing  _Nullable *)error {
  self.configuration = configuration;
  self.autosaveInformation = [[CDEAutosaveInformation alloc] initWithDictionaryRepresentation:self.configuration.autosaveInformationByEntityName];

  self.managedObjectContext = context;
  self.managedObjectModel = model;

  self.managedObjectsViewController.autosaveInformation = self.autosaveInformation;

  self.validationErrorsViewController.managedObjectContext = self.managedObjectContext;
  self.managedObjectsViewController.request = nil;
  self.detailManagedObjectsViewController.request = nil;
  self.managedObjectViewController.request = nil;
  self.relationshipsViewController.managedObject = nil;
  [self.entitiesViewController setManagedObjectContext:self.managedObjectContext];

  return YES;
}

- (BOOL)configureWith:(CDEConfiguration *)configuration
                modelURL:(NSURL *)modelURL
                storeURL:(NSURL *)storeURL
             needsReload:(BOOL)needsReload
                   error:(NSError **)error {
  BOOL performReload = ((_configuration == nil) ||
                        (configuration == nil) ||
                        ([_configuration isEqual:configuration] == NO) ||
                        (needsReload));

  NSManagedObjectContext *selectedContext;
  NSManagedObjectModel *selectedModel;

  if(performReload) {
    selectedModel = [[[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL] transformedManagedObjectModel_cde];
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];

    NSError *internalError = nil;

    NSPersistentStore *store = [persistentStoreCoordinator addPersistentStoreWithType:nil // guess
                                                                             configuration:nil
                                                                                       URL:storeURL
                                                                                   options:nil
                                                                                 error_cde:&internalError];

    if(store == nil) {
      if (error != nil) {
        *error = internalError;
      }
      return NO;
    }

    selectedContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
  } else {
    selectedContext = self.managedObjectContext;
    selectedModel = self.managedObjectModel;
  }

  return [self configureWith:configuration model:selectedModel objectContext:selectedContext error:error];
}

#pragma mark - Saving
- (BOOL)save:(NSError **)error {
  BOOL saved = [self.managedObjectContext save:error];
  if(saved) {
    [self.managedObjectsViewController updateUIOfVisibleObjects];
    [self.detailManagedObjectsViewController updateUIOfVisibleObjects];
  }
  return saved;
}
#pragma mark - State
- (void)cleanup {
}

#pragma mark - Query Control
- (IBAction)takeQueryFromSender:(id)sender {
  NSString *query = [sender stringValue];
  NSInteger colonIndex = [query rangeOfString:@":"].location;
  if(colonIndex == NSNotFound) {
    return;
  }
  NSString *entityName = [query substringToIndex:colonIndex];
  NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
  NSManagedObjectModel *model = self.managedObjectModel;
  NSEntityDescription *entity = model.entitiesByName[entityName];
  if(entity == nil) {
    return;
  }
  fetchRequest.entity = entity;
  if(query.length > colonIndex+1) {
    NSString *predicateFormat = [query substringFromIndex:colonIndex+1];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat];
    fetchRequest.predicate = predicate;
  }
  CDEManagedObjectsRequest *request = [[CDEManagedObjectsRequest alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext];
  [self.managedObjectsViewController setRequest:request];
}

#pragma mark - Entity Operations
- (IBAction)deleteSelectedObjcts:(id)sender {
  [self.managedObjectsViewController remove:sender];
}

- (IBAction)insertObject:(id)sender {
  [self.managedObjectsViewController add:sender];
}

- (BOOL)canCreateCSVRepresentationWithSelectedObjects {
  return self.managedObjectsViewController.canCreateCSVRepresentationWithSelectedObjects;
}

- (BOOL)canDeleteSelectedManagedObjects {
  return self.managedObjectsViewController.canDeleteSelectedManagedObjects;
}

- (BOOL)canInsertManagedObject {
  return self.managedObjectsViewController.canInsertManagedObject;
}

#pragma mark - CDEEntitiesViewControllerDelegate
- (void)entitiesViewController:(CDEEntitiesViewController *)entitiesViewController didSelectEntitiyDescription:(NSEntityDescription *)entityDescription {

  // Before assiging check for equality
  CDEAutosaveInformation *persistentInformation = [[CDEAutosaveInformation alloc] initWithDictionaryRepresentation:self.configuration.autosaveInformationByEntityName];
  //
  if(entityDescription == nil) {
    self.managedObjectsViewController.request = nil;
    self.detailManagedObjectsViewController.request = nil;
    self.relationshipsViewController.managedObject = nil;
    self.managedObjectViewController.representedObject = nil;
    [self.managedObjectsTabView selectTabViewItemAtIndex:1];
    [self.detailTabView selectTabViewItemAtIndex:1];
    [self.nestedDetailTabView selectTabViewItemAtIndex:1];
    return;
  }

  CDEManagedObjectsRequest *request = [[CDEManagedObjectsRequest alloc] initWithEntityDescription:entityDescription managedObjectContext:self.managedObjectContext];
  self.managedObjectsViewController.request = request;
  self.detailManagedObjectsViewController.request = nil;
  self.relationshipsViewController.managedObject = nil;
  self.managedObjectViewController.request = nil;
  [self.managedObjectsTabView selectTabViewItemAtIndex:0];
  [self.detailTabView selectTabViewItemAtIndex:1];
  [self.nestedDetailTabView selectTabViewItemAtIndex:1];

  CDEAutosaveInformation *currentAutosaveInformation = self.autosaveInformation;
  BOOL autosaveIsEqual = [currentAutosaveInformation isEqualToAutosaveInformation:persistentInformation];
  if(autosaveIsEqual) {
  }
  if(autosaveIsEqual == NO) {
    self.configuration.autosaveInformationByEntityName = self.autosaveInformation.representationForSerialization;
  }

}

#pragma mark - CDEManagedObjectsViewControllerDelegate
- (void)managedObjectsViewController:(CDEManagedObjectsViewController *)managedObjectsViewController
              didSelectManagedObject:(NSManagedObject *)managedObject {
  if([managedObjectsViewController isEqual:self.managedObjectsViewController]) {
    self.relationshipsViewController.managedObject = managedObject;
    if(managedObject == nil) {
      self.detailManagedObjectsViewController.request = nil;
      self.relationshipsViewController.managedObject = nil;
      [self.detailTabView selectTabViewItemAtIndex:1];
      [self.nestedDetailTabView selectTabViewItemAtIndex:1];
      return;
    }

    NSArray *sortedRelations = [managedObject.entity sortedRelationships_cde];
    if(sortedRelations.count == 0) {
      self.relationshipsViewController.managedObject = nil;
      self.detailManagedObjectsViewController.request = nil;
      [self.nestedDetailTabView selectTabViewItemAtIndex:1];
    }
    else {
      CDEManagedObjectsRequest *request = [[CDEManagedObjectsRequest alloc] initWithManagedObject:managedObject relationshipDescription:sortedRelations[0]];
      if(request.relationshipDescription.isToOne_cde == NO) {
        self.relationshipsViewController.managedObject = managedObject;
        self.detailManagedObjectsViewController.request = request;
        [self.nestedDetailTabView selectTabViewItemAtIndex:0];
      }
    }
    [self.detailTabView selectTabViewItemAtIndex:0];
    //[self.managedObjectsViewController makeTableViewFirstResponder];
  }
}

- (void)managedObjectsViewController:(CDEManagedObjectsViewController *)managedObjectsViewController
           wantsRequestToBeDisplayed:(CDEManagedObjectsRequest *)request {
  if([managedObjectsViewController isEqual:self.managedObjectsViewController]) {
    self.detailManagedObjectsViewController.request = request;
  }
}

- (void)managedObjectsViewControllerDidChangeContents:(CDEManagedObjectsViewController *)managedObjectsViewController {
  [self.relationshipsViewController updateUI];
}

- (void)managedObjectsViewControllerDidChangeAutosaveInformation:(CDEManagedObjectsViewController *)managedObjectsViewController {
  if([managedObjectsViewController isEqual:self.managedObjectsViewController]) {
    CDEAutosaveInformation *persistentInformation = [[CDEAutosaveInformation alloc] initWithDictionaryRepresentation:self.configuration.autosaveInformationByEntityName];
    CDEAutosaveInformation *currentAutosaveInformation = self.autosaveInformation;
    BOOL autosaveIsEqual = [currentAutosaveInformation isEqualToAutosaveInformation:persistentInformation];
    if(autosaveIsEqual) {
    }
    if(autosaveIsEqual == NO) {
      self.configuration.autosaveInformationByEntityName = self.autosaveInformation.representationForSerialization;
    }
  }
}

- (void)managedObjectsViewController:(CDEManagedObjectsViewController *)managedObjectsViewController
               didSelectRelationship:(NSRelationshipDescription *)relationship
                     ofManagedObject:(NSManagedObject *)managedObject {
  if([self.managedObjectsViewController isEqual:managedObjectsViewController] == NO) {
    return;
  }
  NSLog(@"Show nested Objects for relation %@ of managed object: %@", relationship.name, managedObject.objectID);
  CDEManagedObjectsViewController *newManagedObjectsViewController = [CDEManagedObjectsViewController new];
  newManagedObjectsViewController.delegate = self;
  newManagedObjectsViewController.canNavigateThroughObjectGraph = YES;
  CDEManagedObjectsRequest *request = [[CDEManagedObjectsRequest alloc] initWithManagedObject:managedObject relationshipDescription:relationship];
  self.managedObjectsViewController = newManagedObjectsViewController;
  [newManagedObjectsViewController view];
  [newManagedObjectsViewController setRequest:request];

  [self.managedObjectsNavigationController pushViewController:self.managedObjectsViewController animated:YES completionHandler:^{
  }];
}

#pragma mark - CDERelationshipsViewControllerDelegate
- (void)displayRequestInDetailManagedObjectsView:(CDEManagedObjectsRequest *)request {
  self.detailManagedObjectsViewController.request = request;

  BOOL isShowingDetailManagedObjectsView = self.detailManagedObjectsViewController.view.superview != nil;
  if(request == nil && isShowingDetailManagedObjectsView) {
    [self.detailManagedObjectsViewController.view removeFromSuperview];
    return;
  }
  if(request != nil && isShowingDetailManagedObjectsView == NO) {
    if(self.managedObjectViewController.view.superview != nil) {
      [self.managedObjectViewController.view removeFromSuperview];
    }
    self.detailManagedObjectsViewController.view.frame = self.detailContainer.bounds;
    [self.detailContainer addSubview:self.detailManagedObjectsViewController.view];
  }
}

- (void)displayRequestInManagedObjectView:(CDEManagedObjectsRequest *)request {
  self.managedObjectViewController.request = request;

  BOOL isShowingManagedObjectView = self.managedObjectViewController.view.superview != nil;
  if(isShowingManagedObjectView) {
    //        [self.managedObjectViewController.view removeFromSuperview];
    return;
  }
  if(isShowingManagedObjectView == NO) {
    if(self.detailManagedObjectsViewController.view.superview != nil) {
      [self.detailManagedObjectsViewController.view removeFromSuperview];
    }
    self.managedObjectViewController.view.frame = self.detailContainer.bounds;
    [self.detailContainer addSubview:self.managedObjectViewController.view];
  }
}

- (void)relationshipsViewController:(CDERelationshipsViewController *)relationshipsViewController didSelectRelationshipDescription:(NSRelationshipDescription *)relationshipDescription {
  if(relationshipDescription == nil) {
    self.detailManagedObjectsViewController.request = nil;
    [self displayRequestInManagedObjectView:nil];
    [self displayRequestInDetailManagedObjectsView:nil];
    [self.nestedDetailTabView selectTabViewItemAtIndex:1];
    return;
  }
  NSManagedObject *selectedManagedObject = self.managedObjectsViewController.selectedManagedObject;
  CDEManagedObjectsRequest *detailRequest = [[CDEManagedObjectsRequest alloc] initWithManagedObject:selectedManagedObject relationshipDescription:relationshipDescription];
  if(relationshipDescription.isToMany) {
    //    self.detailManagedObjectsViewController.request = detailRequest;
    [self displayRequestInDetailManagedObjectsView:detailRequest];
  } else {
    [self displayRequestInManagedObjectView:detailRequest];
  }
  [self.nestedDetailTabView selectTabViewItemAtIndex:0];
}

#pragma mark - CDEManagedObjectViewControllerDelegate
- (void)managedObjectViewControllerDidAddOrRemoveManagedObject:(CDEManagedObjectViewController *)managedObjectViewController {
  [self.relationshipsViewController updateUI];
}

@end
