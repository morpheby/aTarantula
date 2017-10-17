#import "FilteringArray.h"

@interface FilteringArray ()


@property (nonatomic,retain) NSMutableArray *_allObjects;
@property (nonatomic,retain) NSMutableArray *_filteredObjects;
@property (nonatomic,retain) NSPredicate *_predicate;
@property (nonatomic,retain) NSArray<NSSortDescriptor *> *_sortDescriptors;
@property (nonatomic,unsafe_unretained,readonly) bool needsFiltering;

@end

@implementation FilteringArray

- (instancetype)init {
  self = [super init];
  self._allObjects = [NSMutableArray new];
  self._filteredObjects = [NSMutableArray new];
  return self;
}

- (bool)needsFiltering {
  return self._predicate != nil || (self._sortDescriptors != nil && self._sortDescriptors.count != 0);
}

- (void)setSortDescriptors:(NSArray<NSSortDescriptor *> *)sortDescriptors {
  self._sortDescriptors = sortDescriptors;
  [self applyFilter];
}

- (void)setFilterPredicate:(NSPredicate *)predicate {
  self._predicate = predicate;
  [self applyFilter];
}

- (void)applyFilter {
  self._filteredObjects = [NSMutableArray arrayWithArray:self._allObjects];
  
  if(!self.needsFiltering) {
    return;
  }

  if (self._predicate != nil)
    [self._filteredObjects filterUsingPredicate:self._predicate];
  if (self._sortDescriptors != nil)
    [self._filteredObjects sortUsingDescriptors:self._sortDescriptors];
}

- (void)addObject:(id)object {
  [self._allObjects addObject: object];
  [self applyFilter];
}
- (void)removeObjectAtIndex:(NSUInteger)index {
  [self._allObjects removeObjectAtIndex:index];
  [self applyFilter];
}
- (id)objectAtIndex:(NSUInteger)index {
  if(!self.needsFiltering) {
    return [self._allObjects objectAtIndex:index];
  }
  return [self._filteredObjects objectAtIndex:index];
}
- (void)addObjectsFromArray:(NSArray *)otherArray {
  [self._allObjects addObjectsFromArray:otherArray];
  [self applyFilter];
}
- (NSUInteger)indexOfObject:(id)object {
  if(!self.needsFiltering) {
    return [self._allObjects indexOfObject:object];
  }
  return [self._filteredObjects indexOfObject:object];
  
}

- (NSUInteger)count {
  if(!self.needsFiltering) {
    return self._allObjects.count;
  }
  return self._filteredObjects.count;
  
}
- (void)removeObjectsAtIndexes:(NSIndexSet *)indexes {
  NSArray *objectsToRemove = [[self objects] objectsAtIndexes:indexes];
  [self._allObjects removeObjectsInArray:objectsToRemove];
  [self applyFilter];
}

- (NSMutableArray *)objects {
  return !self.needsFiltering ? self._allObjects : self._filteredObjects;
}
- (NSArray *)objectsAtIndexes:(NSIndexSet *)indexes {
  return [self.objects objectsAtIndexes:indexes];
}
@end
