#import <CoreData/CoreData.h>

@interface NSEntityDescription (CDEAdditions)

#pragma mark - Convenience
- (NSArray<NSAttributeDescription*> *)supportedAttributes_cde;
- (NSArray<NSRelationshipDescription*> *)sortedToOneRelationships_cde;
- (NSArray<NSRelationshipDescription*> *)sortedRelationships_cde;
@property (nonatomic, readonly) NSString *nameForDisplay_cde;

#pragma mark - UI
- (NSImage *)icon_cde;

@end
