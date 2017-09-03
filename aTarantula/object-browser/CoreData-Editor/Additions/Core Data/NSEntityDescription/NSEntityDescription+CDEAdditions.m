
#import <Cocoa/Cocoa.h>
#import "NSEntityDescription+CDEAdditions.h"
#import "NSAttributeDescription+CDEAdditions.h"
#import "NSString+CDEAdditions.h"


@implementation NSEntityDescription (CDEAdditions)

#pragma mark - Convenience
- (NSArray<NSAttributeDescription*> *)supportedAttributes_cde {
    NSMutableArray *result = [NSMutableArray new];
    for(NSAttributeDescription *attribute in [[self attributesByName] allValues]) {
        // Ignore transient properties
        if(attribute.isTransient) {
            continue;
        }
        if(!attribute.isSupportedAttribute_cde) {
            continue;
        }

        [result addObject:attribute];
    }
    return result;
}


- (NSArray<NSRelationshipDescription*> *)sortedToOneRelationships_cde {
    NSMutableArray *result = [NSMutableArray new];
    [self.relationshipsByName enumerateKeysAndObjectsUsingBlock:^(id key, NSRelationshipDescription *relation, BOOL *stop) {
        if(relation.isToMany) {
            return;
        }
        [result addObject:relation];
    }];
    return [result sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(NSRelationshipDescription *relationA, NSRelationshipDescription *relationB) {
        return [relationA.name localizedStandardCompare:relationB.name];
    }];
}

- (NSArray<NSRelationshipDescription*> *)sortedRelationships_cde {
    return [self.relationshipsByName.allValues sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(NSRelationshipDescription *relationA, NSRelationshipDescription *relationB) {
        return [relationA.name localizedStandardCompare:relationB.name];
    }];
}

- (NSString *)nameForDisplay_cde {
    return [self.name humanReadableStringAccordingToUserDefaults_cde];
}

#pragma mark - UI
- (NSImage *)icon_cde {
    return [NSImage imageNamed:@"entity-icon-small"];
}

@end
